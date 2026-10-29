create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.administradores (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.administradores enable row level security;
revoke all on public.administradores from anon, authenticated;
grant select on public.administradores to authenticated;
create policy "Consultar acceso propio" on public.administradores for select to authenticated
using (user_id = (select auth.uid()));

-- A confirmed email, controlled by Auth, grants the coordinator access.
-- Client-supplied user_metadata never grants administrative privileges.
create function private.sync_coordinator() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.email_confirmed_at is not null and lower(new.email) = 'jose.gomez.lopez@colmayor.edu.co' then
    insert into public.administradores(user_id) values(new.id) on conflict do nothing;
  else
    delete from public.administradores where user_id = new.id;
  end if;
  return new;
end;
$$;
revoke all on function private.sync_coordinator() from public, anon, authenticated;
create trigger grant_coordinator after insert or update of email, email_confirmed_at
on auth.users for each row execute function private.sync_coordinator();

create table public.rate_limits (
  key text primary key,
  window_start timestamptz not null,
  hits integer not null
);
alter table public.rate_limits enable row level security;
revoke all on public.rate_limits from anon, authenticated;
grant all on public.rate_limits to service_role;
create function public.allow_submission(source_key text) returns boolean
language plpgsql security invoker set search_path = '' as $$
declare current_hits integer;
begin
  insert into public.rate_limits(key,window_start,hits) values(source_key,now(),1)
  on conflict (key) do update set
    hits = case when public.rate_limits.window_start < now() - interval '10 minutes' then 1 else public.rate_limits.hits + 1 end,
    window_start = case when public.rate_limits.window_start < now() - interval '10 minutes' then now() else public.rate_limits.window_start end
  returning hits into current_hits;
  return current_hits <= 60;
end;
$$;
revoke all on function public.allow_submission(text) from public, anon, authenticated;
grant execute on function public.allow_submission(text) to service_role;

create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;
-- Generate the internal scheduler credential in Vault, never in source control.
select vault.create_secret(encode(extensions.gen_random_bytes(32),'hex'), 'pmo_cron_secret', 'Internal daily digest credential');
create function public.authorize_summary(supplied_secret text) returns boolean
language sql security definer set search_path = '' as $$
  select exists(select 1 from vault.decrypted_secrets where name = 'pmo_cron_secret' and decrypted_secret = supplied_secret);
$$;
revoke all on function public.authorize_summary(text) from public, anon, authenticated;
grant execute on function public.authorize_summary(text) to service_role;
create table public.pmo_iniciativas (
 id uuid primary key,
 created_at timestamptz not null default now(),
 data jsonb not null check (jsonb_typeof(data)='object' and octet_length(data::text)<=30000)
);
create index pmo_iniciativas_created_idx on public.pmo_iniciativas(created_at desc);
alter table public.pmo_iniciativas enable row level security;
revoke all on public.pmo_iniciativas from anon,authenticated;
grant select on public.pmo_iniciativas to authenticated;
grant all on public.pmo_iniciativas to service_role;
create policy "Coordinador consulta iniciativas" on public.pmo_iniciativas for select to authenticated using (exists(select 1 from public.administradores a where a.user_id=(select auth.uid())));
create table public.pmo_summary_runs (report_date date primary key, status text not null check(status in ('sending','sent','failed','empty')), updated_at timestamptz not null default now(), message_id text, error text);
alter table public.pmo_summary_runs enable row level security;
revoke all on public.pmo_summary_runs from public, anon, authenticated;
grant all on public.pmo_summary_runs to service_role;
select cron.schedule('pmo-daily-summary','0,15,30 12 * * *',$job$
 select net.http_post(url := 'https://kwnsllunphcgdgmpkiuj.supabase.co/functions/v1/pmo-summary',headers := jsonb_build_object('Content-Type','application/json','x-cron-secret',(select decrypted_secret from vault.decrypted_secrets where name='pmo_cron_secret')),body := '{}'::jsonb,timeout_milliseconds := 30000);
$job$);

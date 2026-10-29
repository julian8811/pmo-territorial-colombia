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
 select net.http_post(url := 'https://wfwxdvkcdqnvdmkjxaoj.supabase.co/functions/v1/pmo-summary',headers := jsonb_build_object('Content-Type','application/json','x-cron-secret',(select decrypted_secret from vault.decrypted_secrets where name='remedios_cron_secret')),body := '{}'::jsonb,timeout_milliseconds := 30000);
$job$);

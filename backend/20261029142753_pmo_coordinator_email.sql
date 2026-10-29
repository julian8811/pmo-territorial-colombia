create or replace function private.sync_coordinator() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.email_confirmed_at is not null and lower(new.email) = 'jlopego1@gmail.com' then
    insert into public.administradores(user_id) values(new.id) on conflict do nothing;
  else
    delete from public.administradores where user_id = new.id;
  end if;
  return new;
end;
$$;
revoke all on function private.sync_coordinator() from public, anon, authenticated;
delete from public.administradores a using auth.users u where a.user_id=u.id and lower(u.email)='jose.gomez.lopez@colmayor.edu.co';
insert into public.administradores(user_id) select id from auth.users where lower(email)='jlopego1@gmail.com' and email_confirmed_at is not null on conflict do nothing;

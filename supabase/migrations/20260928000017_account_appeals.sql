-- Appeals sent by suspended (banned) users to the administrators.
--
-- A banned account has no session any more (sessions revoked, Auth ban), so
-- the appeal is submitted anonymously through a SECURITY DEFINER function
-- that only accepts the e-mail of a suspended account. It never tells the
-- caller whether the address exists or is suspended.

create table if not exists public.account_appeals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  email text not null,
  message text not null check (char_length(message) between 10 and 2000),
  status text not null default 'open' check (status in ('open', 'resolved')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id) on delete set null
);

create index if not exists account_appeals_user_idx
  on public.account_appeals (user_id, created_at desc);
create index if not exists account_appeals_open_idx
  on public.account_appeals (created_at desc) where status = 'open';

alter table public.account_appeals enable row level security;

drop policy if exists "Admins read appeals" on public.account_appeals;
create policy "Admins read appeals" on public.account_appeals
  for select to authenticated
  using (public.is_current_user_admin());

drop policy if exists "Admins resolve appeals" on public.account_appeals;
create policy "Admins resolve appeals" on public.account_appeals
  for update to authenticated
  using (public.is_current_user_admin())
  with check (public.is_current_user_admin());

revoke insert, delete on public.account_appeals from anon, authenticated;

create or replace function public.submit_account_appeal(p_email text, p_message text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_message text := btrim(coalesce(p_message, ''));
  v_user uuid;
  v_name text;
begin
  if char_length(v_message) < 10 or char_length(v_message) > 2000 then
    raise exception 'appeal_invalid_message' using errcode = '22023';
  end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'appeal_invalid_email' using errcode = '22023';
  end if;

  select p.id, coalesce(nullif(btrim(p.display_name), ''), split_part(u.email, '@', 1))
    into v_user, v_name
  from auth.users u
  join public.profiles p on p.id = u.id
  where lower(u.email) = v_email
    and p.status = 'suspended'
  limit 1;

  -- Unknown or active address: answer as if it worked, to avoid revealing
  -- which accounts exist or are suspended.
  if v_user is null then
    return;
  end if;

  -- At most 3 appeals a day per account; extra ones are dropped silently.
  if (select count(*) from public.account_appeals
      where user_id = v_user and created_at > now() - interval '24 hours') >= 3 then
    return;
  end if;

  insert into public.account_appeals (user_id, email, message)
  values (v_user, v_email, v_message);

  insert into public.notifications (user_id, type, title, body, payload)
  select distinct r.user_id,
         'account_appeal',
         'Recours de ' || v_name,
         v_message || E'\n\nRépondre à : ' || v_email,
         jsonb_build_object('route', 'adminUsers', 'user_id', v_user)
  from public.user_roles r
  where r.role in ('admin', 'super_admin');
end;
$$;

revoke all on function public.submit_account_appeal(text, text) from public;
grant execute on function public.submit_account_appeal(text, text) to anon, authenticated;

-- Reactivating an account settles its pending appeals.
create or replace function public.resolve_appeals_on_reactivation()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.status = 'active' and old.status is distinct from 'active' then
    update public.account_appeals
       set status = 'resolved',
           resolved_at = now(),
           resolved_by = auth.uid()
     where user_id = new.id and status = 'open';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_resolve_appeals on public.profiles;
create trigger profiles_resolve_appeals
  after update of status on public.profiles
  for each row execute function public.resolve_appeals_on_reactivation();

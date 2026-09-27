-- User activity persisted server-side: translation history counters and
-- per-user sign views.

create or replace function public.sync_session_total_entries()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.translation_sessions
       set total_entries = coalesce(total_entries, 0) + 1
     where id = new.session_id;
    return new;
  end if;
  update public.translation_sessions
     set total_entries = greatest(coalesce(total_entries, 0) - 1, 0)
   where id = old.session_id;
  return old;
end;
$$;

drop trigger if exists translation_entries_total on public.translation_entries;
create trigger translation_entries_total
  after insert or delete on public.translation_entries
  for each row execute function public.sync_session_total_entries();

update public.translation_sessions s
   set total_entries = (select count(*) from public.translation_entries e where e.session_id = s.id);

-- One call per sign opening: global counter + the viewer's own progress.
create or replace function public.record_sign_view(p_sign_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  update public.signs
     set view_count = coalesce(view_count, 0) + 1
   where id = p_sign_id;

  if v_user is not null
     and exists (select 1 from public.profiles where id = v_user and coalesce(status, 'active') = 'active')
     and exists (select 1 from public.signs where id = p_sign_id) then
    insert into public.user_progress (user_id, sign_id, times_viewed, last_seen_at)
    values (v_user, p_sign_id, 1, now())
    on conflict (user_id, sign_id) do update
      set times_viewed = coalesce(public.user_progress.times_viewed, 0) + 1,
          last_seen_at = now();
  end if;
end;
$$;

revoke all on function public.record_sign_view(uuid) from public;
grant execute on function public.record_sign_view(uuid) to anon, authenticated;

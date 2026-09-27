-- Live updates, contribution integrity, storage access and contributor feedback.

-- 1. Realtime: the app's .stream() listeners only receive changes for tables
--    in this publication (RLS still filters what each user gets).
do $$
declare
  t text;
begin
  foreach t in array array['notifications', 'contributions', 'translation_entries',
                           'translation_sessions', 'profiles', 'training_jobs',
                           'ml_experiments', 'ml_epoch_metrics'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$$;

-- 2. A contributor can only submit a pending, unreviewed contribution.
drop policy if exists "Users insert own contributions" on public.contributions;
create policy "Users insert own contributions"
  on public.contributions for insert
  with check (
    auth.uid() = contributor_id
    and coalesce(status, 'pending') = 'pending'
    and reviewer_id is null
    and reviewer_note is null
    and reviewed_at is null
  );

-- 3. Storage: avatar re-upload (upsert needs SELECT) and admin review of
--    videos in the private contributions bucket.
drop policy if exists users_read_own_avatar on storage.objects;
create policy users_read_own_avatar
  on storage.objects for select
  using (bucket_id = 'avatars' and (auth.uid())::text = (storage.foldername(name))[1]);

drop policy if exists admins_read_contributions on storage.objects;
create policy admins_read_contributions
  on storage.objects for select
  using (bucket_id = 'contributions' and public.is_current_user_admin());

-- 4. The contributor is told when their contribution is reviewed.
create or replace function public.notify_contribution_review()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status and new.status in ('approved', 'rejected') then
    insert into public.notifications (user_id, type, title, body, payload)
    values (
      new.contributor_id,
      'contribution',
      case when new.status = 'approved'
           then 'Contribution acceptée : ' || new.word
           else 'Contribution refusée : ' || new.word end,
      coalesce(nullif(new.reviewer_note, ''),
               case when new.status = 'approved'
                    then 'Merci ! Votre signe a été ajouté au dictionnaire.'
                    else 'Votre contribution n''a pas été retenue.' end),
      jsonb_build_object('contribution_id', new.id, 'status', new.status)
    );
  end if;
  return new;
end;
$$;

drop trigger if exists contributions_notify_review on public.contributions;
create trigger contributions_notify_review
  after update of status on public.contributions
  for each row execute function public.notify_contribution_review();

-- 5. Sign-up without an immediate session (email confirmation) keeps the
--    "deaf / hard of hearing" choice passed in the auth metadata.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.profiles (id, email, display_name, is_deaf, created_at, updated_at)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    coalesce((new.raw_user_meta_data->>'is_deaf')::boolean, false),
    now(),
    now()
  )
  on conflict (id) do update
    set email = excluded.email,
        display_name = coalesce(excluded.display_name, public.profiles.display_name),
        updated_at = now();
  return new;
end;
$$;

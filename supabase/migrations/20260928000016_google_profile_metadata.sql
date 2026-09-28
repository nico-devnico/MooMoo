-- New accounts created through Google (signInWithIdToken) carry `full_name` /
-- `name` and `avatar_url` / `picture` in their metadata instead of the
-- `display_name` sent by the email sign-up: use them so the profile starts
-- with the real name and photo rather than the e-mail prefix.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_name text := nullif(btrim(coalesce(
    meta->>'display_name',
    meta->>'full_name',
    meta->>'name'
  )), '');
  v_avatar text := nullif(btrim(coalesce(meta->>'avatar_url', meta->>'picture')), '');
begin
  insert into public.profiles (id, email, display_name, avatar_url, is_deaf, created_at, updated_at)
  values (
    new.id,
    new.email,
    coalesce(left(v_name, 80), split_part(new.email, '@', 1)),
    v_avatar,
    coalesce((meta->>'is_deaf')::boolean, false),
    now(),
    now()
  )
  on conflict (id) do update
    set email = excluded.email,
        display_name = coalesce(public.profiles.display_name, excluded.display_name),
        avatar_url = coalesce(public.profiles.avatar_url, excluded.avatar_url),
        updated_at = now();
  return new;
end;
$$;

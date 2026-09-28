-- MooMoo — une suspension coupe réellement l'accès au compte.
--
-- Jusqu'ici profiles.status = 'suspended' ne bloquait que les écritures (RLS) :
-- le compte pouvait toujours se connecter et naviguer. Désormais :
--   - suspendre bannit le compte dans Supabase Auth (auth.users.banned_until),
--     ce qui refuse toute nouvelle connexion et tout rafraîchissement de jeton ;
--   - ses sessions ouvertes sont supprimées (auth.sessions, et les refresh
--     tokens en cascade), donc les appareils déjà connectés perdent l'accès dès
--     l'expiration de leur jeton d'accès, et l'application les déconnecte
--     immédiatement en voyant le statut changer ;
--   - réactiver lève le bannissement ;
--   - un bannissement posé depuis le tableau de bord Supabase suspend aussi le
--     profil, pour que les deux vues restent cohérentes.
--
-- Apply with: cd backend && npm run migrate

-- Date lointaine plutôt que 'infinity' : GoTrue lit banned_until comme un
-- horodatage Go, qui ne sait pas représenter l'infini.
CREATE OR REPLACE FUNCTION public.suspension_ban_until()
RETURNS timestamptz
LANGUAGE sql
IMMUTABLE
AS $$ SELECT '2999-12-31 00:00:00+00'::timestamptz $$;

CREATE OR REPLACE FUNCTION public.apply_profile_suspension()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NULL;
  END IF;

  IF NEW.status = 'suspended' THEN
    UPDATE auth.users
    SET banned_until = public.suspension_ban_until(),
        updated_at = now()
    WHERE id = NEW.id
      AND (banned_until IS NULL OR banned_until < now());
    DELETE FROM auth.sessions WHERE user_id = NEW.id;
  ELSIF NEW.status = 'active' THEN
    UPDATE auth.users
    SET banned_until = NULL,
        updated_at = now()
    WHERE id = NEW.id
      AND banned_until IS NOT NULL;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS apply_profile_suspension ON public.profiles;
CREATE TRIGGER apply_profile_suspension
  AFTER UPDATE OF status ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.apply_profile_suspension();

CREATE OR REPLACE FUNCTION public.sync_ban_to_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  banned boolean := NEW.banned_until IS NOT NULL AND NEW.banned_until > now();
BEGIN
  IF NEW.banned_until IS NOT DISTINCT FROM OLD.banned_until THEN
    RETURN NULL;
  END IF;

  IF banned THEN
    UPDATE public.profiles
    SET status = 'suspended',
        suspended_at = COALESCE(suspended_at, now()),
        suspended_reason = COALESCE(suspended_reason, 'Compte banni par un administrateur'),
        updated_at = now()
    WHERE id = NEW.id AND status <> 'suspended';
    DELETE FROM auth.sessions WHERE user_id = NEW.id;
  ELSE
    UPDATE public.profiles
    SET status = 'active',
        suspended_at = NULL,
        suspended_reason = NULL,
        suspended_by = NULL,
        updated_at = now()
    WHERE id = NEW.id AND status = 'suspended';
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS sync_ban_to_profile ON auth.users;
CREATE TRIGGER sync_ban_to_profile
  AFTER UPDATE OF banned_until ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_ban_to_profile();

-- Comptes déjà suspendus avant cette migration.
UPDATE auth.users u
SET banned_until = public.suspension_ban_until(),
    updated_at = now()
FROM public.profiles p
WHERE p.id = u.id
  AND p.status = 'suspended'
  AND (u.banned_until IS NULL OR u.banned_until < now());

DELETE FROM auth.sessions s
USING public.profiles p
WHERE p.id = s.user_id AND p.status = 'suspended';

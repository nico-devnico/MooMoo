-- MooMoo — propriétaire du système (super admin).
--
-- Un seul compte porte le rôle 'super_admin', en plus de 'admin'. Il ne peut
-- être ni supprimé, ni suspendu, ni banni, ni perdre ses droits, et ce quel que
-- soit le chemin : application, API Node (service role), tableau de bord
-- Supabase ou éditeur SQL. Les garde-fous sont des triggers : ils s'appliquent
-- aussi au rôle postgres, que RLS ne concerne pas.
--
-- Réservé au propriétaire (les autres admins ne le peuvent pas) :
--   - accorder ou retirer le rôle admin ;
--   - suspendre, réactiver ou supprimer un autre admin ;
--   - modifier la configuration globale (nom, logo, maintenance, contributions).
--
-- Le rôle se transmet uniquement par public.transfer_ownership(), appelée par
-- le propriétaire en place. Un superutilisateur Postgres peut toujours retirer
-- un trigger : ce qui est bloqué ici, ce sont les suppressions et
-- modifications ordinaires, pas la désactivation délibérée du schéma.
--
-- Apply with: cd backend && npm run migrate

-- ---------------------------------------------------------------------------
-- Rôle
-- ---------------------------------------------------------------------------
ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;
ALTER TABLE public.user_roles
  ADD CONSTRAINT user_roles_role_check
  CHECK (role IN ('super_admin', 'admin', 'teacher', 'sign_expert'));

CREATE UNIQUE INDEX IF NOT EXISTS user_roles_single_super_admin
  ON public.user_roles ((true))
  WHERE role = 'super_admin';

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_super_admin(p_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p_user IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user AND role = 'super_admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_super_admin(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_super_admin(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.current_user_is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_super_admin(auth.uid());
$$;

REVOKE ALL ON FUNCTION public.current_user_is_super_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_is_super_admin() TO authenticated, anon;

-- ---------------------------------------------------------------------------
-- Désignation : le plus ancien admin devient propriétaire s'il n'y en a pas.
-- Fait avant la pose des triggers, qui interdisent d'insérer ce rôle.
-- ---------------------------------------------------------------------------
INSERT INTO public.user_roles (user_id, role)
SELECT p.id, 'super_admin'
FROM public.profiles p
WHERE p.is_admin
  AND NOT EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'super_admin')
ORDER BY p.created_at
LIMIT 1;

INSERT INTO public.user_roles (user_id, role)
SELECT user_id, 'admin'
FROM public.user_roles
WHERE role = 'super_admin'
ON CONFLICT (user_id, role) DO NOTHING;

-- ---------------------------------------------------------------------------
-- user_roles
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_user_roles()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller uuid := auth.uid();
  target uuid;
  touches_admin boolean;
BEGIN
  IF current_setting('moomoo.owner_transfer', true) = 'on' THEN
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  END IF;

  IF TG_OP <> 'INSERT' AND (
       OLD.role = 'super_admin'
       OR (OLD.role = 'admin' AND public.is_super_admin(OLD.user_id))
     ) THEN
    RAISE EXCEPTION 'Le propriétaire du système ne peut pas perdre ses droits'
      USING ERRCODE = '42501', HINT = 'protected_owner';
  END IF;

  IF TG_OP <> 'DELETE' AND NEW.role = 'super_admin' THEN
    RAISE EXCEPTION 'Le rôle propriétaire se transmet uniquement par transfer_ownership()'
      USING ERRCODE = '42501', HINT = 'protected_owner';
  END IF;

  -- Service role et éditeur SQL (auth.uid() NULL) : l'API Node applique les
  -- mêmes règles avant d'écrire.
  IF caller IS NULL OR public.is_super_admin(caller) THEN
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  END IF;

  target := CASE WHEN TG_OP = 'DELETE' THEN OLD.user_id ELSE NEW.user_id END;
  IF public.is_super_admin(target) THEN
    RAISE EXCEPTION 'Seul le propriétaire peut modifier ses propres rôles'
      USING ERRCODE = '42501', HINT = 'protected_owner';
  END IF;

  touches_admin := (TG_OP <> 'INSERT' AND OLD.role = 'admin')
                OR (TG_OP <> 'DELETE' AND NEW.role = 'admin');
  IF touches_admin THEN
    RAISE EXCEPTION 'Seul le propriétaire peut accorder ou retirer le rôle admin'
      USING ERRCODE = '42501', HINT = 'owner_only';
  END IF;

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

DROP TRIGGER IF EXISTS guard_user_roles ON public.user_roles;
CREATE TRIGGER guard_user_roles
  BEFORE INSERT OR UPDATE OR DELETE ON public.user_roles
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_user_roles();

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_owner_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller uuid := auth.uid();
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF public.is_super_admin(OLD.id) THEN
      RAISE EXCEPTION 'Le compte du propriétaire du système ne peut pas être supprimé'
        USING ERRCODE = '42501', HINT = 'protected_owner';
    END IF;
    RETURN OLD;
  END IF;

  IF public.is_super_admin(OLD.id) THEN
    IF NEW.status IS DISTINCT FROM 'active' OR NEW.is_admin IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'Le propriétaire du système ne peut être ni suspendu ni rétrogradé'
        USING ERRCODE = '42501', HINT = 'protected_owner';
    END IF;
    IF caller IS NOT NULL AND caller <> OLD.id THEN
      RAISE EXCEPTION 'Seul le propriétaire peut modifier son profil'
        USING ERRCODE = '42501', HINT = 'protected_owner';
    END IF;
  ELSIF OLD.is_admin
        AND caller IS NOT NULL
        AND caller <> OLD.id
        AND NOT public.is_super_admin(caller)
        AND (NEW.status IS DISTINCT FROM OLD.status
             OR NEW.suspended_at IS DISTINCT FROM OLD.suspended_at
             OR NEW.suspended_reason IS DISTINCT FROM OLD.suspended_reason) THEN
    RAISE EXCEPTION 'Seul le propriétaire peut suspendre ou réactiver un admin'
      USING ERRCODE = '42501', HINT = 'owner_only';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_owner_profile ON public.profiles;
CREATE TRIGGER guard_owner_profile
  BEFORE UPDATE OR DELETE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_owner_profile();

-- ---------------------------------------------------------------------------
-- auth.users : suppression, suppression douce et bannissement
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_owner_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.is_super_admin(OLD.id) THEN
    IF TG_OP = 'DELETE' THEN
      RAISE EXCEPTION 'Le compte du propriétaire du système ne peut pas être supprimé'
        USING ERRCODE = '42501', HINT = 'protected_owner';
    END IF;
    IF (NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL)
       OR (NEW.banned_until IS NOT NULL
           AND NEW.banned_until > now()
           AND NEW.banned_until IS DISTINCT FROM OLD.banned_until) THEN
      RAISE EXCEPTION 'Le compte du propriétaire du système ne peut pas être désactivé'
        USING ERRCODE = '42501', HINT = 'protected_owner';
    END IF;
  END IF;
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

DROP TRIGGER IF EXISTS guard_owner_auth_user ON auth.users;
CREATE TRIGGER guard_owner_auth_user
  BEFORE DELETE OR UPDATE OF deleted_at, banned_until ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_owner_auth_user();

-- ---------------------------------------------------------------------------
-- Transmission de la propriété
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.transfer_ownership(p_new_owner uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.current_user_is_super_admin() THEN
    RAISE EXCEPTION 'Seul le propriétaire peut transmettre la propriété'
      USING ERRCODE = '42501', HINT = 'owner_only';
  END IF;
  IF p_new_owner IS NULL OR p_new_owner = auth.uid() THEN
    RETURN;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = p_new_owner AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Le nouveau propriétaire doit déjà être administrateur'
      USING ERRCODE = '22023';
  END IF;

  PERFORM set_config('moomoo.owner_transfer', 'on', true);
  DELETE FROM public.user_roles WHERE role = 'super_admin';
  INSERT INTO public.user_roles (user_id, role, granted_by)
  VALUES (p_new_owner, 'super_admin', auth.uid());
  PERFORM set_config('moomoo.owner_transfer', 'off', true);
END;
$$;

REVOKE ALL ON FUNCTION public.transfer_ownership(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.transfer_ownership(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Configuration globale et logo : propriétaire uniquement
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins update app settings" ON public.app_settings;
DROP POLICY IF EXISTS "Owner updates app settings" ON public.app_settings;
CREATE POLICY "Owner updates app settings"
  ON public.app_settings FOR UPDATE
  USING (public.current_user_is_super_admin())
  WITH CHECK (public.current_user_is_super_admin());

DROP POLICY IF EXISTS branding_admin_insert ON storage.objects;
CREATE POLICY branding_admin_insert
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'branding' AND public.current_user_is_super_admin());

DROP POLICY IF EXISTS branding_admin_update ON storage.objects;
CREATE POLICY branding_admin_update
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'branding' AND public.current_user_is_super_admin());

DROP POLICY IF EXISTS branding_admin_delete ON storage.objects;
CREATE POLICY branding_admin_delete
  ON storage.objects FOR DELETE
  USING (bucket_id = 'branding' AND public.current_user_is_super_admin());

-- MooMoo — modèle de rôles cumulables et suspension de compte.
--
-- Choix : une table (user_id, role) et non une colonne `role` sur profiles,
-- parce qu'un même compte peut être à la fois enseignant et expert en langue
-- des signes, et qu'une colonne unique obligerait à inventer des combinaisons.
--
-- profiles.is_admin reste la source de vérité pour les politiques RLS, le
-- backend et l'application : tout est déjà écrit dessus (is_current_user_admin,
-- assertAdmin, isAdminProvider). Un trigger sur user_roles le maintient en
-- miroir du rôle 'admin', ce qui évite de réécrire toutes les politiques.
--
-- Apply with: cd backend && npm run migrate

-- ---------------------------------------------------------------------------
-- Rôles
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  role text NOT NULL,
  granted_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  granted_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role),
  CONSTRAINT user_roles_role_check
    CHECK (role IN ('admin', 'teacher', 'sign_expert'))
);

-- Compter les admins restants avant d'en retirer un : filtre sur role seul.
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles (role);

-- ---------------------------------------------------------------------------
-- Suspension
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active';

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS suspended_at timestamptz;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS suspended_reason text;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS suspended_by uuid
    REFERENCES auth.users (id) ON DELETE SET NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_status_check'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_status_check
      CHECK (status IN ('active', 'suspended'));
  END IF;
END $$;

-- Index partiel : les comptes suspendus sont une poignée, les actifs sont tout
-- le reste, indexer 'active' n'apporterait rien.
CREATE INDEX IF NOT EXISTS idx_profiles_suspended
  ON public.profiles (status)
  WHERE status <> 'active';

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_has_role(p_role text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = p_role
  );
$$;

REVOKE ALL ON FUNCTION public.current_user_has_role(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_has_role(text) TO authenticated, anon;

-- Renvoie true quand il n'y a pas de profil (service role, anon) : les
-- politiques concernées exigent déjà auth.uid() = user_id, ce défaut ne peut
-- donc pas ouvrir d'accès, il évite juste de casser l'administration serveur.
CREATE OR REPLACE FUNCTION public.current_user_is_active()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT status = 'active' FROM public.profiles WHERE id = auth.uid()),
    true
  );
$$;

REVOKE ALL ON FUNCTION public.current_user_is_active() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_is_active() TO authenticated, anon;

-- ---------------------------------------------------------------------------
-- profiles.is_admin en miroir de user_roles
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_profile_admin_flag()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target uuid := COALESCE(NEW.user_id, OLD.user_id);
  should_be_admin boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = target AND role = 'admin'
  ) INTO should_be_admin;

  UPDATE public.profiles
  SET is_admin = should_be_admin,
      updated_at = now()
  WHERE id = target
    AND is_admin IS DISTINCT FROM should_be_admin;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS sync_profile_admin_flag ON public.user_roles;
CREATE TRIGGER sync_profile_admin_flag
  AFTER INSERT OR UPDATE OR DELETE ON public.user_roles
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_profile_admin_flag();

-- Reprise de l'existant : les comptes déjà admin via is_admin obtiennent la
-- ligne user_roles correspondante, sinon ils apparaîtraient sans rôle dans la
-- nouvelle interface et le premier retrait de rôle les déclasserait.
INSERT INTO public.user_roles (user_id, role)
SELECT p.id, 'admin'
FROM public.profiles p
WHERE p.is_admin = true
ON CONFLICT (user_id, role) DO NOTHING;

-- ---------------------------------------------------------------------------
-- RLS : user_roles
-- ---------------------------------------------------------------------------
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own roles" ON public.user_roles;
CREATE POLICY "Users read own roles"
  ON public.user_roles FOR SELECT
  USING (auth.uid() = user_id OR public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins insert roles" ON public.user_roles;
CREATE POLICY "Admins insert roles"
  ON public.user_roles FOR INSERT
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins delete roles" ON public.user_roles;
CREATE POLICY "Admins delete roles"
  ON public.user_roles FOR DELETE
  USING (public.is_current_user_admin());

-- Pas de politique UPDATE : un rôle se remplace en supprimant puis insérant,
-- il n'y a rien à modifier dans une ligne (user_id, role).

-- ---------------------------------------------------------------------------
-- Protection des colonnes de privilège et de statut
--
-- « Users can update own profile » accorde l'UPDATE sur la ligne entière et RLS
-- n'a pas de granularité colonne. Sans ce garde-fou, un utilisateur suspendu
-- lèverait lui-même sa suspension d'un simple PATCH PostgREST sur son profil.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_profile_privileges()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- auth.uid() est NULL pour le service role (qui contourne RLS) et pour anon
  -- (qui n'a aucune ligne à modifier) : l'administration serveur reste possible.
  IF auth.uid() IS NULL OR public.is_current_user_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.is_admin IS DISTINCT FROM OLD.is_admin THEN
    RAISE EXCEPTION 'Only admins can change is_admin'
      USING ERRCODE = '42501';
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status
     OR NEW.suspended_at IS DISTINCT FROM OLD.suspended_at
     OR NEW.suspended_reason IS DISTINCT FROM OLD.suspended_reason
     OR NEW.suspended_by IS DISTINCT FROM OLD.suspended_by THEN
    RAISE EXCEPTION 'Only admins can change the account status'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_profile_privileges ON public.profiles;
CREATE TRIGGER protect_profile_privileges
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_privileges();

-- ---------------------------------------------------------------------------
-- Un compte suspendu ne peut plus écrire
--
-- Politiques RESTRICTIVE : elles sont combinées en AND avec les politiques
-- permissives existantes, ce qui évite de réécrire (et de risquer de casser)
-- « own_favorites », « own_progress », « own_sessions_* », etc. La lecture et
-- la suppression restent possibles : on bloque la production de contenu, on ne
-- séquestre pas les données déjà créées.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'contributions',
    'favorites',
    'translation_sessions',
    'translation_entries',
    'user_progress'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = tbl
    ) THEN
      RAISE WARNING 'public.% absente, politique de suspension non posée', tbl;
      CONTINUE;
    END IF;

    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I',
      'Suspended accounts cannot insert', tbl
    );
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR INSERT
         WITH CHECK (public.current_user_is_active())',
      'Suspended accounts cannot insert', tbl
    );

    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I',
      'Suspended accounts cannot update', tbl
    );
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR UPDATE
         USING (public.current_user_is_active())
         WITH CHECK (public.current_user_is_active())',
      'Suspended accounts cannot update', tbl
    );
  END LOOP;
END $$;

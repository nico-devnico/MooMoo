-- MooMoo — espaces par rôle, gestion du dictionnaire, configuration globale.
--
-- Rôles (public.user_roles) :
--   admin        tout ;
--   sign_expert  dictionnaire (création, édition, catégories, publication) et
--                modération des contributions ; la suppression reste admin ;
--   teacher      parcours d'apprentissage (déjà couvert par
--                current_user_can_edit_learning) et statistiques agrégées.
--
-- Maintenance : appliquée ici, pas seulement dans l'interface. Pendant une
-- maintenance, seuls les administrateurs peuvent écrire.
--
-- Apply with: cd backend && npm run migrate

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_can_edit_dictionary()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_current_user_admin()
      OR EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid() AND role = 'sign_expert'
      );
$$;

REVOKE ALL ON FUNCTION public.current_user_can_edit_dictionary() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_can_edit_dictionary() TO authenticated, anon;

CREATE OR REPLACE FUNCTION public.current_user_roles()
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(array_agg(role ORDER BY role), ARRAY[]::text[])
  FROM public.user_roles
  WHERE user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.current_user_roles() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_roles() TO authenticated;

-- ---------------------------------------------------------------------------
-- Dictionnaire : les experts éditent, seul l'admin supprime
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Validated signs are public" ON public.signs;
CREATE POLICY "Validated signs are public"
  ON public.signs FOR SELECT
  USING (is_validated = true OR public.current_user_can_edit_dictionary());

DROP POLICY IF EXISTS "Dictionary editors insert signs" ON public.signs;
CREATE POLICY "Dictionary editors insert signs"
  ON public.signs FOR INSERT
  WITH CHECK (public.current_user_can_edit_dictionary());

DROP POLICY IF EXISTS "Dictionary editors update signs" ON public.signs;
CREATE POLICY "Dictionary editors update signs"
  ON public.signs FOR UPDATE
  USING (public.current_user_can_edit_dictionary())
  WITH CHECK (public.current_user_can_edit_dictionary());

DROP POLICY IF EXISTS "Dictionary editors insert categories" ON public.sign_categories;
CREATE POLICY "Dictionary editors insert categories"
  ON public.sign_categories FOR INSERT
  WITH CHECK (public.current_user_can_edit_dictionary());

DROP POLICY IF EXISTS "Dictionary editors update categories" ON public.sign_categories;
CREATE POLICY "Dictionary editors update categories"
  ON public.sign_categories FOR UPDATE
  USING (public.current_user_can_edit_dictionary())
  WITH CHECK (public.current_user_can_edit_dictionary());

-- Détection des doublons à l'import et dans l'éditeur (même mot, même langue).
CREATE INDEX IF NOT EXISTS idx_signs_language_lower_word
  ON public.signs (sign_language_id, lower(btrim(word)));

-- ---------------------------------------------------------------------------
-- Modération : les experts relisent les contributions
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users see own contributions" ON public.contributions;
CREATE POLICY "Users see own contributions"
  ON public.contributions FOR SELECT
  USING (auth.uid() = contributor_id OR public.current_user_can_edit_dictionary());

DROP POLICY IF EXISTS "Admins update contributions" ON public.contributions;
DROP POLICY IF EXISTS "Reviewers update contributions" ON public.contributions;
CREATE POLICY "Reviewers update contributions"
  ON public.contributions FOR UPDATE
  USING (public.current_user_can_edit_dictionary())
  WITH CHECK (public.current_user_can_edit_dictionary());

-- ---------------------------------------------------------------------------
-- Stockage
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS admins_read_contributions ON storage.objects;
DROP POLICY IF EXISTS reviewers_read_contributions ON storage.objects;
CREATE POLICY reviewers_read_contributions
  ON storage.objects FOR SELECT
  USING (bucket_id = 'contributions' AND public.current_user_can_edit_dictionary());

DROP POLICY IF EXISTS dictionary_media_read ON storage.objects;
CREATE POLICY dictionary_media_read
  ON storage.objects FOR SELECT
  USING (bucket_id IN ('sign-videos', 'sign-thumbnails')
         AND public.current_user_can_edit_dictionary());

DROP POLICY IF EXISTS dictionary_media_insert ON storage.objects;
CREATE POLICY dictionary_media_insert
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id IN ('sign-videos', 'sign-thumbnails')
              AND public.current_user_can_edit_dictionary());

DROP POLICY IF EXISTS dictionary_media_update ON storage.objects;
CREATE POLICY dictionary_media_update
  ON storage.objects FOR UPDATE
  USING (bucket_id IN ('sign-videos', 'sign-thumbnails')
         AND public.current_user_can_edit_dictionary());

DROP POLICY IF EXISTS dictionary_media_delete ON storage.objects;
CREATE POLICY dictionary_media_delete
  ON storage.objects FOR DELETE
  USING (bucket_id IN ('sign-videos', 'sign-thumbnails')
         AND public.is_current_user_admin());

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('branding', 'branding', true, 2097152,
        ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/gif'])
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS branding_admin_read ON storage.objects;
CREATE POLICY branding_admin_read
  ON storage.objects FOR SELECT
  USING (bucket_id = 'branding' AND public.is_current_user_admin());

DROP POLICY IF EXISTS branding_admin_insert ON storage.objects;
CREATE POLICY branding_admin_insert
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'branding' AND public.is_current_user_admin());

DROP POLICY IF EXISTS branding_admin_update ON storage.objects;
CREATE POLICY branding_admin_update
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'branding' AND public.is_current_user_admin());

DROP POLICY IF EXISTS branding_admin_delete ON storage.objects;
CREATE POLICY branding_admin_delete
  ON storage.objects FOR DELETE
  USING (bucket_id = 'branding' AND public.is_current_user_admin());

-- ---------------------------------------------------------------------------
-- Configuration globale (une seule ligne)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_settings (
  id boolean PRIMARY KEY DEFAULT true CHECK (id),
  app_name text NOT NULL DEFAULT 'MooMoo'
    CHECK (length(btrim(app_name)) BETWEEN 1 AND 40),
  logo_url text
    CHECK (logo_url IS NULL OR logo_url ~* '^https?://'),
  maintenance_enabled boolean NOT NULL DEFAULT false,
  maintenance_message text
    CHECK (maintenance_message IS NULL OR length(maintenance_message) <= 500),
  support_email text
    CHECK (support_email IS NULL OR support_email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  default_sign_language_id integer
    REFERENCES public.sign_languages (id) ON DELETE SET NULL,
  contributions_enabled boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users (id) ON DELETE SET NULL
);

INSERT INTO public.app_settings (id) VALUES (true) ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Lisible par tous, y compris hors connexion : l'écran de maintenance et le
-- nom de l'application s'affichent avant l'authentification.
DROP POLICY IF EXISTS "Anyone reads app settings" ON public.app_settings;
CREATE POLICY "Anyone reads app settings"
  ON public.app_settings FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admins update app settings" ON public.app_settings;
CREATE POLICY "Admins update app settings"
  ON public.app_settings FOR UPDATE
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

GRANT SELECT ON public.app_settings TO anon, authenticated;
GRANT UPDATE ON public.app_settings TO authenticated;

CREATE OR REPLACE FUNCTION public.touch_app_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.id := true;
  NEW.updated_at := now();
  NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
  NEW.app_name := btrim(NEW.app_name);
  NEW.maintenance_message := NULLIF(btrim(NEW.maintenance_message), '');
  NEW.support_email := NULLIF(btrim(NEW.support_email), '');
  NEW.logo_url := NULLIF(btrim(NEW.logo_url), '');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS app_settings_touch ON public.app_settings;
CREATE TRIGGER app_settings_touch
  BEFORE UPDATE ON public.app_settings
  FOR EACH ROW EXECUTE FUNCTION public.touch_app_settings();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'app_settings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.app_settings;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Maintenance et contributions : appliquées en base
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.app_accepts_writes()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_current_user_admin()
      OR COALESCE((SELECT NOT maintenance_enabled FROM public.app_settings WHERE id), true);
$$;

REVOKE ALL ON FUNCTION public.app_accepts_writes() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.app_accepts_writes() TO authenticated, anon;

DO $$
DECLARE
  tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'contributions', 'favorites', 'translation_sessions', 'translation_entries',
    'user_progress', 'profiles', 'notifications', 'signs', 'sign_categories',
    'learning_units', 'learning_lessons', 'lesson_signs', 'ml_datasets', 'training_jobs'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = tbl
    ) THEN
      CONTINUE;
    END IF;

    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', 'Maintenance blocks insert', tbl);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR INSERT WITH CHECK (public.app_accepts_writes())',
      'Maintenance blocks insert', tbl);

    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', 'Maintenance blocks update', tbl);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR UPDATE USING (public.app_accepts_writes()) WITH CHECK (public.app_accepts_writes())',
      'Maintenance blocks update', tbl);

    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', 'Maintenance blocks delete', tbl);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR DELETE USING (public.app_accepts_writes())',
      'Maintenance blocks delete', tbl);
  END LOOP;
END;
$$;

DROP POLICY IF EXISTS "Contributions must be open" ON public.contributions;
CREATE POLICY "Contributions must be open"
  ON public.contributions AS RESTRICTIVE FOR INSERT
  WITH CHECK (
    public.is_current_user_admin()
    OR COALESCE((SELECT contributions_enabled FROM public.app_settings WHERE id), true)
  );

-- ---------------------------------------------------------------------------
-- Tableaux de bord des espaces (agrégats uniquement, aucune donnée nominative)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.teacher_overview()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result jsonb;
BEGIN
  IF NOT public.current_user_can_edit_learning() THEN
    RAISE EXCEPTION 'teacher_overview: forbidden' USING ERRCODE = '42501';
  END IF;

  SELECT jsonb_build_object(
    'units_total', (SELECT count(*) FROM public.learning_units),
    'units_published', (SELECT count(*) FROM public.learning_units WHERE is_published),
    'lessons_total', (SELECT count(*) FROM public.learning_lessons),
    'learners_total', (SELECT count(DISTINCT user_id) FROM public.lesson_completions),
    'completions_total', (SELECT count(*) FROM public.lesson_completions),
    'completions_7d', (SELECT count(*) FROM public.lesson_completions
                       WHERE completed_at > now() - interval '7 days'),
    'average_score', (SELECT round(avg(correct_count::numeric / question_count) * 100, 1)
                      FROM public.lesson_completions),
    'lessons', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
               'lesson_id', l.id,
               'lesson_title', l.title,
               'unit_title', u.title,
               'unit_published', u.is_published,
               'completions', COALESCE(s.completions, 0),
               'learners', COALESCE(s.learners, 0),
               'average_score', s.average_score,
               'last_completed_at', s.last_completed_at
             ) ORDER BY u.order_index, l.order_index)
      FROM public.learning_lessons l
      JOIN public.learning_units u ON u.id = l.unit_id
      LEFT JOIN (
        SELECT lesson_id,
               count(*) AS completions,
               count(DISTINCT user_id) AS learners,
               round(avg(correct_count::numeric / question_count) * 100, 1) AS average_score,
               max(completed_at) AS last_completed_at
        FROM public.lesson_completions
        GROUP BY lesson_id
      ) s ON s.lesson_id = l.id
    ), '[]'::jsonb)
  ) INTO result;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION public.teacher_overview() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.teacher_overview() TO authenticated;

CREATE OR REPLACE FUNCTION public.expert_overview()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result jsonb;
BEGIN
  IF NOT public.current_user_can_edit_dictionary() THEN
    RAISE EXCEPTION 'expert_overview: forbidden' USING ERRCODE = '42501';
  END IF;

  SELECT jsonb_build_object(
    'pending_contributions', (SELECT count(*) FROM public.contributions WHERE status = 'pending'),
    'reviewed_by_me', (SELECT count(*) FROM public.contributions WHERE reviewer_id = auth.uid()),
    'signs_total', (SELECT count(*) FROM public.signs),
    'signs_published', (SELECT count(*) FROM public.signs WHERE is_validated),
    'signs_draft', (SELECT count(*) FROM public.signs WHERE NOT COALESCE(is_validated, false)),
    'signs_without_video', (SELECT count(*) FROM public.signs WHERE NULLIF(btrim(video_url), '') IS NULL),
    'signs_without_category', (SELECT count(*) FROM public.signs WHERE category_id IS NULL),
    'categories_total', (SELECT count(*) FROM public.sign_categories),
    'languages', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
               'code', sl.code,
               'name', sl.name,
               'signs', (SELECT count(*) FROM public.signs s WHERE s.sign_language_id = sl.id),
               'published', (SELECT count(*) FROM public.signs s
                             WHERE s.sign_language_id = sl.id AND s.is_validated)
             ) ORDER BY sl.id)
      FROM public.sign_languages sl
    ), '[]'::jsonb)
  ) INTO result;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION public.expert_overview() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.expert_overview() TO authenticated;

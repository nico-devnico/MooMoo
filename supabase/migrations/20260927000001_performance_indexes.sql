-- MooMoo — index de performance + agrégat de statistiques admin.
--
-- Les index ajoutés ici correspondent exactement aux filtres et aux tris
-- envoyés par l'application (repositories Dart) :
--
--   signs                : WHERE is_validated ORDER BY word           (dictionnaire)
--                          WHERE is_validated AND word ILIKE '%…%'    (recherche)
--                          ORDER BY created_at DESC                   (liste admin)
--   contributions        : WHERE contributor_id ORDER BY submitted_at DESC
--                          WHERE status ORDER BY submitted_at DESC
--   notifications        : WHERE user_id ORDER BY created_at DESC, badge non lus
--   favorites            : WHERE user_id ORDER BY created_at DESC
--   translation_sessions : WHERE user_id ORDER BY started_at DESC
--   translation_entries  : WHERE session_id ORDER BY created_at
--   profiles             : ORDER BY created_at DESC + recherche nom/email
--
-- Apply with: cd backend && npm run migrate

-- ---------------------------------------------------------------------------
-- Recherche plein texte approximative : ILIKE '%mot%' ne peut pas utiliser un
-- B-tree, il faut un index trigram.
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;

CREATE INDEX IF NOT EXISTS idx_signs_word_trgm
  ON public.signs USING gin (word extensions.gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_profiles_display_name_trgm
  ON public.profiles USING gin (display_name extensions.gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_profiles_email_trgm
  ON public.profiles USING gin (email extensions.gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- signs
-- ---------------------------------------------------------------------------
-- Dictionnaire : filtre sur is_validated puis tri alphabétique.
CREATE INDEX IF NOT EXISTS idx_signs_validated_word
  ON public.signs (is_validated, word);

-- Dictionnaire filtré par langue / catégorie (les deux sont combinés au filtre
-- is_validated et au tri sur word).
CREATE INDEX IF NOT EXISTS idx_signs_language_validated_word
  ON public.signs (sign_language_id, is_validated, word);

CREATE INDEX IF NOT EXISTS idx_signs_category_validated_word
  ON public.signs (category_id, is_validated, word);

-- Liste admin : tri récent en premier, avec ou sans filtre de validation.
CREATE INDEX IF NOT EXISTS idx_signs_created_at
  ON public.signs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_signs_validated_created_at
  ON public.signs (is_validated, created_at DESC);

-- ---------------------------------------------------------------------------
-- contributions
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_contributions_contributor_submitted
  ON public.contributions (contributor_id, submitted_at DESC);

CREATE INDEX IF NOT EXISTS idx_contributions_status_submitted
  ON public.contributions (status, submitted_at DESC);

CREATE INDEX IF NOT EXISTS idx_contributions_submitted_at
  ON public.contributions (submitted_at DESC);

-- ---------------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON public.notifications (user_id, created_at DESC);

-- Badge « non lues » : index partiel, très petit.
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id)
  WHERE is_read = false;

-- ---------------------------------------------------------------------------
-- favorites
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_favorites_user_created
  ON public.favorites (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_favorites_sign
  ON public.favorites (sign_id);

-- ---------------------------------------------------------------------------
-- historique de traduction
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_sessions_user_started
  ON public.translation_sessions (user_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_entries_session_created
  ON public.translation_entries (session_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- profils (liste admin) et catégories
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profiles_created_at
  ON public.profiles (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sign_categories_language_order
  ON public.sign_categories (sign_language_id, order_index);

-- ---------------------------------------------------------------------------
-- Statistiques admin en un seul aller-retour.
-- L'app faisait trois SELECT séquentiels rapatriant toutes les lignes de
-- profiles, signs et contributions pour les compter en Dart.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_stats()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result jsonb;
BEGIN
  IF NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'admin_stats: forbidden' USING ERRCODE = '42501';
  END IF;

  SELECT jsonb_build_object(
    'users_count', (SELECT count(*) FROM public.profiles),
    'signs_count', (SELECT count(*) FROM public.signs),
    'validated_signs_count',
      (SELECT count(*) FROM public.signs WHERE is_validated = true),
    'pending_contributions_count',
      (SELECT count(*) FROM public.contributions WHERE status = 'pending'),
    'approved_contributions_count',
      (SELECT count(*) FROM public.contributions WHERE status = 'approved'),
    'rejected_contributions_count',
      (SELECT count(*) FROM public.contributions WHERE status = 'rejected')
  ) INTO result;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_stats() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_stats() TO authenticated;

ANALYZE public.signs;
ANALYZE public.contributions;
ANALYZE public.notifications;
ANALYZE public.favorites;
ANALYZE public.profiles;

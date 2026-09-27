-- MooMoo — suppression de deux politiques RLS permissives présentes en base
-- mais absentes de toute migration versionnée (créées à la main au début du
-- projet, avant que le schéma ne soit suivi dans ce dépôt).
--
--   public.signs          public_read_signs   USING (true)
--   public.contributions  read_contributions  USING (true)
--
-- Les politiques permissives sont combinées avec OR : tant que `USING (true)`
-- existe, la politique correcte posée à côté ne restreint plus rien.
--
--   * read_contributions exposait les contributions de TOUS les utilisateurs
--     (mot proposé, description, URL de la vidéo, contributor_id, note du
--     modérateur) à n'importe quel porteur de la clé anon, alors que
--     « Users see own contributions » limite déjà la lecture à l'auteur ou à
--     un admin. C'est la fuite la plus grave : des données personnelles non
--     publiées, rattachables à un utilisateur.
--   * public_read_signs rendait lisibles les signes NON validés, c'est-à-dire
--     du contenu en cours de modération, alors que « Validated signs are
--     public » n'ouvre le dictionnaire que sur is_validated = true.
--
-- Apply with: cd backend && npm run migrate

-- ---------------------------------------------------------------------------
-- 1. On (re)pose d'abord les politiques correctes, pour que la suppression des
--    politiques héritées ne puisse jamais laisser une table sans lecture.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Validated signs are public" ON public.signs;
CREATE POLICY "Validated signs are public"
  ON public.signs FOR SELECT
  USING (is_validated = true OR public.is_current_user_admin());

DROP POLICY IF EXISTS "Users see own contributions" ON public.contributions;
CREATE POLICY "Users see own contributions"
  ON public.contributions FOR SELECT
  USING (auth.uid() = contributor_id OR public.is_current_user_admin());

-- ---------------------------------------------------------------------------
-- 2. Suppression des politiques héritées.
--    `insert_contribution` est un doublon exact de « Users insert own
--    contributions » (même WITH CHECK) : du bruit, supprimé au passage comme
--    la migration 20260324000005 l'a fait pour profiles.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS public_read_signs ON public.signs;
DROP POLICY IF EXISTS read_contributions ON public.contributions;
DROP POLICY IF EXISTS insert_contribution ON public.contributions;

-- ---------------------------------------------------------------------------
-- 3. Garde-fous : la migration échoue plutôt que de laisser la base dans un
--    état où la lecture serait soit ouverte à tous, soit complètement fermée.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  tbl text;
  open_reads int;
  read_policies int;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['signs', 'contributions'] LOOP
    SELECT count(*) INTO open_reads
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = tbl
      AND permissive = 'PERMISSIVE'
      AND cmd IN ('SELECT', 'ALL')
      AND btrim(coalesce(qual, '')) = 'true';

    IF open_reads > 0 THEN
      RAISE EXCEPTION
        'public.%: il reste % politique(s) de lecture permissive USING (true)',
        tbl, open_reads;
    END IF;

    SELECT count(*) INTO read_policies
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = tbl
      AND permissive = 'PERMISSIVE'
      AND cmd IN ('SELECT', 'ALL');

    IF read_policies = 0 THEN
      RAISE EXCEPTION
        'public.%: plus aucune politique de lecture, la table serait inaccessible',
        tbl;
    END IF;
  END LOOP;
END $$;

-- MooMoo — purge des données de simulation.
--
-- 20260324000002_ai_models_schema.sql insère deux modèles de démonstration et
-- deux relevés de métriques inventés (accuracy 0.8720, latence 145 ms, note
-- « Seed metrics — replace after real evaluation »). Aucun modèle n'a jamais
-- été entraîné : l'interface admin affichait donc des chiffres crédibles mais
-- faux, ce qui est pire que rien.
--
-- Le bloc INSERT n'est PAS retiré de 20260324000002 : cette migration est déjà
-- appliquée en production et le suivi dans supabase_migrations.schema_migrations
-- ne la rejouera jamais. Modifier un fichier déjà appliqué rendrait le dépôt
-- menteur sur l'état réel de la base et casserait toute base reconstruite à
-- partir de zéro à un moment différent. On supprime donc par une migration
-- nouvelle, en avant, jamais en réécrivant l'historique.
--
-- Les 3 lignes de public.sign_languages (LSF, ASL, CSL) sont conservées : ce
-- sont des données de référence, pas de la simulation.
--
-- Apply with: cd backend && npm run migrate

-- ---------------------------------------------------------------------------
-- Modèles semés et leurs métriques
-- ---------------------------------------------------------------------------
DELETE FROM public.model_metrics
WHERE model_id IN (
  'a1000000-0000-4000-8000-000000000001',
  'a1000000-0000-4000-8000-000000000002'
);

-- training_jobs référence ml_models en ON DELETE SET NULL, mais un job qui
-- pointe vers un modèle de démonstration n'a pas plus de sens que le modèle.
DELETE FROM public.training_jobs
WHERE model_id IN (
    'a1000000-0000-4000-8000-000000000001',
    'a1000000-0000-4000-8000-000000000002'
  )
  OR result_model_id IN (
    'a1000000-0000-4000-8000-000000000001',
    'a1000000-0000-4000-8000-000000000002'
  );

DELETE FROM public.ml_models
WHERE id IN (
  'a1000000-0000-4000-8000-000000000001',
  'a1000000-0000-4000-8000-000000000002'
);

-- ---------------------------------------------------------------------------
-- Tables mortes : RLS activé sans aucune politique, donc inaccessibles depuis
-- l'application, et aucune référence dans lib/ ni backend/.
--   public.ai_models          remplacée par public.ml_models
--   public.translation_cache  jamais lue ni écrite
-- Supprimées uniquement si elles sont vides ; sinon conservées et signalées.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  tbl text;
  rows_left bigint;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['ai_models', 'translation_cache'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = tbl
    ) THEN
      RAISE NOTICE 'public.% déjà absente', tbl;
      CONTINUE;
    END IF;

    EXECUTE format('SELECT count(*) FROM public.%I', tbl) INTO rows_left;

    IF rows_left = 0 THEN
      EXECUTE format('DROP TABLE public.%I', tbl);
      RAISE NOTICE 'public.% supprimée (0 ligne)', tbl;
    ELSE
      RAISE WARNING
        'public.% CONSERVEE : % ligne(s) presentes, suppression annulee',
        tbl, rows_left;
    END IF;
  END LOOP;
END $$;

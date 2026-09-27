-- MooMoo — plateforme d'entraînement des modèles de reconnaissance de signes.
--
-- Datasets -> jobs (file d'attente consommée par le worker ML) -> expériences
-- (EXP-001, ...) -> historique par epoch -> registre de modèles à étapes
-- TRAINING -> TRAINED -> EVALUATED -> VALIDATED -> STAGING -> PRODUCTION.
--
-- Le worker Python écrit avec la connexion serveur (rôle postgres, hors RLS) ;
-- l'application ne lit ces tables qu'en admin.
--
-- Apply with: cd backend && npm run migrate

-- ---------------------------------------------------------------------------
-- Suppression de compte : un relecteur supprimé ne doit pas bloquer l'opération
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  con text;
BEGIN
  SELECT c.conname INTO con
  FROM pg_constraint c
  JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
  WHERE c.conrelid = 'public.contributions'::regclass
    AND c.contype = 'f' AND a.attname = 'reviewer_id';
  IF con IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.contributions DROP CONSTRAINT %I', con);
  END IF;
  ALTER TABLE public.contributions
    ADD CONSTRAINT contributions_reviewer_id_fkey
    FOREIGN KEY (reviewer_id) REFERENCES public.profiles (id) ON DELETE SET NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Langues de référence demandées pour les datasets (LSFB : Belgique francophone)
-- ---------------------------------------------------------------------------
INSERT INTO public.sign_languages (code, name, country, is_active)
SELECT 'LSFB', 'Langue des signes de Belgique francophone', 'BE', true
WHERE NOT EXISTS (SELECT 1 FROM public.sign_languages WHERE code = 'LSFB');

-- ---------------------------------------------------------------------------
-- Datasets
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ml_datasets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (length(trim(name)) > 0),
  language_code text NOT NULL CHECK (language_code ~ '^[A-Z0-9_-]{2,16}$'),
  source_type text NOT NULL CHECK (source_type IN ('local', 'url')),
  uri text NOT NULL CHECK (length(trim(uri)) > 0),
  media_format text NOT NULL DEFAULT 'auto'
    CHECK (media_format IN ('auto', 'images', 'gif', 'video', 'mixed')),
  is_structured boolean NOT NULL DEFAULT true,
  is_labeled boolean NOT NULL DEFAULT true,
  -- Pour les datasets non étiquetés ou mal nommés : {"chemin/relatif": "label"}.
  label_mapping jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'registered'
    CHECK (status IN ('registered', 'analyzing', 'analyzed', 'preprocessing', 'ready', 'failed')),
  analysis jsonb,
  preprocessing jsonb,
  error_message text,
  created_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ml_datasets_language ON public.ml_datasets (language_code, created_at DESC);

DROP TRIGGER IF EXISTS update_ml_datasets_updated_at ON public.ml_datasets;
CREATE TRIGGER update_ml_datasets_updated_at
  BEFORE UPDATE ON public.ml_datasets
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ---------------------------------------------------------------------------
-- Jobs : la table existante devient la file d'attente du worker
-- ---------------------------------------------------------------------------
ALTER TABLE public.training_jobs DROP CONSTRAINT IF EXISTS training_jobs_dataset_check;
ALTER TABLE public.training_jobs DROP CONSTRAINT IF EXISTS training_jobs_status_check;
ALTER TABLE public.training_jobs
  ADD CONSTRAINT training_jobs_status_check
  CHECK (status IN ('queued', 'running', 'cancelling', 'cancelled', 'done', 'failed'));

ALTER TABLE public.training_jobs
  ADD COLUMN IF NOT EXISTS kind text NOT NULL DEFAULT 'train',
  ADD COLUMN IF NOT EXISTS dataset_id uuid REFERENCES public.ml_datasets (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS language_code text,
  ADD COLUMN IF NOT EXISTS config jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS current_epoch integer,
  ADD COLUMN IF NOT EXISTS total_epochs integer,
  ADD COLUMN IF NOT EXISTS message text,
  ADD COLUMN IF NOT EXISTS result jsonb,
  ADD COLUMN IF NOT EXISTS worker_id text,
  ADD COLUMN IF NOT EXISTS heartbeat_at timestamptz,
  ADD COLUMN IF NOT EXISTS attempts integer NOT NULL DEFAULT 0;

ALTER TABLE public.training_jobs DROP CONSTRAINT IF EXISTS training_jobs_kind_check;
ALTER TABLE public.training_jobs
  ADD CONSTRAINT training_jobs_kind_check
  CHECK (kind IN ('analyze', 'preprocess', 'train', 'search', 'evaluate', 'convert'));

CREATE INDEX IF NOT EXISTS idx_training_jobs_queue
  ON public.training_jobs (created_at) WHERE status = 'queued';

-- ---------------------------------------------------------------------------
-- Expériences
-- ---------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS public.ml_experiment_seq;

CREATE TABLE IF NOT EXISTS public.ml_experiments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE
    DEFAULT ('EXP-' || lpad(nextval('public.ml_experiment_seq')::text, 3, '0')),
  job_id uuid REFERENCES public.training_jobs (id) ON DELETE SET NULL,
  dataset_id uuid REFERENCES public.ml_datasets (id) ON DELETE SET NULL,
  language_code text NOT NULL,
  config jsonb NOT NULL,
  status text NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'running', 'completed', 'failed', 'pruned', 'cancelled')),
  -- Hyperband : budget d'epochs du palier courant et palier atteint.
  budget_epochs integer,
  rung integer,
  current_epoch integer NOT NULL DEFAULT 0,
  total_epochs integer,
  best_val_accuracy double precision,
  best_val_loss double precision,
  metrics jsonb,
  per_class jsonb,
  confusion_matrix jsonb,
  labels jsonb,
  params_count bigint,
  model_size_bytes bigint,
  duration_s double precision,
  artifacts jsonb,
  model_id uuid REFERENCES public.ml_models (id) ON DELETE SET NULL,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  started_at timestamptz,
  finished_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_ml_experiments_job ON public.ml_experiments (job_id, created_at);
CREATE INDEX IF NOT EXISTS idx_ml_experiments_language ON public.ml_experiments (language_code, created_at DESC);

CREATE TABLE IF NOT EXISTS public.ml_epoch_metrics (
  id bigserial PRIMARY KEY,
  experiment_id uuid NOT NULL REFERENCES public.ml_experiments (id) ON DELETE CASCADE,
  epoch integer NOT NULL,
  loss double precision,
  accuracy double precision,
  val_loss double precision,
  val_accuracy double precision,
  learning_rate double precision,
  duration_s double precision,
  recorded_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (experiment_id, epoch)
);

CREATE TABLE IF NOT EXISTS public.training_logs (
  id bigserial PRIMARY KEY,
  job_id uuid NOT NULL REFERENCES public.training_jobs (id) ON DELETE CASCADE,
  experiment_id uuid REFERENCES public.ml_experiments (id) ON DELETE CASCADE,
  level text NOT NULL DEFAULT 'info' CHECK (level IN ('debug', 'info', 'warning', 'error')),
  message text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_training_logs_job ON public.training_logs (job_id, id DESC);

-- ---------------------------------------------------------------------------
-- Registre de modèles
-- ---------------------------------------------------------------------------
ALTER TABLE public.ml_models DROP CONSTRAINT IF EXISTS ml_models_dataset_check;

ALTER TABLE public.ml_models
  ADD COLUMN IF NOT EXISTS language_code text,
  ADD COLUMN IF NOT EXISTS stage text NOT NULL DEFAULT 'trained',
  ADD COLUMN IF NOT EXISTS experiment_id uuid REFERENCES public.ml_experiments (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS dataset_id uuid REFERENCES public.ml_datasets (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS classes jsonb,
  ADD COLUMN IF NOT EXISTS architecture jsonb,
  ADD COLUMN IF NOT EXISTS input_shape jsonb,
  ADD COLUMN IF NOT EXISTS hyperparameters jsonb,
  ADD COLUMN IF NOT EXISTS metrics jsonb,
  ADD COLUMN IF NOT EXISTS tflite_metrics jsonb,
  ADD COLUMN IF NOT EXISTS training_duration_s double precision,
  ADD COLUMN IF NOT EXISTS size_bytes bigint,
  ADD COLUMN IF NOT EXISTS tflite_size_bytes bigint,
  ADD COLUMN IF NOT EXISTS artifacts jsonb,
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS promoted_at timestamptz;

ALTER TABLE public.ml_models DROP CONSTRAINT IF EXISTS ml_models_stage_check;
ALTER TABLE public.ml_models
  ADD CONSTRAINT ml_models_stage_check
  CHECK (stage IN ('training', 'trained', 'evaluated', 'validated', 'staging', 'production', 'archived'));

-- Un modèle actif (= en production) par langue, et non plus un seul au total.
DROP INDEX IF EXISTS public.idx_ml_models_single_active;
CREATE UNIQUE INDEX IF NOT EXISTS idx_ml_models_production_per_language
  ON public.ml_models (coalesce(language_code, dataset))
  WHERE stage = 'production';
CREATE UNIQUE INDEX IF NOT EXISTS idx_ml_models_active_per_language
  ON public.ml_models (coalesce(language_code, dataset))
  WHERE is_active = true;

-- ---------------------------------------------------------------------------
-- Transitions d'étapes (admin uniquement)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.promote_ml_model(p_model_id uuid, p_stage text)
RETURNS public.ml_models
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  m public.ml_models;
  lang text;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Only admins can change a model stage' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO m FROM public.ml_models WHERE id = p_model_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Model not found' USING ERRCODE = 'P0002';
  END IF;

  -- Chaque étape ne s'atteint que depuis la précédente : la production n'est
  -- jamais remplacée sans être passée par la validation puis le staging.
  IF NOT (
       (p_stage = 'validated'  AND m.stage = 'evaluated')
    OR (p_stage = 'staging'    AND m.stage IN ('validated', 'archived'))
    OR (p_stage = 'production' AND m.stage = 'staging')
    OR (p_stage = 'archived'   AND m.stage <> 'training')
  ) THEN
    RAISE EXCEPTION 'Transition % -> % not allowed', m.stage, p_stage USING ERRCODE = '22023';
  END IF;

  IF p_stage = 'validated' AND (m.metrics IS NULL OR m.metrics -> 'test' IS NULL) THEN
    RAISE EXCEPTION 'A model needs test metrics before validation' USING ERRCODE = '22023';
  END IF;

  lang := coalesce(m.language_code, m.dataset);

  IF p_stage = 'production' THEN
    UPDATE public.ml_models
    SET stage = 'archived', is_active = false, updated_at = now()
    WHERE coalesce(language_code, dataset) = lang
      AND stage = 'production' AND id <> m.id;
  END IF;

  UPDATE public.ml_models
  SET stage = p_stage,
      is_active = (p_stage = 'production'),
      status = CASE WHEN p_stage = 'archived' THEN 'deprecated' ELSE 'ready' END,
      promoted_at = CASE WHEN p_stage = 'production' THEN now() ELSE promoted_at END,
      updated_at = now()
  WHERE id = m.id
  RETURNING * INTO m;

  RETURN m;
END;
$$;

REVOKE ALL ON FUNCTION public.promote_ml_model(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.promote_ml_model(uuid, text) TO authenticated;

-- L'ancienne activation directe passe désormais par les mêmes règles.
CREATE OR REPLACE FUNCTION public.set_active_ml_model(p_model_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.promote_ml_model(p_model_id, 'production');
END;
$$;

-- ---------------------------------------------------------------------------
-- RLS : lecture et pilotage par les admins, écriture du pipeline par le worker
-- ---------------------------------------------------------------------------
ALTER TABLE public.ml_datasets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ml_experiments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ml_epoch_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage ml_datasets" ON public.ml_datasets;
CREATE POLICY "Admins manage ml_datasets"
  ON public.ml_datasets FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins read ml_experiments" ON public.ml_experiments;
CREATE POLICY "Admins read ml_experiments"
  ON public.ml_experiments FOR SELECT
  USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins read ml_epoch_metrics" ON public.ml_epoch_metrics;
CREATE POLICY "Admins read ml_epoch_metrics"
  ON public.ml_epoch_metrics FOR SELECT
  USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins read training_logs" ON public.training_logs;
CREATE POLICY "Admins read training_logs"
  ON public.training_logs FOR SELECT
  USING (public.is_current_user_admin());

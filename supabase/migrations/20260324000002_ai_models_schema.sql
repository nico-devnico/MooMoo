-- MooMoo AI model registry, metrics and training jobs
-- Datasets: WASL / LSFB (GIFs or images). No on-device GPU training.
-- Apply with: supabase db push

-- ---------------------------------------------------------------------------
-- Models
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ml_models (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  version text NOT NULL,
  dataset text NOT NULL
    CHECK (dataset IN ('WASL', 'LSFB', 'WASL+LSFB', 'other')),
  description text,
  artifact_url text,
  is_active boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'ready'
    CHECK (status IN ('draft', 'ready', 'deprecated', 'failed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (name, version)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ml_models_single_active
  ON public.ml_models (is_active)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_ml_models_dataset ON public.ml_models (dataset);

-- ---------------------------------------------------------------------------
-- Metrics (performance snapshots)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.model_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id uuid NOT NULL REFERENCES public.ml_models (id) ON DELETE CASCADE,
  accuracy numeric(5, 4),
  latency_ms numeric(10, 2),
  inference_count bigint NOT NULL DEFAULT 0,
  dataset text,
  recorded_at timestamptz NOT NULL DEFAULT now(),
  notes text
);

CREATE INDEX IF NOT EXISTS idx_model_metrics_model ON public.model_metrics (model_id, recorded_at DESC);

-- ---------------------------------------------------------------------------
-- Training jobs (queued / running / done / failed)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.training_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id uuid REFERENCES public.ml_models (id) ON DELETE SET NULL,
  requested_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  dataset text NOT NULL DEFAULT 'WASL+LSFB'
    CHECK (dataset IN ('WASL', 'LSFB', 'WASL+LSFB', 'other')),
  status text NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'running', 'done', 'failed')),
  progress numeric(5, 2) NOT NULL DEFAULT 0,
  error_message text,
  result_model_id uuid REFERENCES public.ml_models (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  started_at timestamptz,
  finished_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_training_jobs_status ON public.training_jobs (status, created_at DESC);

-- ---------------------------------------------------------------------------
-- Ensure only one active model when activating
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_active_ml_model(p_model_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Only admins can change the active model';
  END IF;

  UPDATE public.ml_models SET is_active = false, updated_at = now()
  WHERE is_active = true AND id <> p_model_id;

  UPDATE public.ml_models
  SET is_active = true, updated_at = now()
  WHERE id = p_model_id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_active_ml_model(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_active_ml_model(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Seed baseline models (idempotent)
-- ---------------------------------------------------------------------------
INSERT INTO public.ml_models (id, name, version, dataset, description, is_active, status)
VALUES
  (
    'a1000000-0000-4000-8000-000000000001',
    'moomoo-sign-recognizer',
    '1.0.0-wasl',
    'WASL',
    'Baseline recognizer trained on WASL GIF/image samples',
    true,
    'ready'
  ),
  (
    'a1000000-0000-4000-8000-000000000002',
    'moomoo-sign-recognizer',
    '1.0.0-lsfb',
    'LSFB',
    'Baseline recognizer trained on LSFB GIF/image samples',
    false,
    'ready'
  )
ON CONFLICT (name, version) DO NOTHING;

INSERT INTO public.model_metrics (model_id, accuracy, latency_ms, inference_count, dataset, notes)
SELECT m.id, 0.8720, 145.0, 0, m.dataset, 'Seed metrics — replace after real evaluation'
FROM public.ml_models m
WHERE m.version IN ('1.0.0-wasl', '1.0.0-lsfb')
  AND NOT EXISTS (
    SELECT 1 FROM public.model_metrics mm WHERE mm.model_id = m.id
  );

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.ml_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read ml_models" ON public.ml_models;
CREATE POLICY "Anyone can read ml_models"
  ON public.ml_models FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admins write ml_models" ON public.ml_models;
CREATE POLICY "Admins write ml_models"
  ON public.ml_models FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS "Anyone can read model_metrics" ON public.model_metrics;
CREATE POLICY "Anyone can read model_metrics"
  ON public.model_metrics FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admins write model_metrics" ON public.model_metrics;
CREATE POLICY "Admins write model_metrics"
  ON public.model_metrics FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins read training_jobs" ON public.training_jobs;
CREATE POLICY "Admins read training_jobs"
  ON public.training_jobs FOR SELECT
  USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins write training_jobs" ON public.training_jobs;
CREATE POLICY "Admins write training_jobs"
  ON public.training_jobs FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

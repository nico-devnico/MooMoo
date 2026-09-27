-- MooMoo core schema extensions: is_admin, contributions, signs helpers, RLS
-- Apply with: supabase db push   (or supabase migration up)

-- ---------------------------------------------------------------------------
-- Profiles: admin flag
-- ---------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS is_admin boolean NOT NULL DEFAULT false;

ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS three_d_zoom_enabled boolean NOT NULL DEFAULT true;

ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS selected_character_id text DEFAULT 'alex';


CREATE INDEX IF NOT EXISTS idx_profiles_is_admin ON public.profiles (is_admin)
  WHERE is_admin = true;

-- ---------------------------------------------------------------------------
-- Helper: current user is admin
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT is_admin FROM public.profiles WHERE id = auth.uid()),
    false
  );
$$;

REVOKE ALL ON FUNCTION public.is_current_user_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO authenticated, anon;

-- ---------------------------------------------------------------------------
-- Contributions (community submissions)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.contributions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contributor_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  sign_language_id bigint,
  word text NOT NULL,
  description text,
  video_url text NOT NULL,
  thumbnail_url text,
  landmark_data jsonb,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewer_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  reviewer_note text,
  submitted_at timestamptz DEFAULT now(),
  reviewed_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_contributions_status ON public.contributions (status);
CREATE INDEX IF NOT EXISTS idx_contributions_contributor ON public.contributions (contributor_id);

-- ---------------------------------------------------------------------------
-- Signs dictionary (ensure columns used by the app exist)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.signs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sign_language_id bigint,
  category_id bigint,
  word text NOT NULL,
  description text,
  difficulty_level int NOT NULL DEFAULT 1,
  video_url text,
  thumbnail_url text,
  model_3d_url text,
  landmark_data jsonb,
  tags text[],
  example_sentence text,
  is_validated boolean NOT NULL DEFAULT false,
  contributor_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  view_count int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE IF EXISTS public.signs
  ADD COLUMN IF NOT EXISTS is_validated boolean NOT NULL DEFAULT false;

ALTER TABLE IF EXISTS public.signs
  ADD COLUMN IF NOT EXISTS view_count int NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_signs_validated ON public.signs (is_validated);
CREATE INDEX IF NOT EXISTS idx_signs_word ON public.signs (word);

CREATE OR REPLACE FUNCTION public.increment_sign_view_count(sign_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.signs
  SET view_count = view_count + 1,
      updated_at = now()
  WHERE id = sign_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_sign_view_count(uuid) TO authenticated, anon;

-- ---------------------------------------------------------------------------
-- RLS: profiles
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
CREATE POLICY "Admins can update any profile"
  ON public.profiles FOR UPDATE
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

-- ---------------------------------------------------------------------------
-- RLS: contributions
-- ---------------------------------------------------------------------------
ALTER TABLE public.contributions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users see own contributions" ON public.contributions;
CREATE POLICY "Users see own contributions"
  ON public.contributions FOR SELECT
  USING (auth.uid() = contributor_id OR public.is_current_user_admin());

DROP POLICY IF EXISTS "Users insert own contributions" ON public.contributions;
CREATE POLICY "Users insert own contributions"
  ON public.contributions FOR INSERT
  WITH CHECK (auth.uid() = contributor_id);

DROP POLICY IF EXISTS "Admins update contributions" ON public.contributions;
CREATE POLICY "Admins update contributions"
  ON public.contributions FOR UPDATE
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins delete contributions" ON public.contributions;
CREATE POLICY "Admins delete contributions"
  ON public.contributions FOR DELETE
  USING (public.is_current_user_admin());

-- ---------------------------------------------------------------------------
-- RLS: signs
-- ---------------------------------------------------------------------------
ALTER TABLE public.signs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Validated signs are public" ON public.signs;
CREATE POLICY "Validated signs are public"
  ON public.signs FOR SELECT
  USING (is_validated = true OR public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins manage signs" ON public.signs;
CREATE POLICY "Admins manage signs"
  ON public.signs FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

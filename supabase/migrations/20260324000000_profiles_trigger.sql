-- Ensure profiles table + handle_new_user trigger exist
-- Fixes signup failures when Auth succeeds but profile row / trigger is missing or mismatched.

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email text,
  display_name text,
  avatar_url text,
  bio text,
  preferred_sign_language text NOT NULL DEFAULT 'LSF',
  preferred_output text NOT NULL DEFAULT 'text',
  preferred_view text NOT NULL DEFAULT '3d',
  is_deaf boolean NOT NULL DEFAULT false,
  is_admin boolean NOT NULL DEFAULT false,
  theme text NOT NULL DEFAULT 'system',
  locale text NOT NULL DEFAULT 'fr',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS display_name text;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS bio text;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS preferred_sign_language text DEFAULT 'LSF';
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS preferred_output text DEFAULT 'text';
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS preferred_view text DEFAULT '3d';
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS is_deaf boolean NOT NULL DEFAULT false;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS is_admin boolean NOT NULL DEFAULT false;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS theme text DEFAULT 'system';
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS locale text DEFAULT 'fr';
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        display_name = COALESCE(public.profiles.display_name, EXCLUDED.display_name),
        updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Allow authenticated users to insert their own profile (fallback if trigger missed)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admin update policy is created in 20260324000001 after is_current_user_admin().

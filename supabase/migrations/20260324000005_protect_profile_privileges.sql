-- "Users can update own profile" grants UPDATE on the whole row, so any user
-- could set their own is_admin = true. RLS has no column-level granularity,
-- so a trigger guards the privilege columns instead.
--
-- auth.uid() is NULL for the service role (which bypasses RLS) and for anon
-- (which has no row to update anyway), so server-side administration still works.

CREATE OR REPLACE FUNCTION public.protect_profile_privileges()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.is_admin IS DISTINCT FROM OLD.is_admin
     AND auth.uid() IS NOT NULL
     AND NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Only admins can change is_admin'
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

-- Legacy duplicates of the named policies above; same rules, just noise.
DROP POLICY IF EXISTS read_own_profile ON public.profiles;
DROP POLICY IF EXISTS insert_own_profile ON public.profiles;
DROP POLICY IF EXISTS update_own_profile ON public.profiles;

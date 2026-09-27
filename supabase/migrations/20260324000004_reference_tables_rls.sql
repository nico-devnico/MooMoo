-- Reference tables had RLS enabled with no policy at all, so the dictionary
-- always received an empty list even though rows exist (sign_languages).
-- They hold no user data: everyone reads, only admins write.

ALTER TABLE public.sign_languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sign_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read sign_languages" ON public.sign_languages;
CREATE POLICY "Anyone can read sign_languages"
  ON public.sign_languages FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admins write sign_languages" ON public.sign_languages;
CREATE POLICY "Admins write sign_languages"
  ON public.sign_languages FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS "Anyone can read sign_categories" ON public.sign_categories;
CREATE POLICY "Anyone can read sign_categories"
  ON public.sign_categories FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admins write sign_categories" ON public.sign_categories;
CREATE POLICY "Admins write sign_categories"
  ON public.sign_categories FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

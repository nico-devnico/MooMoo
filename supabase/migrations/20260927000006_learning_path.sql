-- MooMoo — parcours d'apprentissage (unités, leçons, progression, XP, série).
--
-- Une leçon ne stocke pas d'exercices : elle référence des signes du
-- dictionnaire et l'application en dérive les questions (reconnaître un signe,
-- retrouver le signe d'un mot). Un signe corrigé dans le dictionnaire l'est
-- donc aussi dans toutes les leçons qui l'utilisent.
--
-- L'XP et la série ne sont jamais écrites par le client : seule la fonction
-- complete_lesson() les modifie, après avoir validé le score reçu.
--
-- Apply with: cd backend && npm run migrate

-- ---------------------------------------------------------------------------
-- Qui peut éditer le parcours
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_can_edit_learning()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_current_user_admin()
      OR EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid() AND role IN ('teacher', 'sign_expert')
      );
$$;

REVOKE ALL ON FUNCTION public.current_user_can_edit_learning() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_can_edit_learning() TO authenticated, anon;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.learning_units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sign_language_id integer NOT NULL
    REFERENCES public.sign_languages (id) ON DELETE CASCADE,
  title text NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 120),
  description text CHECK (description IS NULL OR length(description) <= 500),
  icon_name text,
  order_index integer NOT NULL DEFAULT 0,
  is_published boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES auth.users (id) ON DELETE SET NULL DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.learning_lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id uuid NOT NULL REFERENCES public.learning_units (id) ON DELETE CASCADE,
  title text NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 120),
  description text CHECK (description IS NULL OR length(description) <= 500),
  order_index integer NOT NULL DEFAULT 0,
  xp_reward integer NOT NULL DEFAULT 10 CHECK (xp_reward BETWEEN 1 AND 100),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.lesson_signs (
  lesson_id uuid NOT NULL REFERENCES public.learning_lessons (id) ON DELETE CASCADE,
  sign_id uuid NOT NULL REFERENCES public.signs (id) ON DELETE CASCADE,
  order_index integer NOT NULL DEFAULT 0,
  PRIMARY KEY (lesson_id, sign_id)
);

CREATE TABLE IF NOT EXISTS public.lesson_completions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  lesson_id uuid NOT NULL REFERENCES public.learning_lessons (id) ON DELETE CASCADE,
  correct_count integer NOT NULL CHECK (correct_count >= 0),
  question_count integer NOT NULL CHECK (question_count > 0),
  xp_earned integer NOT NULL CHECK (xp_earned >= 0),
  completed_at timestamptz NOT NULL DEFAULT now(),
  CHECK (correct_count <= question_count)
);

CREATE TABLE IF NOT EXISTS public.learner_stats (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  total_xp integer NOT NULL DEFAULT 0,
  current_streak integer NOT NULL DEFAULT 0,
  longest_streak integer NOT NULL DEFAULT 0,
  last_active_on date,
  daily_goal_xp integer NOT NULL DEFAULT 20
    CHECK (daily_goal_xp IN (10, 20, 30, 50)),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_learning_units_language
  ON public.learning_units (sign_language_id, order_index);
CREATE INDEX IF NOT EXISTS idx_learning_lessons_unit
  ON public.learning_lessons (unit_id, order_index);
CREATE INDEX IF NOT EXISTS idx_lesson_signs_sign
  ON public.lesson_signs (sign_id);
CREATE INDEX IF NOT EXISTS idx_lesson_completions_user
  ON public.lesson_completions (user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_lesson_completions_user_lesson
  ON public.lesson_completions (user_id, lesson_id);

DROP TRIGGER IF EXISTS update_learning_units_updated_at ON public.learning_units;
CREATE TRIGGER update_learning_units_updated_at
  BEFORE UPDATE ON public.learning_units
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_learning_lessons_updated_at ON public.learning_lessons;
CREATE TRIGGER update_learning_lessons_updated_at
  BEFORE UPDATE ON public.learning_lessons
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.learning_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_signs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learner_stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Published units are readable" ON public.learning_units;
CREATE POLICY "Published units are readable"
  ON public.learning_units FOR SELECT
  USING (is_published OR public.current_user_can_edit_learning());

DROP POLICY IF EXISTS "Editors manage units" ON public.learning_units;
CREATE POLICY "Editors manage units"
  ON public.learning_units FOR ALL
  USING (public.current_user_can_edit_learning())
  WITH CHECK (public.current_user_can_edit_learning());

DROP POLICY IF EXISTS "Lessons of published units are readable" ON public.learning_lessons;
CREATE POLICY "Lessons of published units are readable"
  ON public.learning_lessons FOR SELECT
  USING (
    public.current_user_can_edit_learning()
    OR EXISTS (
      SELECT 1 FROM public.learning_units u
      WHERE u.id = unit_id AND u.is_published
    )
  );

DROP POLICY IF EXISTS "Editors manage lessons" ON public.learning_lessons;
CREATE POLICY "Editors manage lessons"
  ON public.learning_lessons FOR ALL
  USING (public.current_user_can_edit_learning())
  WITH CHECK (public.current_user_can_edit_learning());

DROP POLICY IF EXISTS "Lesson signs of published units are readable" ON public.lesson_signs;
CREATE POLICY "Lesson signs of published units are readable"
  ON public.lesson_signs FOR SELECT
  USING (
    public.current_user_can_edit_learning()
    OR EXISTS (
      SELECT 1
      FROM public.learning_lessons l
      JOIN public.learning_units u ON u.id = l.unit_id
      WHERE l.id = lesson_id AND u.is_published
    )
  );

DROP POLICY IF EXISTS "Editors manage lesson signs" ON public.lesson_signs;
CREATE POLICY "Editors manage lesson signs"
  ON public.lesson_signs FOR ALL
  USING (public.current_user_can_edit_learning())
  WITH CHECK (public.current_user_can_edit_learning());

-- Aucune politique d'écriture sur les deux tables suivantes : les lignes ne
-- sont produites que par complete_lesson() / set_daily_goal().
DROP POLICY IF EXISTS "Users read own completions" ON public.lesson_completions;
CREATE POLICY "Users read own completions"
  ON public.lesson_completions FOR SELECT
  USING (auth.uid() = user_id OR public.is_current_user_admin());

DROP POLICY IF EXISTS "Users read own stats" ON public.learner_stats;
CREATE POLICY "Users read own stats"
  ON public.learner_stats FOR SELECT
  USING (auth.uid() = user_id OR public.is_current_user_admin());

-- ---------------------------------------------------------------------------
-- Résumé de l'apprenant
--
-- p_utc_offset_minutes : décalage du fuseau de l'appareil. Les noms de fuseau
-- renvoyés par les plateformes ne sont pas des identifiants IANA fiables
-- (Windows renvoie « Romance Daylight Time »), le décalage l'est.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.learner_summary(p_utc_offset_minutes integer DEFAULT 0)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
  offset_interval interval := make_interval(mins => COALESCE(p_utc_offset_minutes, 0));
  today date := ((now() AT TIME ZONE 'UTC') + offset_interval)::date;
  s public.learner_stats;
  today_xp integer;
  lessons_done integer;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO s FROM public.learner_stats WHERE user_id = uid;

  SELECT COALESCE(sum(xp_earned), 0)::integer INTO today_xp
  FROM public.lesson_completions
  WHERE user_id = uid
    AND ((completed_at AT TIME ZONE 'UTC') + offset_interval)::date = today;

  SELECT count(DISTINCT lesson_id)::integer INTO lessons_done
  FROM public.lesson_completions
  WHERE user_id = uid;

  RETURN jsonb_build_object(
    'total_xp', COALESCE(s.total_xp, 0),
    -- Une série non prolongée hier est rompue, même si la ligne n'a pas
    -- encore été remise à zéro (elle ne l'est qu'à la prochaine leçon).
    'current_streak', CASE
      WHEN s.last_active_on IS NOT NULL AND s.last_active_on >= today - 1
        THEN s.current_streak
      ELSE 0
    END,
    'longest_streak', COALESCE(s.longest_streak, 0),
    'daily_goal_xp', COALESCE(s.daily_goal_xp, 20),
    'today_xp', today_xp,
    'lessons_completed', lessons_done,
    'active_today', s.last_active_on IS NOT DISTINCT FROM today
  );
END;
$$;

REVOKE ALL ON FUNCTION public.learner_summary(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.learner_summary(integer) TO authenticated;

-- ---------------------------------------------------------------------------
-- Meilleur score par leçon (pour le chemin : terminée, parfaite, à faire)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.learning_progress()
RETURNS TABLE (
  lesson_id uuid,
  best_correct integer,
  question_count integer,
  completions integer,
  last_completed_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT DISTINCT ON (c.lesson_id)
    c.lesson_id,
    c.correct_count,
    c.question_count,
    (count(*) OVER (PARTITION BY c.lesson_id))::integer,
    max(c.completed_at) OVER (PARTITION BY c.lesson_id)
  FROM public.lesson_completions c
  WHERE c.user_id = auth.uid()
  ORDER BY c.lesson_id,
           c.correct_count::numeric / c.question_count DESC,
           c.completed_at DESC;
$$;

REVOKE ALL ON FUNCTION public.learning_progress() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.learning_progress() TO authenticated;

-- ---------------------------------------------------------------------------
-- Fin de leçon : enregistre le résultat, crédite l'XP, met à jour la série.
--
-- XP = récompense de la leçon au prorata des bonnes réponses, +5 si parfait.
-- Refaire une leçon déjà terminée rapporte moitié moins : réviser reste
-- utile, mais on ne cultive pas l'XP en boucle sur la leçon la plus facile.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_lesson(
  p_lesson_id uuid,
  p_correct integer,
  p_total integer,
  p_utc_offset_minutes integer DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
  today date := ((now() AT TIME ZONE 'UTC')
                 + make_interval(mins => COALESCE(p_utc_offset_minutes, 0)))::date;
  reward integer;
  published boolean;
  already_done boolean;
  earned integer;
  s public.learner_stats;
  next_streak integer;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;
  IF NOT public.current_user_is_active() THEN
    RAISE EXCEPTION 'Account suspended' USING ERRCODE = '42501';
  END IF;
  IF p_total IS NULL OR p_total < 1 OR p_total > 100
     OR p_correct IS NULL OR p_correct < 0 OR p_correct > p_total THEN
    RAISE EXCEPTION 'Invalid score' USING ERRCODE = '22023';
  END IF;

  SELECT l.xp_reward, u.is_published INTO reward, published
  FROM public.learning_lessons l
  JOIN public.learning_units u ON u.id = l.unit_id
  WHERE l.id = p_lesson_id;

  IF reward IS NULL THEN
    RAISE EXCEPTION 'Lesson not found' USING ERRCODE = 'P0002';
  END IF;
  IF NOT published AND NOT public.current_user_can_edit_learning() THEN
    RAISE EXCEPTION 'Lesson not published' USING ERRCODE = '42501';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.lesson_completions
    WHERE user_id = uid AND lesson_id = p_lesson_id
  ) INTO already_done;

  earned := round(reward::numeric * p_correct / p_total)::integer
            + CASE WHEN p_correct = p_total THEN 5 ELSE 0 END;
  IF already_done THEN
    earned := ceil(earned / 2.0)::integer;
  END IF;

  INSERT INTO public.lesson_completions (user_id, lesson_id, correct_count, question_count, xp_earned)
  VALUES (uid, p_lesson_id, p_correct, p_total, earned);

  INSERT INTO public.learner_stats (user_id)
  VALUES (uid)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT * INTO s FROM public.learner_stats WHERE user_id = uid FOR UPDATE;

  next_streak := CASE
    WHEN s.last_active_on = today THEN s.current_streak
    WHEN s.last_active_on = today - 1 THEN s.current_streak + 1
    ELSE 1
  END;

  UPDATE public.learner_stats
  SET total_xp = s.total_xp + earned,
      current_streak = next_streak,
      longest_streak = GREATEST(s.longest_streak, next_streak),
      last_active_on = today,
      updated_at = now()
  WHERE user_id = uid;

  RETURN jsonb_build_object(
    'xp_earned', earned,
    'is_first_completion', NOT already_done,
    'summary', public.learner_summary(p_utc_offset_minutes)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.complete_lesson(uuid, integer, integer, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_lesson(uuid, integer, integer, integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.set_daily_goal(p_goal integer)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;
  IF p_goal NOT IN (10, 20, 30, 50) THEN
    RAISE EXCEPTION 'Invalid goal' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.learner_stats (user_id, daily_goal_xp)
  VALUES (auth.uid(), p_goal)
  ON CONFLICT (user_id) DO UPDATE
    SET daily_goal_xp = EXCLUDED.daily_goal_xp,
        updated_at = now();
END;
$$;

REVOKE ALL ON FUNCTION public.set_daily_goal(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_daily_goal(integer) TO authenticated;

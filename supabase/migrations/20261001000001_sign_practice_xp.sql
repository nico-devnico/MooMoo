-- Standalone dictionary practice: award a small XP boost when the learner
-- successfully reproduces a sign (ML check or honest self-check).

CREATE TABLE IF NOT EXISTS public.sign_practice_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  sign_id text NOT NULL,
  success boolean NOT NULL,
  xp_earned integer NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS sign_practice_log_user_day_idx
  ON public.sign_practice_log (user_id, created_at DESC);

ALTER TABLE public.sign_practice_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sign_practice_log_own ON public.sign_practice_log;
CREATE POLICY sign_practice_log_own ON public.sign_practice_log
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Awards XP once per successful practice of a given sign per calendar day
-- (learner timezone). Failures are logged with 0 XP.
CREATE OR REPLACE FUNCTION public.award_sign_practice_xp(
  p_sign_id text,
  p_success boolean,
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
  day_start timestamptz;
  day_end timestamptz;
  already boolean := false;
  earned integer := 0;
  s public.learner_stats;
  next_streak integer;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;
  IF NOT public.current_user_is_active() THEN
    RAISE EXCEPTION 'Account suspended' USING ERRCODE = '42501';
  END IF;
  IF p_sign_id IS NULL OR length(trim(p_sign_id)) = 0 THEN
    RAISE EXCEPTION 'Invalid sign' USING ERRCODE = '22023';
  END IF;

  day_start := ((today::timestamp - make_interval(mins => COALESCE(p_utc_offset_minutes, 0)))
                AT TIME ZONE 'UTC');
  day_end := day_start + interval '1 day';

  IF p_success THEN
    SELECT EXISTS (
      SELECT 1 FROM public.sign_practice_log
      WHERE user_id = uid
        AND sign_id = p_sign_id
        AND success = true
        AND created_at >= day_start
        AND created_at < day_end
    ) INTO already;

    -- First success of the day for this sign: +5 XP. Repeats: +1.
    earned := CASE WHEN already THEN 1 ELSE 5 END;
  END IF;

  INSERT INTO public.sign_practice_log (user_id, sign_id, success, xp_earned)
  VALUES (uid, p_sign_id, COALESCE(p_success, false), earned);

  IF earned > 0 THEN
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
  END IF;

  RETURN jsonb_build_object(
    'xp_earned', earned,
    'already_practiced_today', already,
    'summary', public.learner_summary(p_utc_offset_minutes)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.award_sign_practice_xp(text, boolean, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.award_sign_practice_xp(text, boolean, integer) TO authenticated;

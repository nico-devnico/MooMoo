-- MooMoo — notification de bienvenue créée par la base, pas par l'application.
--
-- L'accueil l'insérait lui-même à chaque ouverture après avoir relu toutes
-- les notifications : une requête de trop à chaque visite, et un doublon
-- possible si deux appareils s'ouvraient en même temps.
--
-- Apply with: cd backend && npm run migrate

CREATE OR REPLACE FUNCTION public.send_welcome_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.notifications
    WHERE user_id = NEW.id AND type = 'welcome'
  ) THEN
    INSERT INTO public.notifications (user_id, type, title, body)
    VALUES (
      NEW.id,
      'welcome',
      CASE WHEN NEW.locale = 'en' THEN 'Welcome to MooMoo' ELSE 'Bienvenue sur MooMoo' END,
      CASE WHEN NEW.locale = 'en'
        THEN 'Start with the Learn tab or translate your first sign.'
        ELSE 'Commencez par l''onglet Apprendre ou traduisez votre premier signe.'
      END
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS send_welcome_notification ON public.profiles;
CREATE TRIGGER send_welcome_notification
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.send_welcome_notification();

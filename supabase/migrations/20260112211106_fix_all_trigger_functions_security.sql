-- ============================================
-- CORRECTION SÉCURITÉ : Fix toutes les fonctions trigger
-- ============================================
-- Correction des fonctions trigger qui ont un search_path mutable

-- Étape 1: Supprimer les triggers existants
DROP TRIGGER IF EXISTS update_workout_exercise_updated_at_trigger ON public.workoutexercise;
DROP TRIGGER IF EXISTS update_workout_session_updated_at_trigger ON public.workoutsession;

-- Étape 2: Recréer les fonctions avec search_path fixe

-- Fonction 1: update_workout_exercise_updated_at
DROP FUNCTION IF EXISTS public.update_workout_exercise_updated_at();

CREATE OR REPLACE FUNCTION public.update_workout_exercise_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Fonction 2: update_workout_session_updated_at
DROP FUNCTION IF EXISTS public.update_workout_session_updated_at();

CREATE OR REPLACE FUNCTION public.update_workout_session_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Étape 3: Recréer les triggers
CREATE TRIGGER update_workout_exercise_updated_at_trigger
  BEFORE UPDATE ON public.workoutexercise
  FOR EACH ROW
  EXECUTE FUNCTION public.update_workout_exercise_updated_at();

CREATE TRIGGER update_workout_session_updated_at_trigger
  BEFORE UPDATE ON public.workoutsession
  FOR EACH ROW
  EXECUTE FUNCTION public.update_workout_session_updated_at();

-- Re-créer get_session_stats avec la bonne syntaxe (peut-être que la précédente n'a pas fonctionné)
DROP FUNCTION IF EXISTS public.get_session_stats(uuid);

CREATE OR REPLACE FUNCTION public.get_session_stats(user_uuid uuid)
RETURNS TABLE(total_sessions bigint, weekly_average numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  days_since_first_session integer;
  total_count bigint;
  avg_weekly numeric;
BEGIN
  -- Compter le nombre total de séances
  SELECT COUNT(*) INTO total_count
  FROM public.performedsession ps
  WHERE ps.user_id = user_uuid;

  -- Calculer la moyenne hebdomadaire
  IF total_count > 0 THEN
    SELECT EXTRACT(EPOCH FROM (NOW() - MIN(ps.started_at))) / 86400 INTO days_since_first_session
    FROM public.performedsession ps
    WHERE ps.user_id = user_uuid
      AND ps.started_at IS NOT NULL;

    IF days_since_first_session > 0 AND days_since_first_session > 0 THEN
      avg_weekly := (total_count::numeric / (days_since_first_session::numeric / 7));
    ELSE
      avg_weekly := 0;
    END IF;
  ELSE
    avg_weekly := 0;
  END IF;

  RETURN QUERY SELECT total_count, avg_weekly;
END;
$$;

-- Commentaires de sécurité
COMMENT ON FUNCTION public.update_workout_exercise_updated_at() IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';
COMMENT ON FUNCTION public.update_workout_session_updated_at() IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';
COMMENT ON FUNCTION public.get_session_stats(uuid) IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';

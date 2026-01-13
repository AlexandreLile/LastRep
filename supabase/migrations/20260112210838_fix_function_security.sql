-- ============================================
-- CORRECTION SÉCURITÉ : Fix search_path mutable
-- ============================================
-- Supabase exige que les fonctions aient un search_path fixe pour éviter
-- les risques d'injection SQL. Cette migration corrige les fonctions existantes.

-- Fonction 1: get_total_training_time
-- Supprimer l'ancienne version si elle existe
DROP FUNCTION IF EXISTS public.get_total_training_time(uuid);

-- Recréer avec search_path fixe
CREATE OR REPLACE FUNCTION public.get_total_training_time(user_uuid uuid)
RETURNS TABLE(total_minutes integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (ps.ended_at - ps.started_at)) / 60)::integer, 0) as total_minutes
  FROM public.performedsession ps
  WHERE ps.user_id = user_uuid
    AND ps.started_at IS NOT NULL
    AND ps.ended_at IS NOT NULL
    AND ps.ended_at > ps.started_at;
END;
$$;

-- Fonction 2: get_total_weight
-- Supprimer l'ancienne version si elle existe
DROP FUNCTION IF EXISTS public.get_total_weight(uuid);

-- Recréer avec search_path fixe
CREATE OR REPLACE FUNCTION public.get_total_weight(user_uuid uuid)
RETURNS TABLE(total_weight numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT COALESCE(SUM(es.weight_kg * es.reps), 0)::numeric as total_weight
  FROM public.exerciseset es
  WHERE es.user_id = user_uuid
    AND es.weight_kg IS NOT NULL
    AND es.reps IS NOT NULL;
END;
$$;

-- Fonction 3: get_session_stats
-- Supprimer l'ancienne version si elle existe
DROP FUNCTION IF EXISTS public.get_session_stats(uuid);

-- Recréer avec search_path fixe
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

    IF days_since_first_session > 0 THEN
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
COMMENT ON FUNCTION public.get_total_training_time(uuid) IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';
COMMENT ON FUNCTION public.get_total_weight(uuid) IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';
COMMENT ON FUNCTION public.get_session_stats(uuid) IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';

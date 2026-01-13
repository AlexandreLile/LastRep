-- ============================================
-- CORRECTION SÉCURITÉ : Fix get_session_stats search_path
-- ============================================
-- Ajout de la fonction get_session_stats avec search_path fixe

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

-- Commentaire de sécurité
COMMENT ON FUNCTION public.get_session_stats(uuid) IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';

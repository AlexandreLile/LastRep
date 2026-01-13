-- ============================================
-- OPTIMISATION PERFORMANCE : Fonction pour obtenir les comptes d'exercices par session
-- ============================================
-- Cette fonction évite le problème N+1 en récupérant tous les comptes en une seule requête

CREATE OR REPLACE FUNCTION public.get_session_exercise_counts(user_uuid uuid)
RETURNS TABLE(session_id uuid, exercise_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    es.performed_session_id as session_id,
    COUNT(DISTINCT es.exercise_id) as exercise_count
  FROM public.exerciseset es
  WHERE es.user_id = user_uuid
    AND es.performed_session_id IS NOT NULL
  GROUP BY es.performed_session_id;
END;
$$;

-- Commentaire
COMMENT ON FUNCTION public.get_session_exercise_counts(uuid) IS 
'Optimisation performance : Retourne le nombre d''exercices distincts par session en une seule requête';

-- Grant pour permettre aux utilisateurs d'appeler cette fonction
GRANT EXECUTE ON FUNCTION public.get_session_exercise_counts(uuid) TO authenticated;

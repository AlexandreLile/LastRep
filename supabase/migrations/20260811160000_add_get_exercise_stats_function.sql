-- ============================================
-- OPTIMISATION PERFORMANCE : Fonction pour obtenir le nombre de séries par exercice
-- ============================================
-- Évite de rapatrier toutes les lignes exerciseset de l'utilisateur côté client
-- pour les regrouper en JS (O(n²)). Le GROUP BY est fait côté SQL.

CREATE OR REPLACE FUNCTION public.get_exercise_stats(user_uuid uuid)
RETURNS TABLE(exercise_id uuid, total_sets bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    es.exercise_id,
    COUNT(*) as total_sets
  FROM public.exerciseset es
  WHERE es.user_id = user_uuid
  GROUP BY es.exercise_id;
END;
$$;

COMMENT ON FUNCTION public.get_exercise_stats(uuid) IS
'Optimisation performance : Retourne le nombre de séries par exercice pour un utilisateur en une seule requête agrégée côté SQL';

GRANT EXECUTE ON FUNCTION public.get_exercise_stats(uuid) TO authenticated;

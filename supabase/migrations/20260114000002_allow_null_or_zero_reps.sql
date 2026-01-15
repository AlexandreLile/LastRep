-- ============================================
-- PERMETTRE NULL OU 0 POUR reps DANS LA VALIDATION
-- ============================================
-- Cette migration modifie la fonction de validation pour permettre NULL ou 0 pour reps
-- quand l'utilisateur choisit "Enregistrer quand même" sans remplir les répétitions

-- Modifier la fonction de validation pour être plus flexible avec reps
CREATE OR REPLACE FUNCTION validate_exercise_set()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  exercise_type VARCHAR(20);
BEGIN
  -- Récupérer le type de mesure de l'exercice
  SELECT measurement_type INTO exercise_type
  FROM exercise
  WHERE id = NEW.exercise_id;

  -- Si l'exercice n'existe pas, on ne valide pas (erreur de FK)
  IF exercise_type IS NULL THEN
    RETURN NEW;
  END IF;

  -- Valider selon le type (avec flexibilité)
  CASE exercise_type
    WHEN 'weight_reps' THEN
      -- Poids + Répétitions : reps obligatoire mais peut être 0 si l'utilisateur choisit "Enregistrer quand même"
      IF NEW.reps IS NULL THEN
        RAISE EXCEPTION 'weight_reps requires reps';
      END IF;
      -- weight_kg peut être NULL ou 0 si on fait juste des répétitions (rare mais possible)
    
    WHEN 'time' THEN
      IF NEW.duration_seconds IS NULL THEN
        RAISE EXCEPTION 'time requires duration_seconds';
      END IF;
      -- reps peut être optionnel (pour séries de temps)
    
    WHEN 'reps' THEN
      -- Répétitions : reps obligatoire mais peut être 0 si l'utilisateur choisit "Enregistrer quand même"
      IF NEW.reps IS NULL THEN
        RAISE EXCEPTION 'reps type requires reps';
      END IF;
      -- weight_kg est optionnel : permet pompes normales ET pompes lestées
    
    WHEN 'distance' THEN
      IF NEW.distance_meters IS NULL THEN
        RAISE EXCEPTION 'distance requires distance_meters';
      END IF;
    
    WHEN 'weight_only' THEN
      IF NEW.weight_kg IS NULL THEN
        RAISE EXCEPTION 'weight_only requires weight_kg';
      END IF;
    
    WHEN 'time_distance' THEN
      IF NEW.duration_seconds IS NULL OR NEW.distance_meters IS NULL THEN
        RAISE EXCEPTION 'time_distance requires both duration_seconds and distance_meters';
      END IF;
    
    WHEN 'time_reps' THEN
      -- Temps + Répétitions : reps obligatoire mais peut être 0 si l'utilisateur choisit "Enregistrer quand même"
      IF NEW.duration_seconds IS NULL THEN
        RAISE EXCEPTION 'time_reps requires duration_seconds';
      END IF;
      IF NEW.reps IS NULL THEN
        RAISE EXCEPTION 'time_reps requires reps';
      END IF;
  END CASE;

  RETURN NEW;
END;
$$;

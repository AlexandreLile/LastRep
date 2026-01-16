-- ============================================
-- AJOUT D'EXERCICES FESSIERS AVEC MUSCLES MULTIPLES
-- ============================================
-- Cette migration ajoute une série d'exercices fessiers avec leurs muscles principaux et secondaires
-- Elle vérifie les doublons avant insertion

-- ============================================
-- 1. AJOUTER LES NOUVEAUX MUSCLES MANQUANTS
-- ============================================

INSERT INTO muscle (name) VALUES
  ('Ischio-jambiers'),
  ('Quadriceps'),
  ('Adducteurs'),
  ('Lombaires'),
  ('Trapèzes'),
  ('Fessiers moyens'),
  ('Petit fessier')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 2. FONCTION HELPER POUR AJOUTER UN EXERCICE (avec vérification de doublon)
-- ============================================

CREATE OR REPLACE FUNCTION add_exercise_if_not_exists(
  p_name VARCHAR(255),
  p_primary_muscle VARCHAR(50),
  p_muscles VARCHAR(50)[] DEFAULT NULL,
  p_measurement_type VARCHAR(20) DEFAULT 'weight_reps',
  p_is_custom BOOLEAN DEFAULT false,
  p_user_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  exercise_uuid UUID;
  muscle_name VARCHAR(50);
  muscle_id_val INTEGER;
  is_first BOOLEAN;
BEGIN
  -- Vérifier si l'exercice existe déjà
  SELECT id INTO exercise_uuid
  FROM exercise
  WHERE LOWER(TRIM(name)) = LOWER(TRIM(p_name))
  LIMIT 1;

  -- Si l'exercice existe déjà, retourner son ID
  IF exercise_uuid IS NOT NULL THEN
    RETURN exercise_uuid;
  END IF;

  -- Créer l'exercice
  INSERT INTO exercise (
    name,
    primary_muscle,
    measurement_type,
    is_custom,
    user_id
  ) VALUES (
    TRIM(p_name),
    p_primary_muscle,
    p_measurement_type,
    p_is_custom,
    p_user_id
  )
  RETURNING id INTO exercise_uuid;

  -- Si des muscles supplémentaires sont fournis, les utiliser
  -- Sinon, utiliser seulement le muscle principal
  IF p_muscles IS NOT NULL AND array_length(p_muscles, 1) > 0 THEN
    is_first := true;
    
    -- Ajouter chaque muscle
    FOREACH muscle_name IN ARRAY p_muscles
    LOOP
      -- Récupérer l'ID du muscle
      SELECT id INTO muscle_id_val
      FROM muscle
      WHERE name = muscle_name;
      
      -- Si le muscle existe, créer l'association
      IF muscle_id_val IS NOT NULL THEN
        INSERT INTO exercise_muscle (exercise_id, muscle_id, is_primary)
        VALUES (exercise_uuid, muscle_id_val, is_first)
        ON CONFLICT (exercise_id, muscle_id) DO NOTHING;
        
        is_first := false; -- Seul le premier est principal
      END IF;
    END LOOP;
  ELSE
    -- Si aucun muscle supplémentaire, ajouter seulement le muscle principal
    SELECT id INTO muscle_id_val
    FROM muscle
    WHERE name = p_primary_muscle;
    
    IF muscle_id_val IS NOT NULL THEN
      INSERT INTO exercise_muscle (exercise_id, muscle_id, is_primary)
      VALUES (exercise_uuid, muscle_id_val, true)
      ON CONFLICT (exercise_id, muscle_id) DO NOTHING;
    END IF;
  END IF;

  RETURN exercise_uuid;
END;
$$;

-- ============================================
-- 3. AJOUTER TOUS LES EXERCICES FESSIERS
-- ============================================

-- 🏋️ Exercices fessiers – barre
SELECT add_exercise_if_not_exists('Hip Thrust barre', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Squat back squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Squat front squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Adducteurs', 'Abdominaux', 'Dorsaux']);
SELECT add_exercise_if_not_exists('Squat sumo barre', 'Fessiers', ARRAY['Fessiers', 'Adducteurs', 'Quadriceps', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift conventionnel', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Quadriceps', 'Trapèzes', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift sumo', 'Fessiers', ARRAY['Fessiers', 'Adducteurs', 'Ischio-jambiers', 'Quadriceps', 'Lombaires']);
SELECT add_exercise_if_not_exists('Romanian Deadlift (RDL)', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Good Morning', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Split squat barre', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);

-- 🏋️‍♀️ Exercices fessiers – haltères / kettlebells
SELECT add_exercise_if_not_exists('Hip Thrust haltères', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Goblet squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Bulgarian Split Squat haltères', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Romanian Deadlift haltères', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift kettlebell', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Quadriceps', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Step-up haltères', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Mollets', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Fentes marchées haltères', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Fentes arrière haltères', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);

-- 🧱 Exercices fessiers – machines
SELECT add_exercise_if_not_exists('Hip Thrust machine', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps']);
SELECT add_exercise_if_not_exists('Glute Kickback machine', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Abduction machine (assis)', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier']);
SELECT add_exercise_if_not_exists('Abduction machine debout', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Leg Press (pieds hauts / larges)', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps', 'Adducteurs']);
SELECT add_exercise_if_not_exists('Smith Machine Squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Smith Machine Hip Thrust', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps']);

-- 🧲 Exercices fessiers – câbles / élastiques
SELECT add_exercise_if_not_exists('Kickback câble', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Pull-through câble', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Abduction câble', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Hip Thrust élastique', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps']);
SELECT add_exercise_if_not_exists('Glute Bridge élastique', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Monster Walk (élastique)', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier', 'Quadriceps']);
SELECT add_exercise_if_not_exists('Lateral Walk (élastique)', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier', 'Abdominaux']);

-- ============================================
-- 4. NETTOYER LA FONCTION TEMPORAIRE (optionnel)
-- ============================================
-- On garde la fonction pour usage futur, mais on pourrait la supprimer si besoin
-- DROP FUNCTION IF EXISTS add_exercise_if_not_exists;

-- ============================================
-- NOTES
-- ============================================
-- Cette migration :
-- 1. Ajoute les nouveaux muscles manquants
-- 2. Crée une fonction helper pour éviter les doublons
-- 3. Insère tous les exercices fessiers avec leurs muscles associés
-- 4. Vérifie les doublons par nom (insensible à la casse et aux espaces)
-- 5. Associe automatiquement les muscles principaux et secondaires

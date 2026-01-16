-- ============================================
-- TABLE DE CATÉGORIES D'EXERCICES
-- ============================================
-- Cette migration ajoute une table de catégories pour organiser les exercices
-- (Poids libre, Poids du corps, Machine, Isométrie, Cardio, etc.)

-- ============================================
-- 1. CRÉER LA TABLE exercise_category
-- ============================================

CREATE TABLE IF NOT EXISTS exercise_category (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 2. INSÉRER LES CATÉGORIES DE BASE
-- ============================================

INSERT INTO exercise_category (name, description, icon) VALUES
  ('Poids libre', 'Exercices avec barre, haltères, poids libres', 'dumbbell'),
  ('Poids du corps', 'Exercices au poids du corps (pompes, tractions, etc.)', 'user'),
  ('Machine', 'Exercices sur machines guidées', 'settings'),
  ('Isométrie', 'Exercices isométriques (gainage, planche, etc.)', 'clock'),
  ('Cardio', 'Exercices cardiovasculaires', 'activity'),
  ('Élastique', 'Exercices avec élastiques', 'zap'),
  ('Autre', 'Autres types d''exercices', 'more-horizontal')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 3. AJOUTER LA COLONNE category_id DANS exercise
-- ============================================

ALTER TABLE exercise 
ADD COLUMN IF NOT EXISTS category_id INTEGER REFERENCES exercise_category(id);

-- ============================================
-- 4. METTRE À JOUR TOUS LES EXERCICES EXISTANTS
-- ============================================
-- Tous les exercices existants sont avec poids, donc catégorie "Poids libre"

UPDATE exercise 
SET category_id = (SELECT id FROM exercise_category WHERE name = 'Poids libre')
WHERE category_id IS NULL;

-- ============================================
-- 5. CRÉER LES INDEX POUR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_exercise_category_id ON exercise(category_id);

-- ============================================
-- 6. CONTRAINTE : category_id ne peut pas être NULL pour les nouveaux exercices
-- ============================================
-- Note: On garde NULL autorisé pour compatibilité, mais on peut ajouter une contrainte plus tard si besoin

-- ============================================
-- 7. METTRE À JOUR LA FONCTION add_exercise_if_not_exists
-- ============================================
-- Ajouter le paramètre category_id avec valeur par défaut "Poids libre"

CREATE OR REPLACE FUNCTION add_exercise_if_not_exists(
  p_name VARCHAR(255),
  p_primary_muscle VARCHAR(50),
  p_muscles VARCHAR(50)[] DEFAULT NULL,
  p_measurement_type VARCHAR(20) DEFAULT 'weight_reps',
  p_is_custom BOOLEAN DEFAULT false,
  p_user_id UUID DEFAULT NULL,
  p_category_name VARCHAR(50) DEFAULT 'Poids libre'
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
  category_id_val INTEGER;
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

  -- Récupérer l'ID de la catégorie
  SELECT id INTO category_id_val
  FROM exercise_category
  WHERE name = p_category_name;

  -- Si la catégorie n'existe pas, utiliser "Poids libre" par défaut
  IF category_id_val IS NULL THEN
    SELECT id INTO category_id_val
    FROM exercise_category
    WHERE name = 'Poids libre';
  END IF;

  -- Créer l'exercice
  INSERT INTO exercise (
    name,
    primary_muscle,
    measurement_type,
    is_custom,
    user_id,
    category_id
  ) VALUES (
    TRIM(p_name),
    p_primary_muscle,
    p_measurement_type,
    p_is_custom,
    p_user_id,
    category_id_val
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
-- 8. MESSAGE DE CONFIRMATION
-- ============================================

DO $$
DECLARE
  total_exercises INTEGER;
  categorized_exercises INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_exercises FROM exercise;
  SELECT COUNT(*) INTO categorized_exercises FROM exercise WHERE category_id IS NOT NULL;
  
  RAISE NOTICE '✅ Migration terminée :';
  RAISE NOTICE '   - % exercices au total', total_exercises;
  RAISE NOTICE '   - % exercices catégorisés (Poids libre)', categorized_exercises;
  RAISE NOTICE '   - % catégories disponibles', (SELECT COUNT(*) FROM exercise_category);
END $$;

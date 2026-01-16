-- ============================================
-- TABLE DE LIAISON POUR PLUSIEURS MUSCLES PAR EXERCICE
-- ============================================
-- Cette migration permet aux exercices d'avoir plusieurs muscles associés
-- tout en gardant primary_muscle pour la compatibilité/rétrocompatibilité

-- ============================================
-- 1. CRÉER LA TABLE muscle (normalisation)
-- ============================================

CREATE TABLE IF NOT EXISTS muscle (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insérer les muscles existants
INSERT INTO muscle (name) VALUES
  ('Pectoraux'),
  ('Dorsaux'),
  ('Épaules'),
  ('Biceps'),
  ('Triceps'),
  ('Jambes'),
  ('Fessiers'),
  ('Mollets'),
  ('Abdominaux'),
  ('Cardio'),
  ('Autre')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 2. CRÉER LA TABLE exercise_muscle (many-to-many)
-- ============================================

CREATE TABLE IF NOT EXISTS exercise_muscle (
  id SERIAL PRIMARY KEY,
  exercise_id UUID NOT NULL REFERENCES exercise(id) ON DELETE CASCADE,
  muscle_id INTEGER NOT NULL REFERENCES muscle(id) ON DELETE CASCADE,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(exercise_id, muscle_id)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_exercise_muscle_exercise_id ON exercise_muscle(exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_muscle_muscle_id ON exercise_muscle(muscle_id);
CREATE INDEX IF NOT EXISTS idx_exercise_muscle_is_primary ON exercise_muscle(is_primary);

-- ============================================
-- 3. MIGRER LES DONNÉES EXISTANTES
-- ============================================

-- Migrer primary_muscle vers exercise_muscle
INSERT INTO exercise_muscle (exercise_id, muscle_id, is_primary)
SELECT 
  e.id,
  m.id,
  true -- Marquer comme muscle principal
FROM exercise e
JOIN muscle m ON m.name = e.primary_muscle
WHERE e.primary_muscle IS NOT NULL
ON CONFLICT (exercise_id, muscle_id) DO NOTHING;

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Activer RLS sur les tables
ALTER TABLE muscle ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_muscle ENABLE ROW LEVEL SECURITY;

-- Policy pour muscle : lecture publique
CREATE POLICY "muscle_select_policy" ON muscle
  FOR SELECT
  USING (true);

-- Policy pour exercise_muscle : lecture publique
CREATE POLICY "exercise_muscle_select_policy" ON exercise_muscle
  FOR SELECT
  USING (true);

-- Policy pour exercise_muscle : insertion pour les utilisateurs authentifiés
CREATE POLICY "exercise_muscle_insert_policy" ON exercise_muscle
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM exercise e
      WHERE e.id = exercise_muscle.exercise_id
      AND (
        e.is_custom = false -- Exercices globaux
        OR (
          e.is_custom = true 
          AND e.user_id = auth.uid() -- Exercices personnalisés de l'utilisateur
        )
      )
    )
  );

-- Policy pour exercise_muscle : mise à jour pour les utilisateurs authentifiés
CREATE POLICY "exercise_muscle_update_policy" ON exercise_muscle
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM exercise e
      WHERE e.id = exercise_muscle.exercise_id
      AND (
        e.is_custom = false -- Exercices globaux
        OR (
          e.is_custom = true 
          AND e.user_id = auth.uid() -- Exercices personnalisés de l'utilisateur
        )
      )
    )
  );

-- Policy pour exercise_muscle : suppression pour les utilisateurs authentifiés
CREATE POLICY "exercise_muscle_delete_policy" ON exercise_muscle
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM exercise e
      WHERE e.id = exercise_muscle.exercise_id
      AND (
        e.is_custom = false -- Exercices globaux
        OR (
          e.is_custom = true 
          AND e.user_id = auth.uid() -- Exercices personnalisés de l'utilisateur
        )
      )
    )
  );

-- ============================================
-- 5. FONCTION UTILE : Récupérer les muscles d'un exercice
-- ============================================

CREATE OR REPLACE FUNCTION get_exercise_muscles(exercise_uuid UUID)
RETURNS TABLE (
  muscle_id INTEGER,
  muscle_name VARCHAR(50),
  is_primary BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.name,
    em.is_primary
  FROM exercise_muscle em
  JOIN muscle m ON m.id = em.muscle_id
  WHERE em.exercise_id = exercise_uuid
  ORDER BY em.is_primary DESC, m.name ASC;
END;
$$;

-- Commentaire de sécurité
COMMENT ON FUNCTION get_exercise_muscles(UUID) IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';

-- ============================================
-- 6. FONCTION HELPER : Créer un exercice avec plusieurs muscles
-- ============================================

CREATE OR REPLACE FUNCTION create_exercise_with_muscles(
  p_name VARCHAR(255),
  p_primary_muscle VARCHAR(50),
  p_muscles VARCHAR(50)[] DEFAULT NULL, -- Tableau de noms de muscles
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
  -- Créer l'exercice
  INSERT INTO exercise (
    name,
    primary_muscle,
    measurement_type,
    is_custom,
    user_id
  ) VALUES (
    p_name,
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

-- Commentaire de sécurité
COMMENT ON FUNCTION create_exercise_with_muscles IS 
'Helper pour créer un exercice avec plusieurs muscles. Sécurisé : search_path fixe.';

-- ============================================
-- NOTES
-- ============================================
-- Cette migration permet :
-- 1. D'associer plusieurs muscles à un exercice
-- 2. De marquer un muscle comme "principal" (is_primary)
-- 3. De garder primary_muscle pour la compatibilité/rétrocompatibilité
-- 4. De normaliser les noms de muscles dans une table dédiée
-- 5. De sécuriser l'accès avec RLS

-- ============================================
-- EXERCICES PERSONNALISÉS AVEC TYPES DE MESURE
-- ============================================
-- Cette migration permet aux utilisateurs de créer leurs propres exercices
-- avec différents types de mesure (poids, temps, distance, etc.)

-- ============================================
-- 1. MODIFIER LA TABLE exercise
-- ============================================

-- Ajouter les colonnes nécessaires
ALTER TABLE exercise 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS measurement_type VARCHAR(20) NOT NULL DEFAULT 'weight_reps' 
  CHECK (measurement_type IN (
    'weight_reps',      -- Poids + Répétitions (défaut)
    'time',             -- Temps uniquement
    'reps',             -- Répétitions (poids optionnel pour lestage)
    'distance',         -- Distance uniquement
    'weight_only',      -- Poids uniquement
    'time_distance',    -- Temps + Distance
    'time_reps'         -- Temps + Répétitions (ex: gainage 3x 30s)
  )),
ADD COLUMN IF NOT EXISTS is_custom BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Mettre à jour les exercices existants (ils sont globaux)
UPDATE exercise 
SET is_custom = false, 
    user_id = NULL,
    measurement_type = 'weight_reps'
WHERE user_id IS NULL AND is_custom IS NULL;

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_exercise_user_id ON exercise(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_measurement_type ON exercise(measurement_type);
CREATE INDEX IF NOT EXISTS idx_exercise_is_custom ON exercise(is_custom);
CREATE INDEX IF NOT EXISTS idx_exercise_user_id_is_custom ON exercise(user_id, is_custom);

-- ============================================
-- 2. MODIFIER LA TABLE exerciseset
-- ============================================

-- Ajouter les colonnes pour les nouveaux types de mesure
ALTER TABLE exerciseset
ADD COLUMN IF NOT EXISTS duration_seconds INTEGER, -- Pour les exercices en temps
ADD COLUMN IF NOT EXISTS distance_meters NUMERIC;  -- Pour les exercices en distance

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_exerciseset_duration ON exerciseset(duration_seconds);
CREATE INDEX IF NOT EXISTS idx_exerciseset_distance ON exerciseset(distance_meters);

-- ============================================
-- 3. FONCTION DE VALIDATION
-- ============================================

-- Fonction pour valider que les bonnes colonnes sont remplies selon le type
-- APPROCHE FLEXIBLE : Certains champs sont optionnels pour permettre la flexibilité
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
      -- Poids + Répétitions : reps obligatoire, poids généralement requis
      IF NEW.reps IS NULL THEN
        RAISE EXCEPTION 'weight_reps requires reps';
      END IF;
      -- weight_kg peut être NULL si on fait juste des répétitions (rare mais possible)
    
    WHEN 'time' THEN
      IF NEW.duration_seconds IS NULL THEN
        RAISE EXCEPTION 'time requires duration_seconds';
      END IF;
      -- reps peut être optionnel (pour séries de temps)
    
    WHEN 'reps' THEN
      -- Répétitions : reps obligatoire, poids optionnel (pour lestage)
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
      IF NEW.duration_seconds IS NULL OR NEW.reps IS NULL THEN
        RAISE EXCEPTION 'time_reps requires both duration_seconds and reps';
      END IF;
  END CASE;

  RETURN NEW;
END;
$$;

-- Trigger pour valider automatiquement
DROP TRIGGER IF EXISTS validate_exercise_set_trigger ON exerciseset;
CREATE TRIGGER validate_exercise_set_trigger
  BEFORE INSERT OR UPDATE ON exerciseset
  FOR EACH ROW
  EXECUTE FUNCTION validate_exercise_set();

-- Commentaire de sécurité
COMMENT ON FUNCTION validate_exercise_set() IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Activer RLS sur exercise (si ce n'est pas déjà fait)
ALTER TABLE exercise ENABLE ROW LEVEL SECURITY;

-- Supprimer les policies existantes pour exercise (si elles existent)
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'exercise') LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.exercise', r.policyname);
  END LOOP;
END
$$;

-- Policy : Les utilisateurs peuvent voir les exercices globaux + leurs exercices personnalisés
CREATE POLICY "Users can view global and their own custom exercises"
  ON exercise FOR SELECT
  USING (
    is_custom = false 
    OR (is_custom = true AND user_id = (SELECT auth.uid()))
  );

-- Policy : Les utilisateurs peuvent créer leurs propres exercices
CREATE POLICY "Users can create their own custom exercises"
  ON exercise FOR INSERT
  WITH CHECK (
    is_custom = true 
    AND user_id = (SELECT auth.uid())
  );

-- Policy : Les utilisateurs peuvent modifier leurs propres exercices
CREATE POLICY "Users can update their own custom exercises"
  ON exercise FOR UPDATE
  USING (
    is_custom = true 
    AND user_id = (SELECT auth.uid())
  )
  WITH CHECK (
    is_custom = true 
    AND user_id = (SELECT auth.uid())
  );

-- Policy : Les utilisateurs peuvent supprimer leurs propres exercices
CREATE POLICY "Users can delete their own custom exercises"
  ON exercise FOR DELETE
  USING (
    is_custom = true 
    AND user_id = (SELECT auth.uid())
  );

-- Note : Personne ne peut modifier les exercices globaux (is_custom = false)
-- car il n'y a pas de policy UPDATE/DELETE pour is_custom = false

-- ============================================
-- 5. TRIGGER POUR updated_at
-- ============================================

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_exercise_updated_at()
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

-- Trigger pour mettre à jour updated_at
DROP TRIGGER IF EXISTS update_exercise_updated_at_trigger ON exercise;
CREATE TRIGGER update_exercise_updated_at_trigger
  BEFORE UPDATE ON exercise
  FOR EACH ROW
  EXECUTE FUNCTION update_exercise_updated_at();

-- Commentaire de sécurité
COMMENT ON FUNCTION update_exercise_updated_at() IS 
'Sécurisé : search_path fixe pour éviter les injections SQL';

-- ============================================
-- NOTES
-- ============================================
-- Cette migration permet :
-- 1. Aux utilisateurs de créer leurs propres exercices
-- 2. De choisir le type de mesure (poids, temps, distance, etc.)
-- 3. De gérer le lestage pour les exercices en répétitions (pompes, tractions)
-- 4. De valider automatiquement que les bons champs sont remplis
-- 5. De sécuriser l'accès avec RLS
--
-- Types de mesure supportés :
-- - weight_reps : Poids + Répétitions (défaut)
-- - reps : Répétitions (poids optionnel pour lestage)
-- - time : Temps uniquement
-- - time_reps : Temps + Répétitions
-- - time_distance : Temps + Distance
-- - distance : Distance uniquement
-- - weight_only : Poids uniquement

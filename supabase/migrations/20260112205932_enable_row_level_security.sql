-- ============================================
-- ROW LEVEL SECURITY (RLS) - SÉCURITÉ CRITIQUE
-- ============================================
-- Cette migration active RLS sur toutes les tables pour garantir
-- que chaque utilisateur ne peut accéder qu'à ses propres données

-- ============================================
-- 1. TABLE: workoutsession
-- ============================================
ALTER TABLE workoutsession ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir uniquement leurs propres séances
CREATE POLICY "Users can view their own workout sessions"
  ON workoutsession
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent créer leurs propres séances
CREATE POLICY "Users can insert their own workout sessions"
  ON workoutsession
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent modifier leurs propres séances
CREATE POLICY "Users can update their own workout sessions"
  ON workoutsession
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent supprimer leurs propres séances
CREATE POLICY "Users can delete their own workout sessions"
  ON workoutsession
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 2. TABLE: workoutexercise
-- ============================================
ALTER TABLE workoutexercise ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir les exercices de leurs propres séances
CREATE POLICY "Users can view exercises from their own workout sessions"
  ON workoutexercise
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = auth.uid()
    )
  );

-- Policy: Les utilisateurs peuvent ajouter des exercices à leurs propres séances
CREATE POLICY "Users can insert exercises to their own workout sessions"
  ON workoutexercise
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = auth.uid()
    )
  );

-- Policy: Les utilisateurs peuvent modifier les exercices de leurs propres séances
CREATE POLICY "Users can update exercises from their own workout sessions"
  ON workoutexercise
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = auth.uid()
    )
  );

-- Policy: Les utilisateurs peuvent supprimer les exercices de leurs propres séances
CREATE POLICY "Users can delete exercises from their own workout sessions"
  ON workoutexercise
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = auth.uid()
    )
  );

-- ============================================
-- 3. TABLE: exerciseset
-- ============================================
ALTER TABLE exerciseset ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir uniquement leurs propres séries
CREATE POLICY "Users can view their own exercise sets"
  ON exerciseset
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent créer leurs propres séries
CREATE POLICY "Users can insert their own exercise sets"
  ON exerciseset
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent modifier leurs propres séries
CREATE POLICY "Users can update their own exercise sets"
  ON exerciseset
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent supprimer leurs propres séries
CREATE POLICY "Users can delete their own exercise sets"
  ON exerciseset
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 4. TABLE: performedsession
-- ============================================
ALTER TABLE performedsession ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir uniquement leurs propres séances effectuées
CREATE POLICY "Users can view their own performed sessions"
  ON performedsession
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent créer leurs propres séances effectuées
CREATE POLICY "Users can insert their own performed sessions"
  ON performedsession
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent modifier leurs propres séances effectuées
CREATE POLICY "Users can update their own performed sessions"
  ON performedsession
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent supprimer leurs propres séances effectuées
CREATE POLICY "Users can delete their own performed sessions"
  ON performedsession
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- NOTE: La table 'exercise' est publique
-- ============================================
-- La table 'exercise' contient les exercices de référence (Squat, Développé couché, etc.)
-- Elle n'a pas de user_id et doit rester accessible à tous les utilisateurs
-- Pas besoin de RLS pour cette table

-- ============================================
-- OPTIMISATION PERFORMANCE : RLS Policies
-- ============================================
-- Remplacement de auth.uid() par (SELECT auth.uid()) pour améliorer
-- les performances. Cela permet à PostgreSQL d'évaluer auth.uid() une seule
-- fois par requête au lieu de le faire pour chaque ligne.

-- ============================================
-- 1. TABLE: workoutsession
-- ============================================

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Users can view their own workout sessions" ON workoutsession;
DROP POLICY IF EXISTS "Users can insert their own workout sessions" ON workoutsession;
DROP POLICY IF EXISTS "Users can update their own workout sessions" ON workoutsession;
DROP POLICY IF EXISTS "Users can delete their own workout sessions" ON workoutsession;

-- Recréer avec (SELECT auth.uid()) pour optimiser les performances
CREATE POLICY "Users can view their own workout sessions"
  ON workoutsession
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own workout sessions"
  ON workoutsession
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own workout sessions"
  ON workoutsession
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own workout sessions"
  ON workoutsession
  FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- 2. TABLE: workoutexercise
-- ============================================

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Users can view exercises from their own workout sessions" ON workoutexercise;
DROP POLICY IF EXISTS "Users can insert exercises to their own workout sessions" ON workoutexercise;
DROP POLICY IF EXISTS "Users can update exercises from their own workout sessions" ON workoutexercise;
DROP POLICY IF EXISTS "Users can delete exercises from their own workout sessions" ON workoutexercise;

-- Recréer avec (SELECT auth.uid()) pour optimiser les performances
CREATE POLICY "Users can view exercises from their own workout sessions"
  ON workoutexercise
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can insert exercises to their own workout sessions"
  ON workoutexercise
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update exercises from their own workout sessions"
  ON workoutexercise
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can delete exercises from their own workout sessions"
  ON workoutexercise
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM workoutsession
      WHERE workoutsession.id = workoutexercise.session_id
      AND workoutsession.user_id = (SELECT auth.uid())
    )
  );

-- ============================================
-- 3. TABLE: exerciseset
-- ============================================

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Users can view their own exercise sets" ON exerciseset;
DROP POLICY IF EXISTS "Users can insert their own exercise sets" ON exerciseset;
DROP POLICY IF EXISTS "Users can update their own exercise sets" ON exerciseset;
DROP POLICY IF EXISTS "Users can delete their own exercise sets" ON exerciseset;

-- Recréer avec (SELECT auth.uid()) pour optimiser les performances
CREATE POLICY "Users can view their own exercise sets"
  ON exerciseset
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own exercise sets"
  ON exerciseset
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own exercise sets"
  ON exerciseset
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own exercise sets"
  ON exerciseset
  FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- 4. TABLE: performedsession
-- ============================================

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Users can view their own performed sessions" ON performedsession;
DROP POLICY IF EXISTS "Users can insert their own performed sessions" ON performedsession;
DROP POLICY IF EXISTS "Users can update their own performed sessions" ON performedsession;
DROP POLICY IF EXISTS "Users can delete their own performed sessions" ON performedsession;

-- Recréer avec (SELECT auth.uid()) pour optimiser les performances
CREATE POLICY "Users can view their own performed sessions"
  ON performedsession
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own performed sessions"
  ON performedsession
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own performed sessions"
  ON performedsession
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own performed sessions"
  ON performedsession
  FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

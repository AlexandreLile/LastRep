-- ============================================
-- CORRECTION : Suppression des policies en double
-- ============================================
-- Il y a des policies en double avec des noms différents.
-- Cette migration supprime TOUTES les policies existantes et les recrée
-- avec les bons noms et la syntaxe optimisée (SELECT auth.uid()).

-- ============================================
-- 1. TABLE: workoutsession
-- ============================================

-- Supprimer TOUTES les policies existantes (peu importe leur nom)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'workoutsession') LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.workoutsession', r.policyname);
  END LOOP;
END $$;

-- Recréer avec (SELECT auth.uid()) pour optimiser les performances
CREATE POLICY "Users can view their own workout sessions"
  ON public.workoutsession
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own workout sessions"
  ON public.workoutsession
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own workout sessions"
  ON public.workoutsession
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own workout sessions"
  ON public.workoutsession
  FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- 2. TABLE: workoutexercise
-- ============================================

-- Supprimer TOUTES les policies existantes
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'workoutexercise') LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.workoutexercise', r.policyname);
  END LOOP;
END $$;

-- Recréer avec (SELECT auth.uid()) pour optimiser les performances
CREATE POLICY "Users can view exercises from their own workout sessions"
  ON public.workoutexercise
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.workoutsession
      WHERE public.workoutsession.id = public.workoutexercise.session_id
      AND public.workoutsession.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can insert exercises to their own workout sessions"
  ON public.workoutexercise
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workoutsession
      WHERE public.workoutsession.id = public.workoutexercise.session_id
      AND public.workoutsession.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update exercises from their own workout sessions"
  ON public.workoutexercise
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.workoutsession
      WHERE public.workoutsession.id = public.workoutexercise.session_id
      AND public.workoutsession.user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workoutsession
      WHERE public.workoutsession.id = public.workoutexercise.session_id
      AND public.workoutsession.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can delete exercises from their own workout sessions"
  ON public.workoutexercise
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.workoutsession
      WHERE public.workoutsession.id = public.workoutexercise.session_id
      AND public.workoutsession.user_id = (SELECT auth.uid())
    )
  );

-- ============================================
-- 3. TABLE: exerciseset
-- ============================================

-- Supprimer TOUTES les policies existantes
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'exerciseset') LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.exerciseset', r.policyname);
  END LOOP;
END $$;

-- Recréer avec (SELECT auth.uid()) pour optimiser les performances
CREATE POLICY "Users can view their own exercise sets"
  ON public.exerciseset
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own exercise sets"
  ON public.exerciseset
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own exercise sets"
  ON public.exerciseset
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own exercise sets"
  ON public.exerciseset
  FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- 4. TABLE: performedsession
-- ============================================

-- Supprimer TOUTES les policies existantes
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'performedsession') LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.performedsession', r.policyname);
  END LOOP;
END $$;

-- Recréer avec (SELECT auth.uid()) pour optimiser les performances
CREATE POLICY "Users can view their own performed sessions"
  ON public.performedsession
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own performed sessions"
  ON public.performedsession
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own performed sessions"
  ON public.performedsession
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own performed sessions"
  ON public.performedsession
  FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

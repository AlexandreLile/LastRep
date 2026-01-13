-- ============================================
-- OPTIMISATION PERFORMANCE : Index sur colonnes fréquemment utilisées
-- ============================================
-- Cette migration ajoute des index sur les colonnes utilisées dans les WHERE,
-- JOIN et ORDER BY pour améliorer significativement les performances des requêtes.

-- ============================================
-- TABLE: performedsession
-- ============================================

-- Index sur user_id (très fréquent dans WHERE avec RLS)
CREATE INDEX IF NOT EXISTS idx_performedsession_user_id 
  ON public.performedsession(user_id);

-- Index sur ended_at (fréquent dans ORDER BY)
CREATE INDEX IF NOT EXISTS idx_performedsession_ended_at 
  ON public.performedsession(ended_at DESC);

-- Index sur started_at (fréquent dans ORDER BY)
CREATE INDEX IF NOT EXISTS idx_performedsession_started_at 
  ON public.performedsession(started_at DESC);

-- Index sur workout_session_id (fréquent dans WHERE et JOIN)
CREATE INDEX IF NOT EXISTS idx_performedsession_workout_session_id 
  ON public.performedsession(workout_session_id);

-- Index composite sur user_id + ended_at (pour les requêtes combinées)
CREATE INDEX IF NOT EXISTS idx_performedsession_user_id_ended_at 
  ON public.performedsession(user_id, ended_at DESC);

-- Index composite sur user_id + workout_session_id (pour les requêtes combinées)
CREATE INDEX IF NOT EXISTS idx_performedsession_user_id_workout_session_id 
  ON public.performedsession(user_id, workout_session_id);

-- ============================================
-- TABLE: exerciseset
-- ============================================

-- Index sur user_id (très fréquent dans WHERE avec RLS)
CREATE INDEX IF NOT EXISTS idx_exerciseset_user_id 
  ON public.exerciseset(user_id);

-- Index sur exercise_id (fréquent dans WHERE)
CREATE INDEX IF NOT EXISTS idx_exerciseset_exercise_id 
  ON public.exerciseset(exercise_id);

-- Index sur performed_session_id (fréquent dans WHERE)
CREATE INDEX IF NOT EXISTS idx_exerciseset_performed_session_id 
  ON public.exerciseset(performed_session_id);

-- Index sur created_at (fréquent dans ORDER BY)
CREATE INDEX IF NOT EXISTS idx_exerciseset_created_at 
  ON public.exerciseset(created_at DESC);

-- Index composite sur user_id + exercise_id (pour les requêtes combinées)
CREATE INDEX IF NOT EXISTS idx_exerciseset_user_id_exercise_id 
  ON public.exerciseset(user_id, exercise_id);

-- Index composite sur user_id + created_at (pour les requêtes combinées)
CREATE INDEX IF NOT EXISTS idx_exerciseset_user_id_created_at 
  ON public.exerciseset(user_id, created_at DESC);

-- Index composite sur exercise_id + weight_kg + reps (pour les ORDER BY combinés)
CREATE INDEX IF NOT EXISTS idx_exerciseset_exercise_id_weight_reps 
  ON public.exerciseset(exercise_id, weight_kg DESC, reps DESC);

-- Index composite sur performed_session_id + user_id (pour les requêtes combinées)
CREATE INDEX IF NOT EXISTS idx_exerciseset_performed_session_id_user_id 
  ON public.exerciseset(performed_session_id, user_id);

-- ============================================
-- TABLE: workoutsession
-- ============================================

-- Index sur user_id (très fréquent dans WHERE avec RLS)
CREATE INDEX IF NOT EXISTS idx_workoutsession_user_id 
  ON public.workoutsession(user_id);

-- Index sur date (fréquent dans ORDER BY)
CREATE INDEX IF NOT EXISTS idx_workoutsession_date 
  ON public.workoutsession(date DESC);

-- Index composite sur user_id + date (pour les requêtes combinées)
CREATE INDEX IF NOT EXISTS idx_workoutsession_user_id_date 
  ON public.workoutsession(user_id, date DESC);

-- ============================================
-- TABLE: workoutexercise
-- ============================================

-- Index sur session_id (fréquent dans WHERE et JOIN)
CREATE INDEX IF NOT EXISTS idx_workoutexercise_session_id 
  ON public.workoutexercise(session_id);

-- Index sur order (fréquent dans ORDER BY)
CREATE INDEX IF NOT EXISTS idx_workoutexercise_order 
  ON public.workoutexercise("order" ASC);

-- Index composite sur session_id + order (pour les requêtes combinées)
CREATE INDEX IF NOT EXISTS idx_workoutexercise_session_id_order 
  ON public.workoutexercise(session_id, "order" ASC);

-- ============================================
-- TABLE: exercise
-- ============================================

-- Index sur name (fréquent dans ORDER BY)
CREATE INDEX IF NOT EXISTS idx_exercise_name 
  ON public.exercise(name ASC);

-- ============================================
-- NOTES
-- ============================================
-- Ces index amélioreront les performances des requêtes suivantes :
-- - Filtrage par user_id (avec RLS)
-- - Tri par date/heure (ended_at, started_at, created_at, date)
-- - Jointures sur les foreign keys
-- - Requêtes combinant plusieurs critères
--
-- Les index composites sont particulièrement efficaces pour les requêtes
-- qui filtrent ET trient sur plusieurs colonnes en même temps.

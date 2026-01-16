-- ============================================
-- NETTOYAGE COMPLET DE LA BASE DE DONNÉES
-- ============================================
-- Cette migration supprime TOUTES les données de toutes les tables
-- mais préserve la structure des tables (schéma)
-- 
-- ATTENTION : Cette opération est irréversible !
-- Toutes les données utilisateur seront perdues.

-- ============================================
-- 1. SUPPRIMER LES DONNÉES DANS L'ORDRE DES DÉPENDANCES
-- ============================================

-- Afficher le nombre d'enregistrements avant suppression
DO $$
DECLARE
  exerciseset_count INTEGER;
  performed_count INTEGER;
  workout_exercise_count INTEGER;
  workout_session_count INTEGER;
  exercise_muscle_count INTEGER;
  exercise_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO exerciseset_count FROM exerciseset;
  SELECT COUNT(*) INTO performed_count FROM performedsession;
  SELECT COUNT(*) INTO workout_exercise_count FROM workoutexercise;
  SELECT COUNT(*) INTO workout_session_count FROM workoutsession;
  SELECT COUNT(*) INTO exercise_muscle_count FROM exercise_muscle;
  SELECT COUNT(*) INTO exercise_count FROM exercise;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'NETTOYAGE DES DONNÉES UTILISATEUR';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Enregistrements à supprimer :';
  RAISE NOTICE '  - exerciseset: %', exerciseset_count;
  RAISE NOTICE '  - performedsession: %', performed_count;
  RAISE NOTICE '  - workoutexercise: %', workout_exercise_count;
  RAISE NOTICE '  - workoutsession: %', workout_session_count;
  RAISE NOTICE '  - exercise_muscle: %', exercise_muscle_count;
  RAISE NOTICE '';
  RAISE NOTICE 'PRÉSERVÉS (non supprimés) :';
  RAISE NOTICE '  - exercise: % (exercices préservés)', exercise_count;
  RAISE NOTICE '  - muscle: (muscles préservés)';
  RAISE NOTICE '========================================';
END $$;

-- 1. Supprimer toutes les séries (exerciseset)
--    Dépend de : exercise, performed_session, user
DELETE FROM exerciseset;

-- 2. Supprimer toutes les séances effectuées (performedsession)
--    Dépend de : workout_session, user
DELETE FROM performedsession;

-- 3. Supprimer tous les exercices des séances (workoutexercise)
--    Dépend de : session, exercise
DELETE FROM workoutexercise;

-- 4. Supprimer toutes les séances (workoutsession)
--    Dépend de : user
DELETE FROM workoutsession;

-- 5. Supprimer toutes les associations exercice-muscle (exercise_muscle)
--    Dépend de : exercise, muscle
--    NOTE : On garde les exercices, donc on ne supprime que les associations
--    qui ne sont plus nécessaires (les exercices seront recréés avec leurs muscles)
DELETE FROM exercise_muscle;

-- 6. NE PAS SUPPRIMER LES EXERCICES
--    Les exercices sont préservés car ils contiennent les exercices détaillés
--    ajoutés récemment avec plusieurs muscles

-- 7. NE PAS SUPPRIMER LES MUSCLES
--    Les muscles sont préservés car ils sont nécessaires pour les exercices

-- ============================================
-- 2. RÉINITIALISER LES SÉQUENCES (si nécessaire)
-- ============================================

-- Réinitialiser les séquences pour les IDs auto-incrémentés
-- Note : Les UUID ne nécessitent pas de réinitialisation

-- Réinitialiser la séquence de muscle.id
ALTER SEQUENCE IF EXISTS muscle_id_seq RESTART WITH 1;

-- ============================================
-- 3. VÉRIFICATION POST-SUPPRESSION
-- ============================================

DO $$
DECLARE
  exerciseset_count INTEGER;
  performed_count INTEGER;
  workout_exercise_count INTEGER;
  workout_session_count INTEGER;
  exercise_muscle_count INTEGER;
  exercise_count INTEGER;
  muscle_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO exerciseset_count FROM exerciseset;
  SELECT COUNT(*) INTO performed_count FROM performedsession;
  SELECT COUNT(*) INTO workout_exercise_count FROM workoutexercise;
  SELECT COUNT(*) INTO workout_session_count FROM workoutsession;
  SELECT COUNT(*) INTO exercise_muscle_count FROM exercise_muscle;
  SELECT COUNT(*) INTO exercise_count FROM exercise;
  SELECT COUNT(*) INTO muscle_count FROM muscle;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VÉRIFICATION POST-SUPPRESSION';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Données utilisateur supprimées :';
  RAISE NOTICE '  - exerciseset: %', exerciseset_count;
  RAISE NOTICE '  - performedsession: %', performed_count;
  RAISE NOTICE '  - workoutexercise: %', workout_exercise_count;
  RAISE NOTICE '  - workoutsession: %', workout_session_count;
  RAISE NOTICE '  - exercise_muscle: %', exercise_muscle_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Données préservées :';
  RAISE NOTICE '  - exercise: % (exercices préservés)', exercise_count;
  RAISE NOTICE '  - muscle: % (muscles préservés)', muscle_count;
  RAISE NOTICE '========================================';
  
  IF exerciseset_count = 0 
     AND performed_count = 0 
     AND workout_exercise_count = 0 
     AND workout_session_count = 0 
     AND exercise_muscle_count = 0 THEN
    RAISE NOTICE '✅ NETTOYAGE RÉUSSI : Toutes les données utilisateur ont été supprimées';
    RAISE NOTICE '✅ Les exercices et muscles ont été préservés';
  ELSE
    RAISE WARNING '⚠️  ATTENTION : Certaines données utilisateur restent dans la base';
  END IF;
END $$;

-- ============================================
-- NOTES
-- ============================================
-- Cette migration supprime les données utilisateur :
-- - Toutes les séries (exerciseset)
-- - Toutes les séances effectuées (performedsession)
-- - Tous les exercices des séances (workoutexercise)
-- - Toutes les séances (workoutsession)
-- - Toutes les associations exercice-muscle (exercise_muscle)
--
-- PRÉSERVÉS (non supprimés) :
-- - Tous les exercices (exercise) - globaux ET personnalisés
-- - Tous les muscles (muscle)
--
-- La structure des tables est préservée.
-- Les exercices et muscles restent disponibles pour utilisation.

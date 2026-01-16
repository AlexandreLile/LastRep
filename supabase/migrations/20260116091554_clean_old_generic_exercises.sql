-- ============================================
-- NETTOYAGE DES ANCIENS EXERCICES GÉNÉRIQUES
-- ============================================
-- Cette migration supprime les anciens exercices qui :
-- 1. Ont été créés avant l'ajout des exercices détaillés (avant le 16 janvier 2026)
-- 2. Ont des muscles génériques (Jambes, Pectoraux, Épaules, etc.)
-- 3. N'ont qu'un seul muscle associé (ou aucun)
-- 4. Ne sont pas utilisés dans des séances ou séries
-- 5. Sont des exercices globaux (pas personnalisés)

-- ============================================
-- 1. IDENTIFIER LES EXERCICES À SUPPRIMER
-- ============================================

-- Créer une table temporaire pour stocker les IDs des exercices à supprimer
CREATE TEMP TABLE IF NOT EXISTS exercises_to_delete AS
SELECT DISTINCT e.id
FROM exercise e
WHERE 
  -- Exercices globaux uniquement (pas les exercices personnalisés)
  e.is_custom = false
  -- Créés avant l'ajout des exercices détaillés (16 janvier 2026)
  AND e.created_at < '2026-01-16 00:00:00'
  -- Avec des muscles génériques dans primary_muscle
  AND e.primary_muscle IN ('Jambes', 'Pectoraux', 'Épaules', 'Dorsaux', 'Biceps', 'Triceps', 'Abdominaux', 'Cardio', 'Autre')
  -- Qui n'ont qu'un seul muscle associé (ou aucun) dans exercise_muscle
  AND (
    SELECT COUNT(*)
    FROM exercise_muscle em
    WHERE em.exercise_id = e.id
  ) <= 1
  -- Qui ne sont pas utilisés dans des séances (workoutexercise)
  AND NOT EXISTS (
    SELECT 1
    FROM workoutexercise we
    WHERE we.exercise_id = e.id
  )
  -- Qui ne sont pas utilisés dans des séries (exerciseset)
  AND NOT EXISTS (
    SELECT 1
    FROM exerciseset es
    WHERE es.exercise_id = e.id
  );

-- ============================================
-- 2. AFFICHER LES EXERCICES QUI SERONT SUPPRIMÉS (pour vérification)
-- ============================================

-- Voir combien d'exercices seront supprimés
DO $$
DECLARE
  delete_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO delete_count FROM exercises_to_delete;
  RAISE NOTICE 'Nombre d''exercices à supprimer: %', delete_count;
END $$;

-- Afficher la liste des exercices qui seront supprimés
DO $$
DECLARE
  exercise_record RECORD;
  total_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_count FROM exercises_to_delete;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'EXERCICES QUI SERONT SUPPRIMÉS: %', total_count;
  RAISE NOTICE '========================================';
  
  FOR exercise_record IN 
    SELECT 
      e.id,
      e.name,
      e.primary_muscle,
      e.created_at,
      (SELECT COUNT(*) FROM exercise_muscle em WHERE em.exercise_id = e.id) as muscle_count
    FROM exercise e
    INNER JOIN exercises_to_delete etd ON e.id = etd.id
    ORDER BY e.created_at ASC, e.name ASC
  LOOP
    RAISE NOTICE 'ID: %, Nom: %, Muscle: %, Créé: %, Muscles associés: %', 
      exercise_record.id, 
      exercise_record.name, 
      exercise_record.primary_muscle,
      exercise_record.created_at,
      exercise_record.muscle_count;
  END LOOP;
  
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 3. SUPPRIMER LES ASSOCIATIONS EXERCICE-MUSCLE
-- ============================================

DELETE FROM exercise_muscle
WHERE exercise_id IN (SELECT id FROM exercises_to_delete);

-- ============================================
-- 4. SUPPRIMER LES EXERCICES
-- ============================================

DELETE FROM exercise
WHERE id IN (SELECT id FROM exercises_to_delete);

-- ============================================
-- 5. NETTOYER LA TABLE TEMPORAIRE
-- ============================================

DROP TABLE IF EXISTS exercises_to_delete;

-- ============================================
-- NOTES
-- ============================================
-- Cette migration supprime uniquement :
-- - Les exercices globaux (is_custom = false)
-- - Créés avant le 16 janvier 2026
-- - Avec des muscles génériques
-- - Non utilisés dans des séances ou séries
-- 
-- Les exercices personnalisés des utilisateurs sont préservés.
-- Les exercices récemment ajoutés avec des muscles détaillés sont préservés.
-- Les exercices utilisés dans des séances/séries sont préservés.

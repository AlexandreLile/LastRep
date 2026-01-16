-- ============================================
-- AJOUT D'EXERCICES DE FENTES
-- ============================================
-- Cette migration ajoute deux exercices de fentes :
-- 1. Fente avant (Forward Lunge)
-- 2. Fente bulgare (Bulgarian Split Squat)

-- Note : Ces exercices sont différents des variantes existantes :
-- - "Fente avant" n'existe pas encore (il y a "Fentes marchées" et "Fentes arrière")
-- - "Fente bulgare" sans précision d'équipement n'existe pas (il y a "Bulgarian Split Squat haltères")

-- 1. Fente avant (Forward Lunge)
-- Principal : Quadriceps
-- Secondaires : Fessiers, Ischio-jambiers, Adducteurs, Abdominaux (gainage)
SELECT add_exercise_if_not_exists('Fente avant (Forward Lunge)', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);

-- 2. Fente bulgare (Bulgarian Split Squat)
-- Principal : Fessiers
-- Secondaires : Quadriceps, Ischio-jambiers, Adducteurs, Abdominaux (gainage)
SELECT add_exercise_if_not_exists('Fente bulgare (Bulgarian Split Squat)', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);

-- ============================================
-- VÉRIFICATION
-- ============================================
DO $$
DECLARE
  fente_avant_count INTEGER;
  fente_bulgare_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO fente_avant_count 
  FROM exercise 
  WHERE LOWER(TRIM(name)) = LOWER('Fente avant (Forward Lunge)');
  
  SELECT COUNT(*) INTO fente_bulgare_count 
  FROM exercise 
  WHERE LOWER(TRIM(name)) = LOWER('Fente bulgare (Bulgarian Split Squat)');
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'AJOUT DES EXERCICES DE FENTES';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Fente avant (Forward Lunge): %', CASE WHEN fente_avant_count > 0 THEN '✅ Ajouté' ELSE '❌ Non trouvé' END;
  RAISE NOTICE 'Fente bulgare (Bulgarian Split Squat): %', CASE WHEN fente_bulgare_count > 0 THEN '✅ Ajouté' ELSE '❌ Non trouvé' END;
  RAISE NOTICE '========================================';
END $$;

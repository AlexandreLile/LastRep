-- ============================================
-- CORRECTION DES CATÉGORIES D'EXERCICES
-- ============================================
-- Cette migration corrige les catégories des exercices existants
-- en fonction de leur nom (machine, élastique, câble, etc.)

-- ============================================
-- 1. CORRIGER LES EXERCICES SUR MACHINE
-- ============================================

UPDATE exercise 
SET category_id = (SELECT id FROM exercise_category WHERE name = 'Machine')
WHERE (
  LOWER(name) LIKE '%machine%'
  OR LOWER(name) LIKE '%leg press%'
  OR LOWER(name) LIKE '%leg extension%'
  OR LOWER(name) LIKE '%leg curl%'
  OR LOWER(name) LIKE '%pec deck%'
  OR LOWER(name) LIKE '%hack squat%'
  OR LOWER(name) LIKE '%smith machine%'
  OR LOWER(name) LIKE '%abduction machine%'
  OR LOWER(name) LIKE '%glute kickback machine%'
  OR LOWER(name) LIKE '%hip thrust machine%'
  OR LOWER(name) LIKE '%développé assis machine%'
  OR LOWER(name) LIKE '%développé incliné machine%'
  OR LOWER(name) LIKE '%développé décliné machine%'
  OR LOWER(name) LIKE '%tirage poitrine%'
  OR LOWER(name) LIKE '%tirage nuque%'
  OR LOWER(name) LIKE '%rowing assis machine%'
  OR LOWER(name) LIKE '%pull-over machine%'
  OR LOWER(name) LIKE '%curl machine%'
  OR LOWER(name) LIKE '%extension triceps machine%'
  OR LOWER(name) LIKE '%push-down poulie%'
  OR LOWER(name) LIKE '%push-down câble%'
)
AND is_custom = false
AND category_id = (SELECT id FROM exercise_category WHERE name = 'Poids libre');

-- ============================================
-- 2. CORRIGER LES EXERCICES AVEC ÉLASTIQUE
-- ============================================

UPDATE exercise 
SET category_id = (SELECT id FROM exercise_category WHERE name = 'Élastique')
WHERE (
  LOWER(name) LIKE '%élastique%'
  OR LOWER(name) LIKE '%monster walk%'
  OR LOWER(name) LIKE '%lateral walk%'
  OR LOWER(name) LIKE '%glute bridge élastique%'
  OR LOWER(name) LIKE '%hip thrust élastique%'
  OR LOWER(name) LIKE '%kickback élastique%'
  OR LOWER(name) LIKE '%leg curl élastique%'
  OR LOWER(name) LIKE '%extension triceps élastique%'
  OR LOWER(name) LIKE '%pull-through élastique%'
)
AND is_custom = false
AND category_id = (SELECT id FROM exercise_category WHERE name = 'Poids libre');

-- ============================================
-- 3. CORRIGER LES EXERCICES AVEC CÂBLES
-- ============================================
-- Note: Les exercices avec câbles peuvent être considérés comme "Poids libre"
-- car ils utilisent des poids, mais on peut aussi les mettre dans une catégorie séparée
-- Pour l'instant, on les laisse en "Poids libre" car ils utilisent des poids

-- ============================================
-- 4. MESSAGE DE CONFIRMATION
-- ============================================

DO $$
DECLARE
  machine_count INTEGER;
  elastic_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO machine_count
  FROM exercise e
  JOIN exercise_category ec ON e.category_id = ec.id
  WHERE ec.name = 'Machine'
  AND e.is_custom = false;
  
  SELECT COUNT(*) INTO elastic_count
  FROM exercise e
  JOIN exercise_category ec ON e.category_id = ec.id
  WHERE ec.name = 'Élastique'
  AND e.is_custom = false;
  
  RAISE NOTICE '✅ Migration terminée :';
  RAISE NOTICE '   - % exercices sur machine', machine_count;
  RAISE NOTICE '   - % exercices avec élastique', elastic_count;
END $$;

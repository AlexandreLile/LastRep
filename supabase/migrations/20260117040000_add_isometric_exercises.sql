-- ============================================
-- AJOUT DES EXERCICES ISOMÉTRIQUES
-- ============================================
-- Cette migration ajoute les exercices d'isométrie
-- avec la catégorie "Isométrie" et measurement_type "time"

-- ============================================
-- EXERCICES ISOMÉTRIQUES
-- ============================================

SELECT add_exercise_if_not_exists(
  'Planche (Plank)',
  'Transverse',
  ARRAY['Transverse', 'Grand droit', 'Obliques', 'Lombaires', 'Fessiers'],
  'time',
  false,
  NULL,
  'Isométrie'
);

SELECT add_exercise_if_not_exists(
  'Planche latérale (Side Plank)',
  'Obliques',
  ARRAY['Obliques', 'Transverse', 'Grand droit', 'Lombaires'],
  'time',
  false,
  NULL,
  'Isométrie'
);

SELECT add_exercise_if_not_exists(
  'Hollow hold',
  'Grand droit',
  ARRAY['Grand droit', 'Transverse', 'Obliques'],
  'time',
  false,
  NULL,
  'Isométrie'
);

SELECT add_exercise_if_not_exists(
  'L-sit',
  'Grand droit',
  ARRAY['Grand droit', 'Fléchisseurs de hanche', 'Obliques'],
  'time',
  false,
  NULL,
  'Isométrie'
);

-- ============================================
-- MESSAGE DE CONFIRMATION
-- ============================================

DO $$
DECLARE
  isometric_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO isometric_count
  FROM exercise e
  JOIN exercise_category ec ON e.category_id = ec.id
  WHERE ec.name = 'Isométrie'
  AND e.is_custom = false;
  
  RAISE NOTICE '✅ Migration terminée : % exercices isométriques au total', isometric_count;
END $$;

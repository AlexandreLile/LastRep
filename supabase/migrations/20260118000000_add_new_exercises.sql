-- ============================================
-- AJOUT DE NOUVEAUX EXERCICES
-- ============================================
-- Cette migration ajoute 3 nouveaux exercices avec leurs muscles associés

-- ============================================
-- 1. TIRAGE HORIZONTAL – MACHINE
-- ============================================
SELECT add_exercise_if_not_exists(
  'Tirage horizontal – machine',
  'Grand dorsal',
  ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps'],
  'weight_reps',
  false,
  NULL,
  'Machine'
);

-- ============================================
-- 2. TIRAGE HORIZONTAL – POULIE
-- ============================================
SELECT add_exercise_if_not_exists(
  'Tirage horizontal – poulie',
  'Grand dorsal',
  ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps'],
  'weight_reps',
  false,
  NULL,
  'Machine'
);

-- ============================================
-- 3. DÉVELOPPÉ MILITAIRE – HALTÈRES
-- ============================================
SELECT add_exercise_if_not_exists(
  'Développé militaire – haltères',
  'Deltoïdes antérieurs',
  ARRAY['Deltoïdes antérieurs', 'Deltoïdes moyens', 'Trapèzes supérieurs', 'Triceps'],
  'weight_reps',
  false,
  NULL,
  'Poids libre'
);

-- ============================================
-- MESSAGE DE CONFIRMATION
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Migration terminée : 3 nouveaux exercices ajoutés';
  RAISE NOTICE '  - Tirage horizontal – machine (Machine)';
  RAISE NOTICE '  - Tirage horizontal – poulie (Machine)';
  RAISE NOTICE '  - Développé militaire – haltères (Poids libre)';
END $$;

-- ============================================
-- AJOUT DES EXERCICES AU POIDS DU CORPS
-- ============================================
-- Cette migration ajoute tous les exercices au poids du corps
-- avec la catégorie "Poids du corps" et measurement_type "reps"
-- Note: Les noms incluent "(poids du corps)" pour les distinguer des versions avec poids

-- ============================================
-- 🏋️ POIDS DU CORPS – PECTORAUX / TRICEPS / ÉPAULES
-- ============================================

SELECT add_exercise_if_not_exists(
  'Pompes classiques (Push-up)',
  'Pectoraux',
  ARRAY['Pectoraux', 'Triceps', 'Deltoïdes antérieurs', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Pompes inclinées',
  'Pectoraux',
  ARRAY['Pectoraux', 'Triceps', 'Deltoïdes antérieurs', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Pompes déclinées',
  'Pectoraux',
  ARRAY['Pectoraux', 'Triceps', 'Deltoïdes antérieurs', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Pompes diamant',
  'Triceps',
  ARRAY['Triceps', 'Pectoraux', 'Deltoïdes antérieurs', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Pompes Spiderman',
  'Pectoraux',
  ARRAY['Pectoraux', 'Triceps', 'Deltoïdes antérieurs', 'Obliques', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Pompes avec rotation',
  'Pectoraux',
  ARRAY['Pectoraux', 'Triceps', 'Deltoïdes antérieurs', 'Obliques', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Dips',
  'Triceps',
  ARRAY['Triceps', 'Pectoraux', 'Deltoïdes antérieurs'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

-- ============================================
-- 🏋️ POIDS DU CORPS – DOS / BICEPS
-- ============================================

SELECT add_exercise_if_not_exists(
  'Tractions (Pull-up)',
  'Grand dorsal',
  ARRAY['Grand dorsal', 'Biceps', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Tractions supination (Chin-up)',
  'Grand dorsal',
  ARRAY['Grand dorsal', 'Biceps', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Australian Pull-up',
  'Grand dorsal',
  ARRAY['Grand dorsal', 'Biceps', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Row inversé',
  'Grand dorsal',
  ARRAY['Grand dorsal', 'Biceps', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Superman',
  'Lombaires',
  ARRAY['Lombaires', 'Fessiers', 'Trapèzes'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

-- ============================================
-- 🏋️ POIDS DU CORPS – FESSIERS / JAMBES
-- ============================================

SELECT add_exercise_if_not_exists(
  'Squat (poids du corps)',
  'Quadriceps',
  ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Squat sumo (poids du corps)',
  'Fessiers',
  ARRAY['Fessiers', 'Quadriceps', 'Adducteurs', 'Ischio-jambiers'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Fente avant (poids du corps)',
  'Quadriceps',
  ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Fente arrière (poids du corps)',
  'Fessiers',
  ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Fente bulgare (poids du corps)',
  'Fessiers',
  ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Glute Bridge',
  'Fessiers',
  ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Hip Thrust au sol',
  'Fessiers',
  ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Donkey Kick',
  'Fessiers',
  ARRAY['Fessiers', 'Lombaires', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Fire Hydrant',
  'Fessiers moyens',
  ARRAY['Fessiers moyens', 'Petit fessier', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Step-up (poids du corps)',
  'Quadriceps',
  ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Mollets'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Pistol squat',
  'Quadriceps',
  ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Squat sur une jambe',
  'Quadriceps',
  ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Abdominaux'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

-- ============================================
-- 🏋️ POIDS DU CORPS – ABDOS / CORE
-- ============================================

SELECT add_exercise_if_not_exists(
  'Crunch',
  'Grand droit',
  ARRAY['Grand droit', 'Obliques', 'Transverse'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Sit-up',
  'Grand droit',
  ARRAY['Grand droit', 'Obliques', 'Transverse'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Relevé de jambes suspension',
  'Grand droit',
  ARRAY['Grand droit', 'Fléchisseurs de hanche', 'Obliques'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'V-sit',
  'Grand droit',
  ARRAY['Grand droit', 'Obliques', 'Fléchisseurs de hanche'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Jackknife',
  'Grand droit',
  ARRAY['Grand droit', 'Obliques', 'Fléchisseurs de hanche'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Mountain Climbers',
  'Grand droit',
  ARRAY['Grand droit', 'Obliques', 'Transverse', 'Fléchisseurs de hanche', 'Deltoïdes'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Russian Twist au sol',
  'Obliques',
  ARRAY['Obliques', 'Grand droit', 'Transverse'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

-- ============================================
-- 🏋️ POIDS DU CORPS – MOLLETS
-- ============================================

SELECT add_exercise_if_not_exists(
  'Calf Raise sur une marche',
  'Gastrocnémien',
  ARRAY['Gastrocnémien', 'Soléaire', 'Tibial antérieur'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Single Leg Calf Raise',
  'Gastrocnémien',
  ARRAY['Gastrocnémien', 'Soléaire', 'Tibial antérieur'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);

SELECT add_exercise_if_not_exists(
  'Calf Raise une jambe',
  'Gastrocnémien',
  ARRAY['Gastrocnémien', 'Soléaire', 'Tibial antérieur'],
  'reps',
  false,
  NULL,
  'Poids du corps'
);


-- ============================================
-- MESSAGE DE CONFIRMATION
-- ============================================

DO $$
DECLARE
  bodyweight_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO bodyweight_count
  FROM exercise e
  JOIN exercise_category ec ON e.category_id = ec.id
  WHERE ec.name = 'Poids du corps';
  
  RAISE NOTICE '✅ Migration terminée : % exercices au poids du corps au total', bodyweight_count;
END $$;

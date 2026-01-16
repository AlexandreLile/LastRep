-- ============================================
-- AJOUT D'EXERCICES QUADRICEPS ET ISCHIO-JAMBIERS AVEC MUSCLES MULTIPLES
-- ============================================
-- Cette migration ajoute une série d'exercices quadriceps et ischio-jambiers avec leurs muscles principaux et secondaires
-- Elle vérifie les doublons avant insertion

-- ============================================
-- 1. AJOUTER TOUS LES EXERCICES QUADRICEPS / ISCHIO-JAMBIERS
-- ============================================

-- 🏋️ Exercices quadriceps – barre
-- Note: Certains exercices peuvent déjà exister (gérés par add_exercise_if_not_exists)
SELECT add_exercise_if_not_exists('Squat back squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Squat front squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Adducteurs', 'Abdominaux', 'Dorsaux']);
SELECT add_exercise_if_not_exists('Squat sumo barre', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Adducteurs', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Split squat barre', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift barre', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Trapèzes', 'Biceps', 'Quadriceps']);

-- 🏋️‍♀️ Exercices quadriceps – haltères / kettlebells
SELECT add_exercise_if_not_exists('Goblet squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Bulgarian Split Squat haltères', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Step-up haltères', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Mollets', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Fentes marchées haltères', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Fentes arrière haltères', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift kettlebell / RDL haltères', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Quadriceps']);

-- 🧱 Exercices quadriceps / ischio – machines
SELECT add_exercise_if_not_exists('Leg Press (pieds bas)', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers']);
SELECT add_exercise_if_not_exists('Leg Press (pieds hauts / larges)', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs']);
SELECT add_exercise_if_not_exists('Leg Extension (quad machine)', 'Quadriceps', ARRAY['Quadriceps']);
SELECT add_exercise_if_not_exists('Leg Curl (assis / allongé)', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers']);
SELECT add_exercise_if_not_exists('Hack Squat machine', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers']);

-- 🧲 Exercices quadriceps / ischio – câbles / élastiques
SELECT add_exercise_if_not_exists('Kickback élastique / câble', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Monster Walk / Lateral Walk élastique', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Quadriceps', 'Petit fessier', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Leg Curl élastique', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers']);

-- ============================================
-- NOTES
-- ============================================
-- Cette migration :
-- 1. Insère tous les exercices quadriceps et ischio-jambiers avec leurs muscles associés
-- 2. Vérifie les doublons par nom (insensible à la casse et aux espaces)
-- 3. Associe automatiquement les muscles principaux et secondaires
-- 4. Certains exercices peuvent déjà exister (comme Squat back squat) mais seront ignorés grâce à la vérification de doublon

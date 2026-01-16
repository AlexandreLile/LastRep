-- ============================================
-- AJOUT D'EXERCICES DOS AVEC MUSCLES MULTIPLES
-- ============================================
-- Cette migration ajoute une série d'exercices dos avec leurs muscles principaux et secondaires
-- Elle vérifie les doublons avant insertion

-- ============================================
-- 1. AJOUTER LES NOUVEAUX MUSCLES MANQUANTS
-- ============================================

INSERT INTO muscle (name) VALUES
  ('Grand dorsal'),
  ('Rhomboïdes'),
  ('Deltoïdes postérieurs'),
  ('Deltoïdes moyens'),
  ('Trapèzes supérieurs'),
  ('Trapèzes moyens'),
  ('Trapèzes inférieurs'),
  ('Érecteurs du rachis')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 2. AJOUTER TOUS LES EXERCICES DOS
-- ============================================

-- 🏋️ Exercices dos – barre
SELECT add_exercise_if_not_exists('Deadlift barre', 'Érecteurs du rachis', ARRAY['Érecteurs du rachis', 'Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Fessiers', 'Ischio-jambiers', 'Biceps']);
SELECT add_exercise_if_not_exists('Rowing barre (Barbell Row)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps', 'Lombaires']);
SELECT add_exercise_if_not_exists('Tirage menton barre (Upright Row)', 'Trapèzes', ARRAY['Trapèzes', 'Deltoïdes postérieurs', 'Deltoïdes moyens', 'Biceps']);
SELECT add_exercise_if_not_exists('Traction pronation barre (Pull-up)', 'Grand dorsal', ARRAY['Grand dorsal', 'Biceps', 'Trapèzes moyens', 'Trapèzes inférieurs', 'Rhomboïdes', 'Deltoïdes postérieurs']);
SELECT add_exercise_if_not_exists('Traction supination barre (Chin-up)', 'Grand dorsal', ARRAY['Grand dorsal', 'Biceps', 'Trapèzes moyens', 'Trapèzes inférieurs', 'Rhomboïdes']);

-- 🏋️‍♀️ Exercices dos – haltères / kettlebells
SELECT add_exercise_if_not_exists('Rowing haltère unilatéral (One-arm Dumbbell Row)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps']);
SELECT add_exercise_if_not_exists('Rowing haltères simultané (Bent-over Dumbbell Row)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps']);
SELECT add_exercise_if_not_exists('Shrugs haltères', 'Trapèzes supérieurs', ARRAY['Trapèzes supérieurs', 'Deltoïdes postérieurs']);
SELECT add_exercise_if_not_exists('Pull-over haltère', 'Grand dorsal', ARRAY['Grand dorsal', 'Pectoraux', 'Triceps']);

-- 🧱 Exercices dos – machines
SELECT add_exercise_if_not_exists('Tirage poitrine (Lat Pulldown)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Tirage nuque (Lat Pulldown derrière)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Rowing assis machine', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps']);
SELECT add_exercise_if_not_exists('Pull-over machine', 'Grand dorsal', ARRAY['Grand dorsal', 'Pectoraux', 'Triceps']);

-- 🧲 Exercices dos – câbles / élastiques
SELECT add_exercise_if_not_exists('Tirage câble poitrine', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Tirage câble nuque', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Rowing câble assis', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps']);
SELECT add_exercise_if_not_exists('Face pull (câble)', 'Deltoïdes postérieurs', ARRAY['Deltoïdes postérieurs', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Pull-through élastique', 'Érecteurs du rachis', ARRAY['Érecteurs du rachis', 'Fessiers', 'Ischio-jambiers', 'Grand dorsal']);

-- ============================================
-- NOTES
-- ============================================
-- Cette migration :
-- 1. Ajoute les nouveaux muscles manquants (Grand dorsal, Rhomboïdes, Deltoïdes postérieurs/moyens, Trapèzes variantes, Érecteurs du rachis)
-- 2. Insère tous les exercices dos avec leurs muscles associés
-- 3. Vérifie les doublons par nom (insensible à la casse et aux espaces)
-- 4. Associe automatiquement les muscles principaux et secondaires

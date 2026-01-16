-- ============================================
-- AJOUT D'EXERCICES ABDOMINAUX AVEC MUSCLES MULTIPLES
-- ============================================
-- Cette migration ajoute une série d'exercices abdominaux avec leurs muscles principaux et secondaires
-- Elle vérifie les doublons avant insertion

-- ============================================
-- 1. AJOUTER LES NOUVEAUX MUSCLES MANQUANTS
-- ============================================

INSERT INTO muscle (name) VALUES
  ('Obliques'),
  ('Grand droit'),
  ('Transverse'),
  ('Fléchisseurs de hanche')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 2. AJOUTER TOUS LES EXERCICES ABDOMINAUX
-- ============================================

-- 🏋️‍♀️ Exercices abdos – haltères / kettlebells
SELECT add_exercise_if_not_exists('Russian Twist avec haltère / kettlebell', 'Obliques', ARRAY['Obliques', 'Grand droit', 'Transverse', 'Lombaires']);
SELECT add_exercise_if_not_exists('Sit-up avec poids', 'Grand droit', ARRAY['Grand droit', 'Obliques', 'Transverse', 'Fléchisseurs de hanche']);
SELECT add_exercise_if_not_exists('Weighted Leg Raise', 'Grand droit', ARRAY['Grand droit', 'Fléchisseurs de hanche', 'Obliques']);

-- 🧱 Exercices abdos – machines
SELECT add_exercise_if_not_exists('Crunch machine', 'Grand droit', ARRAY['Grand droit', 'Obliques', 'Transverse']);
SELECT add_exercise_if_not_exists('Roman Chair / Hyperextension', 'Lombaires', ARRAY['Lombaires', 'Fessiers', 'Grand droit', 'Obliques']);
SELECT add_exercise_if_not_exists('Twist machine', 'Obliques', ARRAY['Obliques', 'Grand droit', 'Transverse']);

-- 🧲 Exercices abdos – câbles / élastiques
SELECT add_exercise_if_not_exists('Cable Crunch', 'Grand droit', ARRAY['Grand droit', 'Obliques', 'Transverse']);
SELECT add_exercise_if_not_exists('Woodchopper (câble)', 'Obliques', ARRAY['Obliques', 'Grand droit', 'Transverse', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Pallof Press (câble)', 'Transverse', ARRAY['Transverse', 'Grand droit', 'Obliques', 'Deltoïdes antérieurs', 'Lombaires']);

-- ============================================
-- NOTES
-- ============================================
-- Cette migration :
-- 1. Ajoute les nouveaux muscles manquants (Obliques, Grand droit, Transverse, Fléchisseurs de hanche)
-- 2. Insère tous les exercices abdominaux avec leurs muscles associés
-- 3. Vérifie les doublons par nom (insensible à la casse et aux espaces)
-- 4. Associe automatiquement les muscles principaux et secondaires

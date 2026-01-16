-- ============================================
-- AJOUT D'EXERCICES MOLETS AVEC MUSCLES MULTIPLES
-- ============================================
-- Cette migration ajoute une série d'exercices mollets avec leurs muscles principaux et secondaires
-- Elle vérifie les doublons avant insertion

-- ============================================
-- 1. AJOUTER LES NOUVEAUX MUSCLES MANQUANTS
-- ============================================

INSERT INTO muscle (name) VALUES
  ('Gastrocnémien'),
  ('Soléaire'),
  ('Tibial antérieur')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 2. AJOUTER TOUS LES EXERCICES MOLETS
-- ============================================

-- 🏋️ Exercices mollets – barre
SELECT add_exercise_if_not_exists('Standing Calf Raise (debout, barre sur les épaules)', 'Gastrocnémien', ARRAY['Gastrocnémien', 'Soléaire', 'Tibial antérieur']);
SELECT add_exercise_if_not_exists('Seated Calf Raise (assis, barre sur les cuisses)', 'Soléaire', ARRAY['Soléaire', 'Gastrocnémien']);

-- 🏋️‍♀️ Exercices mollets – haltères / kettlebells
SELECT add_exercise_if_not_exists('Standing Calf Raise haltères', 'Gastrocnémien', ARRAY['Gastrocnémien', 'Soléaire']);
SELECT add_exercise_if_not_exists('Seated Calf Raise haltères', 'Soléaire', ARRAY['Soléaire', 'Gastrocnémien']);

-- 🧱 Exercices mollets – machines
SELECT add_exercise_if_not_exists('Standing Calf Raise machine', 'Gastrocnémien', ARRAY['Gastrocnémien', 'Soléaire']);
SELECT add_exercise_if_not_exists('Seated Calf Raise machine', 'Soléaire', ARRAY['Soléaire', 'Gastrocnémien']);
SELECT add_exercise_if_not_exists('Leg Press Calf Raise', 'Gastrocnémien', ARRAY['Gastrocnémien', 'Soléaire', 'Tibial antérieur']);

-- 🧲 Exercices mollets – câbles / élastiques
SELECT add_exercise_if_not_exists('Calf Raise élastique / câble', 'Gastrocnémien', ARRAY['Gastrocnémien', 'Soléaire', 'Tibial antérieur']);

-- ============================================
-- NOTES
-- ============================================
-- Cette migration :
-- 1. Ajoute les nouveaux muscles manquants (Gastrocnémien, Soléaire, Tibial antérieur)
-- 2. Insère tous les exercices mollets avec leurs muscles associés
-- 3. Vérifie les doublons par nom (insensible à la casse et aux espaces)
-- 4. Associe automatiquement les muscles principaux et secondaires

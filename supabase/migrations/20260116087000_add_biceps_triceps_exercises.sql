-- ============================================
-- AJOUT D'EXERCICES BICEPS ET TRICEPS AVEC MUSCLES MULTIPLES
-- ============================================
-- Cette migration ajoute une série d'exercices biceps et triceps avec leurs muscles principaux et secondaires
-- Elle vérifie les doublons avant insertion

-- ============================================
-- 1. AJOUTER LES NOUVEAUX MUSCLES MANQUANTS
-- ============================================

INSERT INTO muscle (name) VALUES
  ('Brachial antérieur'),
  ('Avant-bras')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 2. AJOUTER TOUS LES EXERCICES BICEPS
-- ============================================

-- 🏋️ Exercices biceps – barre
SELECT add_exercise_if_not_exists('Curl barre (Barbell Curl)', 'Biceps', ARRAY['Biceps', 'Brachial antérieur', 'Avant-bras']);
SELECT add_exercise_if_not_exists('Curl barre EZ', 'Biceps', ARRAY['Biceps', 'Brachial antérieur', 'Avant-bras']);
SELECT add_exercise_if_not_exists('Curl prise marteau barre (Hammer Curl barre EZ)', 'Biceps', ARRAY['Biceps', 'Brachial antérieur', 'Avant-bras']);

-- 🏋️‍♀️ Exercices biceps – haltères / kettlebells
SELECT add_exercise_if_not_exists('Curl haltères alterné', 'Biceps', ARRAY['Biceps', 'Brachial antérieur', 'Avant-bras']);
SELECT add_exercise_if_not_exists('Curl marteau haltères', 'Biceps', ARRAY['Biceps', 'Brachial antérieur', 'Avant-bras']);
SELECT add_exercise_if_not_exists('Concentration curl', 'Biceps', ARRAY['Biceps', 'Avant-bras']);
SELECT add_exercise_if_not_exists('Curl incliné haltères', 'Biceps', ARRAY['Biceps', 'Brachial antérieur', 'Avant-bras']);

-- 🧱 Exercices biceps – machines
SELECT add_exercise_if_not_exists('Curl machine assis', 'Biceps', ARRAY['Biceps', 'Avant-bras']);
SELECT add_exercise_if_not_exists('Curl pupitre / preacher curl machine', 'Biceps', ARRAY['Biceps', 'Brachial antérieur']);

-- 🧲 Exercices biceps – câbles / élastiques
SELECT add_exercise_if_not_exists('Curl câble (debout)', 'Biceps', ARRAY['Biceps', 'Brachial antérieur', 'Avant-bras']);
SELECT add_exercise_if_not_exists('Curl câble prise marteau', 'Biceps', ARRAY['Biceps', 'Brachial antérieur', 'Avant-bras']);

-- ============================================
-- 3. AJOUTER TOUS LES EXERCICES TRICEPS
-- ============================================

-- 🏋️ Exercices triceps – barre
SELECT add_exercise_if_not_exists('Développé couché prise serrée', 'Triceps', ARRAY['Triceps', 'Deltoïdes antérieurs', 'Pectoraux']);
SELECT add_exercise_if_not_exists('Barre au front (Skull Crusher)', 'Triceps', ARRAY['Triceps', 'Avant-bras', 'Deltoïdes antérieurs']);

-- 🏋️‍♀️ Exercices triceps – haltères / kettlebells
SELECT add_exercise_if_not_exists('Extension triceps haltère derrière la tête (One-arm / deux mains)', 'Triceps', ARRAY['Triceps', 'Deltoïdes antérieurs', 'Avant-bras']);
SELECT add_exercise_if_not_exists('Kickback haltères', 'Triceps', ARRAY['Triceps', 'Deltoïdes postérieurs', 'Avant-bras']);

-- 🧱 Exercices triceps – machines
SELECT add_exercise_if_not_exists('Push-down poulie (câble)', 'Triceps', ARRAY['Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Extension triceps machine assis / couché', 'Triceps', ARRAY['Triceps', 'Deltoïdes antérieurs']);

-- 🧲 Exercices triceps – câbles / élastiques
SELECT add_exercise_if_not_exists('Push-down câble prise corde', 'Triceps', ARRAY['Triceps', 'Deltoïdes antérieurs', 'Avant-bras']);
SELECT add_exercise_if_not_exists('Extension triceps élastique derrière la tête', 'Triceps', ARRAY['Triceps', 'Deltoïdes antérieurs']);

-- ============================================
-- NOTES
-- ============================================
-- Cette migration :
-- 1. Ajoute les nouveaux muscles manquants (Brachial antérieur, Avant-bras)
-- 2. Insère tous les exercices biceps et triceps avec leurs muscles associés
-- 3. Vérifie les doublons par nom (insensible à la casse et aux espaces)
-- 4. Associe automatiquement les muscles principaux et secondaires

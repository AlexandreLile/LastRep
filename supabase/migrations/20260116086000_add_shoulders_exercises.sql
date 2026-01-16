-- ============================================
-- AJOUT D'EXERCICES ÉPAULES AVEC MUSCLES MULTIPLES
-- ============================================
-- Cette migration ajoute une série d'exercices épaules avec leurs muscles principaux et secondaires
-- Elle vérifie les doublons avant insertion

-- ============================================
-- 1. AJOUTER TOUS LES EXERCICES ÉPAULES
-- ============================================

-- 🏋️ Exercices épaules – barre
SELECT add_exercise_if_not_exists('Développé militaire barre (Overhead Press)', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Deltoïdes moyens', 'Trapèzes supérieurs', 'Triceps']);
SELECT add_exercise_if_not_exists('Développé nuque barre', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Deltoïdes moyens', 'Trapèzes supérieurs', 'Triceps']);
-- Note: Rowing menton barre existe déjà dans les exercices dos, sera ignoré par add_exercise_if_not_exists

-- 🏋️‍♀️ Exercices épaules – haltères / kettlebells
SELECT add_exercise_if_not_exists('Développé haltères assis', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Deltoïdes moyens', 'Trapèzes supérieurs', 'Triceps']);
SELECT add_exercise_if_not_exists('Développé haltères debout', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Deltoïdes moyens', 'Trapèzes supérieurs', 'Triceps']);
SELECT add_exercise_if_not_exists('Élévations latérales haltères', 'Deltoïdes moyens', ARRAY['Deltoïdes moyens', 'Trapèzes supérieurs', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Élévations frontales haltères', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Trapèzes supérieurs', 'Deltoïdes moyens']);
SELECT add_exercise_if_not_exists('Élévations postérieures / reverse fly', 'Deltoïdes postérieurs', ARRAY['Deltoïdes postérieurs', 'Trapèzes moyens', 'Trapèzes inférieurs', 'Rhomboïdes']);
SELECT add_exercise_if_not_exists('Arnold Press', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Deltoïdes moyens', 'Trapèzes supérieurs', 'Triceps']);

-- 🧱 Exercices épaules – machines
SELECT add_exercise_if_not_exists('Élévations latérales machine', 'Deltoïdes moyens', ARRAY['Deltoïdes moyens', 'Trapèzes supérieurs']);
SELECT add_exercise_if_not_exists('Développé machine assis', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Deltoïdes moyens', 'Trapèzes supérieurs', 'Triceps']);
SELECT add_exercise_if_not_exists('Élévations postérieures machine', 'Deltoïdes postérieurs', ARRAY['Deltoïdes postérieurs', 'Trapèzes moyens', 'Rhomboïdes']);

-- 🧲 Exercices épaules – câbles / élastiques
SELECT add_exercise_if_not_exists('Élévations latérales câble', 'Deltoïdes moyens', ARRAY['Deltoïdes moyens', 'Trapèzes supérieurs']);
SELECT add_exercise_if_not_exists('Élévations frontales câble', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Trapèzes supérieurs']);
-- Note: Face Pull existe déjà dans les exercices dos, sera ignoré par add_exercise_if_not_exists
SELECT add_exercise_if_not_exists('Oiseau / reverse fly câble', 'Deltoïdes postérieurs', ARRAY['Deltoïdes postérieurs', 'Trapèzes moyens', 'Trapèzes inférieurs', 'Rhomboïdes']);

-- ============================================
-- NOTES
-- ============================================
-- Cette migration :
-- 1. Insère tous les exercices épaules avec leurs muscles associés
-- 2. Vérifie les doublons par nom (insensible à la casse et aux espaces)
-- 3. Associe automatiquement les muscles principaux et secondaires
-- 4. Certains exercices peuvent déjà exister (comme Rowing menton barre, Face Pull) mais seront ignorés grâce à la vérification de doublon

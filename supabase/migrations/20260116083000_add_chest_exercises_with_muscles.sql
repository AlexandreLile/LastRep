-- ============================================
-- AJOUT D'EXERCICES PECTORAUX AVEC MUSCLES MULTIPLES
-- ============================================
-- Cette migration ajoute une série d'exercices pectoraux avec leurs muscles principaux et secondaires
-- Elle vérifie les doublons avant insertion

-- ============================================
-- 1. AJOUTER LES NOUVEAUX MUSCLES MANQUANTS
-- ============================================

INSERT INTO muscle (name) VALUES
  ('Pectoraux supérieurs'),
  ('Pectoraux inférieurs'),
  ('Deltoïdes antérieurs')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 2. AJOUTER TOUS LES EXERCICES PECTORAUX
-- ============================================

-- 🏋️ Exercices pectoraux – barre
SELECT add_exercise_if_not_exists('Développé couché barre (Bench Press)', 'Pectoraux', ARRAY['Pectoraux', 'Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Développé incliné barre', 'Pectoraux supérieurs', ARRAY['Pectoraux supérieurs', 'Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Développé décliné barre', 'Pectoraux inférieurs', ARRAY['Pectoraux inférieurs', 'Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Écarté couché barre (ou pec deck sur barre)', 'Pectoraux', ARRAY['Pectoraux', 'Deltoïdes antérieurs', 'Biceps']);

-- 🏋️‍♀️ Exercices pectoraux – haltères / kettlebells
SELECT add_exercise_if_not_exists('Développé couché haltères', 'Pectoraux', ARRAY['Pectoraux', 'Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Développé incliné haltères', 'Pectoraux supérieurs', ARRAY['Pectoraux supérieurs', 'Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Développé décliné haltères', 'Pectoraux inférieurs', ARRAY['Pectoraux inférieurs', 'Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Écarté couché haltères', 'Pectoraux', ARRAY['Pectoraux', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Pullover haltère', 'Pectoraux', ARRAY['Pectoraux', 'Dorsaux', 'Triceps', 'Deltoïdes antérieurs']);

-- 🧱 Exercices pectoraux – machines
SELECT add_exercise_if_not_exists('Pec Deck (machine écarté)', 'Pectoraux', ARRAY['Pectoraux', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Développé assis machine', 'Pectoraux', ARRAY['Pectoraux', 'Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Développé incliné machine', 'Pectoraux supérieurs', ARRAY['Pectoraux supérieurs', 'Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Développé décliné machine', 'Pectoraux inférieurs', ARRAY['Pectoraux inférieurs', 'Triceps', 'Deltoïdes antérieurs']);

-- 🧲 Exercices pectoraux – câbles / élastiques
SELECT add_exercise_if_not_exists('Écarté câbles (câbles croisés)', 'Pectoraux', ARRAY['Pectoraux', 'Deltoïdes antérieurs', 'Biceps']);
SELECT add_exercise_if_not_exists('Développé câbles', 'Pectoraux', ARRAY['Pectoraux', 'Triceps', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Écarté incliné câbles', 'Pectoraux supérieurs', ARRAY['Pectoraux supérieurs', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Écarté décliné câbles', 'Pectoraux inférieurs', ARRAY['Pectoraux inférieurs', 'Deltoïdes antérieurs']);

-- ============================================
-- NOTES
-- ============================================
-- Cette migration :
-- 1. Ajoute les nouveaux muscles manquants (Pectoraux supérieurs, Pectoraux inférieurs, Deltoïdes antérieurs)
-- 2. Insère tous les exercices pectoraux avec leurs muscles associés
-- 3. Vérifie les doublons par nom (insensible à la casse et aux espaces)
-- 4. Associe automatiquement les muscles principaux et secondaires

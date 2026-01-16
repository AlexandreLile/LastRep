-- ============================================
-- AJOUT DE L'EXERCICE "DIPS LESTÉS"
-- ============================================
-- Cet exercice cible principalement les triceps
-- avec les pectoraux et deltoïdes antérieurs comme muscles secondaires

-- Ajouter l'exercice Dips lestés
SELECT add_exercise_if_not_exists(
  'Dips lestés',
  'Triceps',
  ARRAY['Triceps', 'Pectoraux', 'Deltoïdes antérieurs']
);

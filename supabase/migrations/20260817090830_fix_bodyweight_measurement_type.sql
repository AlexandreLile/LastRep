-- Les exercices "Poids du corps" importés de WorkoutX étaient en
-- measurement_type = 'weight_reps' (poids traité comme pour un exercice
-- avec charge). On aligne sur le comportement historique des anciens
-- exercices bodyweight (tractions, pompes...) : reps obligatoire, poids
-- optionnel (pour le lestage, ex. gilet lesté).

UPDATE exercise
SET measurement_type = 'reps'
WHERE equipment = 'Poids du corps'
  AND is_legacy = false
  AND is_custom = false
  AND measurement_type = 'weight_reps';

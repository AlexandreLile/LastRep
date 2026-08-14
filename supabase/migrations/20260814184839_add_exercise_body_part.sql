-- ============================================
-- CATÉGORIE CORPORELLE (filtre de recherche)
-- ============================================
-- Catégorie large (Dos, Poitrine, Épaules, Jambes...) utilisée pour les chips
-- de filtre dans le sélecteur d'exercices. Beaucoup plus lisible que la liste
-- complète des muscles (~40 entrées, souvent trop fines pour naviguer).
-- Alimentée depuis le champ `bodyPart` de l'API WorkoutX (10 valeurs).

ALTER TABLE exercise
ADD COLUMN IF NOT EXISTS body_part TEXT;

CREATE INDEX IF NOT EXISTS idx_exercise_body_part ON exercise(body_part);

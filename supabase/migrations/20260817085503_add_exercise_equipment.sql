-- Ajoute l'équipement précis WorkoutX (ex: "Câble", "Haltère", "Kettlebell",
-- "Poids du corps"...), jusqu'ici traduit en category_id (7 valeurs
-- grossières seulement) puis jeté à l'import. Permet des filtres plus fins
-- côté catalogue sans casser l'existant.

ALTER TABLE exercise
ADD COLUMN IF NOT EXISTS equipment TEXT;

-- Muscles nécessaires pour mapper la taxonomie WorkoutX (target),
-- absents de la liste actuelle : Abducteurs (déjà ajouté précédemment),
-- Élévateur de la scapula (Levator Scapulae), Dentelé antérieur (Serratus Anterior)

INSERT INTO muscle (name) VALUES
  ('Abducteurs'),
  ('Cou'),
  ('Élévateur de la scapula'),
  ('Dentelé antérieur')
ON CONFLICT (name) DO NOTHING;

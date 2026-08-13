-- ============================================
-- BIBLIOTHÈQUE DE SÉANCES MODÈLES
-- ============================================
-- Séances pré-construites par l'équipe LastRep, consultables par tous les
-- utilisateurs connectés et ajoutables directement à leurs propres séances
-- (copiées dans workoutsession / workoutexercise à l'ajout).

CREATE TABLE IF NOT EXISTS session_template (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL UNIQUE,
  description TEXT,
  category TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS session_template_exercise (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES session_template(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercise(id) ON DELETE CASCADE,
  "order" INTEGER NOT NULL DEFAULT 1,
  target_sets INTEGER,
  target_reps TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_session_template_exercise_template_id ON session_template_exercise(template_id);
CREATE INDEX IF NOT EXISTS idx_session_template_exercise_exercise_id ON session_template_exercise(exercise_id);

ALTER TABLE session_template ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_template_exercise ENABLE ROW LEVEL SECURITY;

-- Lecture publique pour les utilisateurs connectés : ce sont des modèles partagés,
-- pas des données appartenant à un utilisateur. Aucune policy INSERT/UPDATE/DELETE :
-- le contenu de la bibliothèque est géré uniquement via migrations (ou service role).
CREATE POLICY "Authenticated users can view session templates"
  ON public.session_template
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can view session template exercises"
  ON public.session_template_exercise
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- Contenu initial de la bibliothèque
-- ============================================

DO $$
DECLARE
  v_template_id UUID;
BEGIN
  -- 1. Full Body Débutant
  INSERT INTO session_template (title, description, category)
  VALUES ('Full Body Débutant', 'Une séance complète pour travailler tout le corps en une fois, idéale pour débuter.', 'Full Body')
  ON CONFLICT (title) DO NOTHING
  RETURNING id INTO v_template_id;

  IF v_template_id IS NOT NULL THEN
    INSERT INTO session_template_exercise (template_id, exercise_id, "order", target_sets, target_reps)
    SELECT v_template_id, e.id, x.ord, x.sets, x.reps
    FROM (VALUES
      ('Squat back squat', 1, 4, '8-10'),
      ('Développé couché barre (Bench Press)', 2, 4, '8-10'),
      ('Rowing barre (Barbell Row)', 3, 3, '10-12'),
      ('Développé militaire barre (Overhead Press)', 4, 3, '8-10'),
      ('Curl barre (Barbell Curl)', 5, 3, '10-12')
    ) AS x(name, ord, sets, reps)
    JOIN exercise e ON e.name = x.name AND e.is_custom = false;
  END IF;

  -- 2. Push (Pecs / Épaules / Triceps)
  INSERT INTO session_template (title, description, category)
  VALUES ('Push — Pecs, Épaules, Triceps', 'Séance poussée classique pour développer le haut du corps.', 'Push')
  ON CONFLICT (title) DO NOTHING
  RETURNING id INTO v_template_id;

  IF v_template_id IS NOT NULL THEN
    INSERT INTO session_template_exercise (template_id, exercise_id, "order", target_sets, target_reps)
    SELECT v_template_id, e.id, x.ord, x.sets, x.reps
    FROM (VALUES
      ('Développé couché barre (Bench Press)', 1, 4, '8-10'),
      ('Développé incliné haltères', 2, 3, '10-12'),
      ('Développé militaire barre (Overhead Press)', 3, 3, '8-10'),
      ('Élévations latérales haltères', 4, 3, '12-15'),
      ('Push-down câble prise corde', 5, 3, '12-15')
    ) AS x(name, ord, sets, reps)
    JOIN exercise e ON e.name = x.name AND e.is_custom = false;
  END IF;

  -- 3. Pull (Dos / Biceps)
  INSERT INTO session_template (title, description, category)
  VALUES ('Pull — Dos, Biceps', 'Séance tirage classique pour développer le dos et les bras.', 'Pull')
  ON CONFLICT (title) DO NOTHING
  RETURNING id INTO v_template_id;

  IF v_template_id IS NOT NULL THEN
    INSERT INTO session_template_exercise (template_id, exercise_id, "order", target_sets, target_reps)
    SELECT v_template_id, e.id, x.ord, x.sets, x.reps
    FROM (VALUES
      ('Traction pronation barre (Pull-up)', 1, 4, '6-10'),
      ('Rowing barre (Barbell Row)', 2, 4, '8-10'),
      ('Tirage poitrine (Lat Pulldown)', 3, 3, '10-12'),
      ('Curl barre (Barbell Curl)', 4, 3, '10-12'),
      ('Curl marteau haltères', 5, 3, '10-12')
    ) AS x(name, ord, sets, reps)
    JOIN exercise e ON e.name = x.name AND e.is_custom = false;
  END IF;

  -- 4. Jambes complet
  INSERT INTO session_template (title, description, category)
  VALUES ('Jambes complet', 'Séance jambes complète : quadriceps, ischio-jambiers, fessiers et mollets.', 'Jambes')
  ON CONFLICT (title) DO NOTHING
  RETURNING id INTO v_template_id;

  IF v_template_id IS NOT NULL THEN
    INSERT INTO session_template_exercise (template_id, exercise_id, "order", target_sets, target_reps)
    SELECT v_template_id, e.id, x.ord, x.sets, x.reps
    FROM (VALUES
      ('Squat back squat', 1, 4, '8-10'),
      ('Leg Press (pieds bas)', 2, 3, '10-12'),
      ('Leg Curl (assis / allongé)', 3, 3, '12-15'),
      ('Leg Extension (quad machine)', 4, 3, '12-15'),
      ('Hip Thrust barre', 5, 3, '10-12'),
      ('Calf Raise élastique / câble', 6, 4, '15-20')
    ) AS x(name, ord, sets, reps)
    JOIN exercise e ON e.name = x.name AND e.is_custom = false;
  END IF;
END $$;

-- ============================================
-- RESTAURATION DES EXERCICES ET MUSCLES
-- ============================================
-- Cette migration restaure tous les exercices et muscles qui ont été supprimés
-- Elle recrée les muscles de base puis tous les exercices détaillés

-- ============================================
-- 1. RECRÉER LES MUSCLES DE BASE
-- ============================================

INSERT INTO muscle (name) VALUES
  ('Pectoraux'),
  ('Dorsaux'),
  ('Épaules'),
  ('Biceps'),
  ('Triceps'),
  ('Jambes'),
  ('Fessiers'),
  ('Mollets'),
  ('Abdominaux'),
  ('Cardio'),
  ('Autre'),
  -- Muscles détaillés
  ('Ischio-jambiers'),
  ('Quadriceps'),
  ('Adducteurs'),
  ('Lombaires'),
  ('Trapèzes'),
  ('Fessiers moyens'),
  ('Petit fessier'),
  ('Grand dorsal'),
  ('Rhomboïdes'),
  ('Deltoïdes postérieurs'),
  ('Deltoïdes moyens'),
  ('Trapèzes supérieurs'),
  ('Trapèzes moyens'),
  ('Trapèzes inférieurs'),
  ('Érecteurs du rachis'),
  ('Pectoraux supérieurs'),
  ('Pectoraux inférieurs'),
  ('Deltoïdes antérieurs'),
  ('Brachial antérieur'),
  ('Avant-bras'),
  ('Gastrocnémien'),
  ('Soléaire'),
  ('Tibial antérieur'),
  ('Grand droit'),
  ('Obliques'),
  ('Transverse'),
  ('Fléchisseurs de hanche')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 2. S'ASSURER QUE LA FONCTION add_exercise_if_not_exists EXISTE
-- ============================================
-- La fonction devrait déjà exister depuis les migrations précédentes
-- Mais on la recrée au cas où

CREATE OR REPLACE FUNCTION add_exercise_if_not_exists(
  p_name VARCHAR(255),
  p_primary_muscle VARCHAR(50),
  p_muscles VARCHAR(50)[] DEFAULT NULL,
  p_measurement_type VARCHAR(20) DEFAULT 'weight_reps',
  p_is_custom BOOLEAN DEFAULT false,
  p_user_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  exercise_uuid UUID;
  muscle_name VARCHAR(50);
  muscle_id_val INTEGER;
  is_first BOOLEAN;
BEGIN
  -- Vérifier si l'exercice existe déjà
  SELECT id INTO exercise_uuid
  FROM exercise
  WHERE LOWER(TRIM(name)) = LOWER(TRIM(p_name))
  LIMIT 1;

  -- Si l'exercice existe déjà, retourner son ID
  IF exercise_uuid IS NOT NULL THEN
    RETURN exercise_uuid;
  END IF;

  -- Créer l'exercice
  INSERT INTO exercise (
    name,
    primary_muscle,
    measurement_type,
    is_custom,
    user_id
  ) VALUES (
    TRIM(p_name),
    p_primary_muscle,
    p_measurement_type,
    p_is_custom,
    p_user_id
  )
  RETURNING id INTO exercise_uuid;

  -- Si des muscles supplémentaires sont fournis, les utiliser
  -- Sinon, utiliser seulement le muscle principal
  IF p_muscles IS NOT NULL AND array_length(p_muscles, 1) > 0 THEN
    is_first := true;
    
    -- Ajouter chaque muscle
    FOREACH muscle_name IN ARRAY p_muscles
    LOOP
      -- Récupérer l'ID du muscle
      SELECT id INTO muscle_id_val
      FROM muscle
      WHERE name = muscle_name;
      
      -- Si le muscle existe, créer l'association
      IF muscle_id_val IS NOT NULL THEN
        INSERT INTO exercise_muscle (exercise_id, muscle_id, is_primary)
        VALUES (exercise_uuid, muscle_id_val, is_first)
        ON CONFLICT (exercise_id, muscle_id) DO NOTHING;
        
        is_first := false; -- Seul le premier est principal
      END IF;
    END LOOP;
  ELSE
    -- Si aucun muscle supplémentaire, ajouter seulement le muscle principal
    SELECT id INTO muscle_id_val
    FROM muscle
    WHERE name = p_primary_muscle;
    
    IF muscle_id_val IS NOT NULL THEN
      INSERT INTO exercise_muscle (exercise_id, muscle_id, is_primary)
      VALUES (exercise_uuid, muscle_id_val, true)
      ON CONFLICT (exercise_id, muscle_id) DO NOTHING;
    END IF;
  END IF;

  RETURN exercise_uuid;
END;
$$;

-- ============================================
-- 3. RESTAURER TOUS LES EXERCICES
-- ============================================

-- 🏋️ Exercices fessiers – barre
SELECT add_exercise_if_not_exists('Hip Thrust barre', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Squat back squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Squat front squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Adducteurs', 'Abdominaux', 'Dorsaux']);
SELECT add_exercise_if_not_exists('Squat sumo barre', 'Fessiers', ARRAY['Fessiers', 'Adducteurs', 'Quadriceps', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift conventionnel', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Quadriceps', 'Trapèzes', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift sumo', 'Fessiers', ARRAY['Fessiers', 'Adducteurs', 'Ischio-jambiers', 'Quadriceps', 'Lombaires']);
SELECT add_exercise_if_not_exists('Romanian Deadlift (RDL)', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Good Morning', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Split squat barre', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);

-- 🏋️‍♀️ Exercices fessiers – haltères / kettlebells
SELECT add_exercise_if_not_exists('Hip Thrust haltères', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Goblet squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Bulgarian Split Squat haltères', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Romanian Deadlift haltères', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift kettlebell', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Quadriceps', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Step-up haltères', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Mollets', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Fentes marchées haltères', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Fentes arrière haltères', 'Fessiers', ARRAY['Fessiers', 'Quadriceps', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);

-- 🧱 Exercices fessiers – machines
SELECT add_exercise_if_not_exists('Hip Thrust machine', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps']);
SELECT add_exercise_if_not_exists('Glute Kickback machine', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Abduction machine (assis)', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier']);
SELECT add_exercise_if_not_exists('Abduction machine debout', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Leg Press (pieds hauts / larges)', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps', 'Adducteurs']);
SELECT add_exercise_if_not_exists('Smith Machine Squat', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Smith Machine Hip Thrust', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps']);

-- 🧲 Exercices fessiers – câbles / élastiques
SELECT add_exercise_if_not_exists('Kickback câble', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Pull-through câble', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Lombaires', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Abduction câble', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Hip Thrust élastique', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Quadriceps']);
SELECT add_exercise_if_not_exists('Glute Bridge élastique', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Monster Walk (élastique)', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier', 'Quadriceps']);
SELECT add_exercise_if_not_exists('Lateral Walk (élastique)', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Petit fessier', 'Abdominaux']);

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

-- 🏋️ Exercices dos – barre
SELECT add_exercise_if_not_exists('Deadlift barre', 'Érecteurs du rachis', ARRAY['Érecteurs du rachis', 'Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Fessiers', 'Ischio-jambiers', 'Biceps']);
SELECT add_exercise_if_not_exists('Rowing barre (Barbell Row)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps', 'Lombaires']);
SELECT add_exercise_if_not_exists('Tirage menton barre (Upright Row)', 'Trapèzes', ARRAY['Trapèzes', 'Deltoïdes postérieurs', 'Deltoïdes moyens', 'Biceps']);
SELECT add_exercise_if_not_exists('Traction pronation barre (Pull-up)', 'Grand dorsal', ARRAY['Grand dorsal', 'Biceps', 'Trapèzes moyens', 'Trapèzes inférieurs', 'Rhomboïdes', 'Deltoïdes postérieurs']);
SELECT add_exercise_if_not_exists('Traction supination barre (Chin-up)', 'Grand dorsal', ARRAY['Grand dorsal', 'Biceps', 'Trapèzes moyens', 'Trapèzes inférieurs', 'Rhomboïdes']);

-- 🏋️‍♀️ Exercices dos – haltères / kettlebells
SELECT add_exercise_if_not_exists('Rowing haltère unilatéral (One-arm Dumbbell Row)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps']);
SELECT add_exercise_if_not_exists('Rowing haltères simultané (Bent-over Dumbbell Row)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps']);
SELECT add_exercise_if_not_exists('Shrugs haltères', 'Trapèzes supérieurs', ARRAY['Trapèzes supérieurs', 'Deltoïdes postérieurs']);
SELECT add_exercise_if_not_exists('Pull-over haltère', 'Grand dorsal', ARRAY['Grand dorsal', 'Pectoraux', 'Triceps']);

-- 🧱 Exercices dos – machines
SELECT add_exercise_if_not_exists('Tirage poitrine (Lat Pulldown)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Tirage nuque (Lat Pulldown derrière)', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Rowing assis machine', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps']);
SELECT add_exercise_if_not_exists('Pull-over machine', 'Grand dorsal', ARRAY['Grand dorsal', 'Pectoraux', 'Triceps']);

-- 🧲 Exercices dos – câbles / élastiques
SELECT add_exercise_if_not_exists('Tirage câble poitrine', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Tirage câble nuque', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Rowing câble assis', 'Grand dorsal', ARRAY['Grand dorsal', 'Trapèzes', 'Rhomboïdes', 'Deltoïdes postérieurs', 'Biceps']);
SELECT add_exercise_if_not_exists('Face pull (câble)', 'Deltoïdes postérieurs', ARRAY['Deltoïdes postérieurs', 'Trapèzes', 'Rhomboïdes', 'Biceps']);
SELECT add_exercise_if_not_exists('Pull-through élastique', 'Érecteurs du rachis', ARRAY['Érecteurs du rachis', 'Fessiers', 'Ischio-jambiers', 'Grand dorsal']);

-- 🏋️ Exercices quadriceps – barre
SELECT add_exercise_if_not_exists('Split squat barre', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift barre', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Trapèzes', 'Biceps', 'Quadriceps']);

-- 🏋️‍♀️ Exercices quadriceps – haltères / kettlebells
SELECT add_exercise_if_not_exists('Bulgarian Split Squat haltères', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers', 'Adducteurs', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Deadlift kettlebell / RDL haltères', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers', 'Lombaires', 'Quadriceps']);

-- 🧱 Exercices quadriceps / ischio – machines
SELECT add_exercise_if_not_exists('Leg Press (pieds bas)', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers']);
SELECT add_exercise_if_not_exists('Leg Extension (quad machine)', 'Quadriceps', ARRAY['Quadriceps']);
SELECT add_exercise_if_not_exists('Leg Curl (assis / allongé)', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers']);
SELECT add_exercise_if_not_exists('Hack Squat machine', 'Quadriceps', ARRAY['Quadriceps', 'Fessiers', 'Ischio-jambiers']);

-- 🧲 Exercices quadriceps / ischio – câbles / élastiques
SELECT add_exercise_if_not_exists('Kickback élastique / câble', 'Fessiers', ARRAY['Fessiers', 'Ischio-jambiers', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Monster Walk / Lateral Walk élastique', 'Fessiers moyens', ARRAY['Fessiers moyens', 'Quadriceps', 'Petit fessier', 'Abdominaux']);
SELECT add_exercise_if_not_exists('Leg Curl élastique', 'Ischio-jambiers', ARRAY['Ischio-jambiers', 'Fessiers']);

-- 🏋️ Exercices épaules – barre
SELECT add_exercise_if_not_exists('Développé militaire barre (Overhead Press)', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Deltoïdes moyens', 'Trapèzes supérieurs', 'Triceps']);
SELECT add_exercise_if_not_exists('Développé nuque barre', 'Deltoïdes antérieurs', ARRAY['Deltoïdes antérieurs', 'Deltoïdes moyens', 'Trapèzes supérieurs', 'Triceps']);

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
SELECT add_exercise_if_not_exists('Oiseau / reverse fly câble', 'Deltoïdes postérieurs', ARRAY['Deltoïdes postérieurs', 'Trapèzes moyens', 'Trapèzes inférieurs', 'Rhomboïdes']);

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

-- 🏋️‍♀️ Exercices abdos – haltères / kettlebells
SELECT add_exercise_if_not_exists('Russian Twist avec haltère / kettlebell', 'Obliques', ARRAY['Obliques', 'Grand droit', 'Transverse', 'Lombaires']);
SELECT add_exercise_if_not_exists('Sit-up avec poids', 'Grand droit', ARRAY['Grand droit', 'Obliques', 'Transverse', 'Fléchisseurs de hanche']);
SELECT add_exercise_if_not_exists('Weighted Leg Raise', 'Grand droit', ARRAY['Grand droit', 'Fléchisseurs de hanche', 'Obliques']);

-- 🧱 Exercices abdos – machines
SELECT add_exercise_if_not_exists('Crunch machine', 'Grand droit', ARRAY['Grand droit', 'Obliques', 'Transverse']);
SELECT add_exercise_if_not_exists('Roman Chair / Hyperextension', 'Lombaires', ARRAY['Lombaires', 'Fessiers', 'Grand droit', 'Obliques']);
SELECT add_exercise_if_not_exists('Twist machine', 'Obliques', ARRAY['Obliques', 'Grand droit', 'Transverse']);

-- 🧲 Exercices abdos – câbles / élastiques
SELECT add_exercise_if_not_exists('Cable Crunch', 'Grand droit', ARRAY['Grand droit', 'Obliques', 'Transverse']);
SELECT add_exercise_if_not_exists('Woodchopper (câble)', 'Obliques', ARRAY['Obliques', 'Grand droit', 'Transverse', 'Deltoïdes antérieurs']);
SELECT add_exercise_if_not_exists('Pallof Press (câble)', 'Transverse', ARRAY['Transverse', 'Grand droit', 'Obliques', 'Deltoïdes antérieurs', 'Lombaires']);

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
-- 4. VÉRIFICATION
-- ============================================

DO $$
DECLARE
  exercise_count INTEGER;
  muscle_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO exercise_count FROM exercise;
  SELECT COUNT(*) INTO muscle_count FROM muscle;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RESTAURATION TERMINÉE';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Exercices restaurés: %', exercise_count;
  RAISE NOTICE 'Muscles disponibles: %', muscle_count;
  RAISE NOTICE '========================================';
END $$;

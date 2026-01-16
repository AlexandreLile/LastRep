-- ============================================
-- GÉNÉRATION DE DONNÉES DE TEST
-- ============================================
-- User ID: 9af8cb22-9196-4616-bea9-5fafc0b48af7
-- 
-- 1. Créer 3 séances Push, Pull, Legs avec 4 exercices chacune
-- 2. Générer 20 séances effectuées en décembre 2025
-- 3. Générer 14 séances entre le 1er et le 16 janvier 2026
-- 4. La semaine du 12 janvier (12-16 janvier) doit avoir au moins 4 séances

-- ============================================
-- 1. CRÉER LES 3 SÉANCES (workoutsession)
-- ============================================

INSERT INTO workoutsession (id, title, user_id, created_at, date, updated_at)
VALUES 
  (gen_random_uuid(), 'Push', '9af8cb22-9196-4616-bea9-5fafc0b48af7', NOW(), CURRENT_DATE, NOW()),
  (gen_random_uuid(), 'Pull', '9af8cb22-9196-4616-bea9-5fafc0b48af7', NOW(), CURRENT_DATE, NOW()),
  (gen_random_uuid(), 'Legs', '9af8cb22-9196-4616-bea9-5fafc0b48af7', NOW(), CURRENT_DATE, NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 2. AJOUTER LES EXERCICES AUX SÉANCES
-- ============================================

-- Push session (4 exercices)
INSERT INTO workoutexercise (id, session_id, exercise_id, "order", created_at, updated_at)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM workoutsession WHERE title = 'Push' AND user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' LIMIT 1),
  e.id,
  row_number() OVER (ORDER BY e.name),
  NOW(),
  NOW()
FROM exercise e
WHERE LOWER(TRIM(e.name)) IN (
  LOWER('Développé couché barre (Bench Press)'),
  LOWER('Développé incliné barre'),
  LOWER('Dips lestés'),
  LOWER('Extension triceps haltère derrière la tête (One-arm / deux mains)')
)
LIMIT 4
ON CONFLICT DO NOTHING;

-- Pull session (4 exercices)
INSERT INTO workoutexercise (id, session_id, exercise_id, "order", created_at, updated_at)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM workoutsession WHERE title = 'Pull' AND user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' LIMIT 1),
  e.id,
  row_number() OVER (ORDER BY e.name),
  NOW(),
  NOW()
FROM exercise e
WHERE LOWER(TRIM(e.name)) IN (
  LOWER('Rowing barre (Barbell Row)'),
  LOWER('Tirage poitrine (Lat Pulldown)'),
  LOWER('Curl barre (Barbell Curl)'),
  LOWER('Face pull (câble)')
)
LIMIT 4
ON CONFLICT DO NOTHING;

-- Legs session (4 exercices)
INSERT INTO workoutexercise (id, session_id, exercise_id, "order", created_at, updated_at)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM workoutsession WHERE title = 'Legs' AND user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' LIMIT 1),
  e.id,
  row_number() OVER (ORDER BY e.name),
  NOW(),
  NOW()
FROM exercise e
WHERE LOWER(TRIM(e.name)) IN (
  LOWER('Squat back squat'),
  LOWER('Leg Press (pieds bas)'),
  LOWER('Leg Curl (assis / allongé)'),
  LOWER('Hip Thrust barre')
)
LIMIT 4
ON CONFLICT DO NOTHING;

-- ============================================
-- 3. FONCTION HELPER POUR GÉNÉRER UNE SÉANCE
-- ============================================

CREATE OR REPLACE FUNCTION generate_performed_session(
  p_user_id UUID,
  p_workout_session_id UUID,
  p_start_time TIMESTAMP,
  p_duration_minutes INTEGER
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  performed_id UUID;
  session_end TIMESTAMP;
  current_exercise_id UUID;
  set_id UUID;
  j INTEGER;
  k INTEGER;
  num_sets INTEGER;
  weight_val NUMERIC;
  reps_val INTEGER;
  exercise_name TEXT;
BEGIN
  performed_id := gen_random_uuid();
  session_end := p_start_time + (p_duration_minutes * INTERVAL '1 minute');
  
  -- Créer la séance effectuée
  INSERT INTO performedsession (id, user_id, workout_session_id, started_at, ended_at, created_at)
  VALUES (performed_id, p_user_id, p_workout_session_id, p_start_time, session_end, p_start_time)
  ON CONFLICT (id) DO NOTHING;
  
  -- Pour chaque exercice de la séance
  FOR j IN 1..4 LOOP
    SELECT exercise_id INTO current_exercise_id
    FROM workoutexercise
    WHERE session_id = p_workout_session_id AND "order" = j
    LIMIT 1;
    
    IF current_exercise_id IS NOT NULL THEN
      -- Récupérer le nom de l'exercice pour déterminer le poids
      SELECT name INTO exercise_name FROM exercise WHERE id = current_exercise_id;
      
      -- Générer 3-4 séries
      num_sets := 3 + (RANDOM() * 2)::INTEGER;
      
      FOR k IN 1..num_sets LOOP
        -- Déterminer le poids selon le type d'exercice
        IF exercise_name LIKE '%Squat%' OR exercise_name LIKE '%Leg Press%' OR exercise_name LIKE '%Hip Thrust%' THEN
          weight_val := 80 + (RANDOM() * 40);
        ELSIF exercise_name LIKE '%Développé%' OR exercise_name LIKE '%Rowing%' THEN
          weight_val := 60 + (RANDOM() * 30);
        ELSIF exercise_name LIKE '%Curl%' OR exercise_name LIKE '%Extension%' OR exercise_name LIKE '%Face pull%' THEN
          weight_val := 15 + (RANDOM() * 15);
        ELSIF exercise_name LIKE '%Dips%' THEN
          weight_val := 0 + (RANDOM() * 30);
        ELSE
          weight_val := 50 + (RANDOM() * 30);
        END IF;
        
        reps_val := 6 + (RANDOM() * 6)::INTEGER;
        set_id := gen_random_uuid();
        
        INSERT INTO exerciseset (
          id, exercise_id, user_id, weight_kg, reps, rest_seconds, 
          performed_session_id, created_at
        )
        VALUES (
          set_id,
          current_exercise_id,
          p_user_id,
          ROUND(weight_val::NUMERIC, 1),
          reps_val,
          90 + (RANDOM() * 90)::INTEGER,
          performed_id,
          p_start_time + (j * 15 + k * 3)::INTEGER * INTERVAL '1 minute'
        )
        ON CONFLICT (id) DO NOTHING;
      END LOOP;
    END IF;
  END LOOP;
  
  RETURN performed_id;
END;
$$;

-- ============================================
-- 4. GÉNÉRER 20 SÉANCES EN DÉCEMBRE 2025
-- ============================================

DO $$
DECLARE
  i INTEGER;
  session_date DATE;
  session_start TIMESTAMP;
  session_type TEXT;
  workout_id UUID;
  push_id UUID;
  pull_id UUID;
  legs_id UUID;
BEGIN
  -- Récupérer les IDs des sessions
  SELECT id INTO push_id FROM workoutsession WHERE title = 'Push' AND user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' LIMIT 1;
  SELECT id INTO pull_id FROM workoutsession WHERE title = 'Pull' AND user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' LIMIT 1;
  SELECT id INTO legs_id FROM workoutsession WHERE title = 'Legs' AND user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' LIMIT 1;
  
  FOR i IN 1..20 LOOP
    -- Date aléatoire en décembre 2025
    session_date := '2025-12-01'::DATE + (RANDOM() * 30)::INTEGER;
    session_start := (session_date + (8 + RANDOM() * 12)::INTEGER * INTERVAL '1 hour')::TIMESTAMP;
    
    -- Alterner entre Push, Pull, Legs
    session_type := CASE (i % 3)
      WHEN 0 THEN 'push'
      WHEN 1 THEN 'pull'
      ELSE 'legs'
    END;
    
    workout_id := CASE session_type
      WHEN 'push' THEN push_id
      WHEN 'pull' THEN pull_id
      ELSE legs_id
    END;
    
    PERFORM generate_performed_session(
      '9af8cb22-9196-4616-bea9-5fafc0b48af7',
      workout_id,
      session_start,
      60 + (RANDOM() * 60)::INTEGER -- Durée entre 60 et 120 minutes
    );
  END LOOP;
END $$;

-- ============================================
-- 5. GÉNÉRER 14 SÉANCES ENTRE LE 1ER ET LE 16 JANVIER 2026
-- ============================================

DO $$
DECLARE
  i INTEGER;
  session_date DATE;
  session_start TIMESTAMP;
  session_type TEXT;
  workout_id UUID;
  push_id UUID;
  pull_id UUID;
  legs_id UUID;
  dates_array DATE[] := ARRAY[
    '2026-01-01', '2026-01-02', '2026-01-03', '2026-01-04', '2026-01-05',
    '2026-01-06', '2026-01-07', '2026-01-08', '2026-01-09', '2026-01-10',
    '2026-01-11', '2026-01-12', '2026-01-13', '2026-01-14', '2026-01-15', '2026-01-16'
  ];
  selected_dates DATE[] := ARRAY[
    '2026-01-12', '2026-01-13', '2026-01-14', '2026-01-15' -- Semaine du 12 janvier (4 séances minimum)
  ];
  date_idx INTEGER;
BEGIN
  -- Récupérer les IDs des sessions
  SELECT id INTO push_id FROM workoutsession WHERE title = 'Push' AND user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' LIMIT 1;
  SELECT id INTO pull_id FROM workoutsession WHERE title = 'Pull' AND user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' LIMIT 1;
  SELECT id INTO legs_id FROM workoutsession WHERE title = 'Legs' AND user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' LIMIT 1;
  
  -- Ajouter 10 autres dates aléatoires
  WHILE array_length(selected_dates, 1) < 14 LOOP
    date_idx := 1 + (RANDOM() * 15)::INTEGER;
    IF dates_array[date_idx] NOT IN (SELECT unnest(selected_dates)) THEN
      selected_dates := array_append(selected_dates, dates_array[date_idx]);
    END IF;
  END LOOP;
  
  -- Générer les 14 séances
  FOR i IN 1..14 LOOP
    session_date := selected_dates[i];
    session_start := (session_date + (8 + RANDOM() * 12)::INTEGER * INTERVAL '1 hour')::TIMESTAMP;
    
    session_type := CASE (i % 3)
      WHEN 0 THEN 'push'
      WHEN 1 THEN 'pull'
      ELSE 'legs'
    END;
    
    workout_id := CASE session_type
      WHEN 'push' THEN push_id
      WHEN 'pull' THEN pull_id
      ELSE legs_id
    END;
    
    PERFORM generate_performed_session(
      '9af8cb22-9196-4616-bea9-5fafc0b48af7',
      workout_id,
      session_start,
      60 + (RANDOM() * 60)::INTEGER
    );
  END LOOP;
END $$;

-- ============================================
-- 6. NETTOYER LA FONCTION TEMPORAIRE
-- ============================================

DROP FUNCTION IF EXISTS generate_performed_session;

-- ============================================
-- 7. VÉRIFICATION
-- ============================================

DO $$
DECLARE
  session_count INTEGER;
  performed_dec_count INTEGER;
  performed_jan_count INTEGER;
  performed_week_12_count INTEGER;
  set_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO session_count FROM workoutsession WHERE user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7';
  SELECT COUNT(*) INTO performed_dec_count FROM performedsession 
    WHERE user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' 
    AND started_at >= '2025-12-01' AND started_at < '2026-01-01';
  SELECT COUNT(*) INTO performed_jan_count FROM performedsession 
    WHERE user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' 
    AND started_at >= '2026-01-01' AND started_at < '2026-01-17';
  SELECT COUNT(*) INTO performed_week_12_count FROM performedsession 
    WHERE user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7' 
    AND started_at >= '2026-01-12' AND started_at < '2026-01-17';
  SELECT COUNT(*) INTO set_count FROM exerciseset WHERE user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'GÉNÉRATION TERMINÉE';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Séances créées: %', session_count;
  RAISE NOTICE 'Séances effectuées en décembre 2025: %', performed_dec_count;
  RAISE NOTICE 'Séances effectuées en janvier 2026 (1-16): %', performed_jan_count;
  RAISE NOTICE 'Séances semaine du 12 janvier (12-16): %', performed_week_12_count;
  RAISE NOTICE 'Séries créées: %', set_count;
  RAISE NOTICE '========================================';
END $$;

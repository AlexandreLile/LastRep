-- ============================================
-- GÉNÉRATION FORCÉE DES DONNÉES AVEC PROGRESSION
-- ============================================
-- User ID: 9af8cb22-9196-4616-bea9-5fafc0b48af7
-- Séance ID: 2ddb6570-162f-4423-b393-13ed02635d97
-- Période: décembre 2025 à janvier 2026
-- Dernière séance: 16 janvier 2026 à 13h08 (heure française = 12h08 UTC)
-- 
-- Progression: charges, répétitions et temps d'isométrie augmentent séance après séance

DO $$
DECLARE
  test1_session_id UUID := '2ddb6570-162f-4423-b393-13ed02635d97';
  exercise_rec RECORD;
  exercise_list UUID[] := ARRAY[]::UUID[];
  exercise_type_map JSONB := '{}'::JSONB;
  exercise_name_map JSONB := '{}'::JSONB;
  session_start TIMESTAMP;
  session_end TIMESTAMP;
  performed_id UUID;
  set_id UUID;
  i INTEGER;
  j INTEGER;
  k INTEGER;
  num_sets INTEGER;
  weight_val NUMERIC;
  reps_val INTEGER;
  time_val INTEGER;
  base_weight NUMERIC;
  base_reps INTEGER;
  base_time INTEGER;
  progression_factor NUMERIC;
  exercise_count INTEGER;
  session_num INTEGER := 0;
  dates_array DATE[];
  session_date_val DATE;
  exercise_measurement_type TEXT;
  exercise_name_val TEXT;
BEGIN
  RAISE NOTICE '🚀 Début de la génération des données pour la séance %', test1_session_id;
  
  -- Vérifier que la séance existe
  IF NOT EXISTS (SELECT 1 FROM workoutsession WHERE id = test1_session_id) THEN
    RAISE EXCEPTION 'Séance avec ID % non trouvée', test1_session_id;
  END IF;
  
  -- Récupérer les exercices de la séance avec leur measurement_type
  FOR exercise_rec IN
    SELECT 
      we.exercise_id,
      e.name,
      e.measurement_type
    FROM workoutexercise we
    JOIN exercise e ON e.id = we.exercise_id
    WHERE we.session_id = test1_session_id
    ORDER BY we."order"
  LOOP
    exercise_list := array_append(exercise_list, exercise_rec.exercise_id);
    exercise_type_map := exercise_type_map || jsonb_build_object(exercise_rec.exercise_id::TEXT, exercise_rec.measurement_type);
    exercise_name_map := exercise_name_map || jsonb_build_object(exercise_rec.exercise_id::TEXT, exercise_rec.name);
  END LOOP;
  
  exercise_count := array_length(exercise_list, 1);
  
  IF exercise_count = 0 THEN
    RAISE EXCEPTION 'Aucun exercice trouvé dans la séance';
  END IF;
  
  RAISE NOTICE '✅ % exercice(s) trouvé(s) dans la séance', exercise_count;
  
  -- Générer les dates de décembre 2025 à janvier 2026
  dates_array := ARRAY[
    '2025-12-02', '2025-12-04', '2025-12-06', '2025-12-09', '2025-12-11',
    '2025-12-13', '2025-12-16', '2025-12-18', '2025-12-20', '2025-12-23',
    '2025-12-27', '2025-12-30',
    '2026-01-02', '2026-01-04', '2026-01-06', '2026-01-09', '2026-01-11',
    '2026-01-13', '2026-01-15', '2026-01-16'
  ];
  
  -- Générer les séances avec progression
  FOR i IN 1..array_length(dates_array, 1) LOOP
    session_num := i;
    session_date_val := dates_array[i];
    
    -- Dernière séance le 16 janvier à 13h08 heure française (12h08 UTC)
    IF session_date_val = '2026-01-16' THEN
      session_start := '2026-01-16 12:08:00'::TIMESTAMP;
    ELSE
      -- Heures aléatoires entre 8h et 20h pour les autres séances
      session_start := (session_date_val + (8 + RANDOM() * 12)::INTEGER * INTERVAL '1 hour')::TIMESTAMP;
    END IF;
    
    -- Durée entre 45 et 90 minutes
    session_end := session_start + (45 + (RANDOM() * 45))::INTEGER * INTERVAL '1 minute';
    
    -- Créer la séance effectuée
    performed_id := gen_random_uuid();
    INSERT INTO performedsession (id, user_id, workout_session_id, started_at, ended_at, created_at)
    VALUES (performed_id, '9af8cb22-9196-4616-bea9-5fafc0b48af7', test1_session_id, session_start, session_end, session_start)
    ON CONFLICT (id) DO NOTHING;
    
    -- Pour chaque exercice de la séance
    FOR j IN 1..exercise_count LOOP
      exercise_measurement_type := exercise_type_map->>(exercise_list[j]::TEXT);
      
      -- Déterminer le nombre de séries selon le type
      IF exercise_measurement_type = 'time' THEN
        num_sets := 3;
      ELSE
        num_sets := 3 + (RANDOM() * 2)::INTEGER;
      END IF;
      
      -- Calculer les valeurs de base avec progression
      progression_factor := 1.0 + ((session_num - 1) * 0.02);
      
      -- Pour chaque série
      FOR k IN 1..num_sets LOOP
        set_id := gen_random_uuid();
        
        IF exercise_measurement_type = 'time' OR exercise_measurement_type = 'time_reps' THEN
          base_time := 30 + (session_num - 1) * 2;
          time_val := base_time + (RANDOM() * 5)::INTEGER;
          
          INSERT INTO exerciseset (
            id, exercise_id, user_id, duration_seconds, reps,
            rest_seconds, performed_session_id, created_at
          )
          VALUES (
            set_id,
            exercise_list[j],
            '9af8cb22-9196-4616-bea9-5fafc0b48af7',
            time_val,
            CASE WHEN exercise_measurement_type = 'time_reps' THEN 1 ELSE 0 END,
            60 + (RANDOM() * 60)::INTEGER,
            performed_id,
            session_start + (j * 10 + k * 2)::INTEGER * INTERVAL '1 minute'
          )
          ON CONFLICT (id) DO NOTHING;
          
        ELSIF exercise_measurement_type = 'reps' THEN
          base_reps := 10 + (session_num - 1) * 1;
          reps_val := base_reps + (RANDOM() * 3)::INTEGER;
          weight_val := CASE WHEN RANDOM() < 0.2 THEN (RANDOM() * 20)::NUMERIC ELSE 0 END;
          
          INSERT INTO exerciseset (
            id, exercise_id, user_id, weight_kg, reps,
            rest_seconds, performed_session_id, created_at
          )
          VALUES (
            set_id,
            exercise_list[j],
            '9af8cb22-9196-4616-bea9-5fafc0b48af7',
            ROUND(weight_val::NUMERIC, 1),
            reps_val,
            60 + (RANDOM() * 60)::INTEGER,
            performed_id,
            session_start + (j * 10 + k * 2)::INTEGER * INTERVAL '1 minute'
          )
          ON CONFLICT (id) DO NOTHING;
          
        ELSE
          exercise_name_val := exercise_name_map->>(exercise_list[j]::TEXT);
        
          IF exercise_name_val LIKE '%Squat%' OR exercise_name_val LIKE '%Leg Press%' OR exercise_name_val LIKE '%Hip Thrust%' THEN
            base_weight := 60.0 + (session_num - 1) * 2.5;
          ELSIF exercise_name_val LIKE '%Développé%' OR exercise_name_val LIKE '%Rowing%' THEN
            base_weight := 50.0 + (session_num - 1) * 2.0;
          ELSIF exercise_name_val LIKE '%Curl%' OR exercise_name_val LIKE '%Extension%' OR exercise_name_val LIKE '%Face pull%' THEN
            base_weight := 10.0 + (session_num - 1) * 1.0;
          ELSE
            base_weight := 40.0 + (session_num - 1) * 1.5;
          END IF;
          
          weight_val := base_weight * progression_factor + (RANDOM() * 3 - 1.5);
          base_reps := 8 + (session_num - 1) * 0.5;
          reps_val := GREATEST(1, (base_reps * progression_factor)::INTEGER + (RANDOM() * 2 - 1)::INTEGER);
          
          INSERT INTO exerciseset (
            id, exercise_id, user_id, weight_kg, reps,
            rest_seconds, performed_session_id, created_at
          )
          VALUES (
            set_id,
            exercise_list[j],
            '9af8cb22-9196-4616-bea9-5fafc0b48af7',
            ROUND(weight_val::NUMERIC, 1),
            reps_val,
            90 + (RANDOM() * 60)::INTEGER,
            performed_id,
            session_start + (j * 10 + k * 3)::INTEGER * INTERVAL '1 minute'
          )
          ON CONFLICT (id) DO NOTHING;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;
  
  RAISE NOTICE '✅ Génération terminée : % séances créées avec progression', array_length(dates_array, 1);
END $$;

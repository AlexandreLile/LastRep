-- ============================================
-- MISE À JOUR DES DONNÉES DE SEED DE 2025 À 2026
-- ============================================

-- Mettre à jour les dates dans workoutsession
UPDATE workoutsession
SET 
  created_at = created_at + INTERVAL '1 year',
  date = (date + INTERVAL '1 year')::date,
  updated_at = updated_at + INTERVAL '1 year'
WHERE user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7'
  AND date >= '2025-01-01' AND date < '2026-01-01';

-- Mettre à jour les dates dans workoutexercise
UPDATE workoutexercise
SET 
  created_at = created_at + INTERVAL '1 year',
  updated_at = updated_at + INTERVAL '1 year'
WHERE session_id IN (
  SELECT id FROM workoutsession 
  WHERE user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7'
);

-- Mettre à jour les dates dans performedsession
UPDATE performedsession
SET 
  started_at = started_at + INTERVAL '1 year',
  ended_at = ended_at + INTERVAL '1 year',
  created_at = created_at + INTERVAL '1 year'
WHERE user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7'
  AND started_at >= '2025-01-01' AND started_at < '2026-01-01';

-- Mettre à jour les dates dans exerciseset
UPDATE exerciseset
SET created_at = created_at + INTERVAL '1 year'
WHERE user_id = '9af8cb22-9196-4616-bea9-5fafc0b48af7'
  AND created_at >= '2025-01-01' AND created_at < '2026-01-01';

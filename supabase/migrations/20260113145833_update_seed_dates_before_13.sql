-- ============================================
-- MISE À JOUR DES DATES POUR QU'ELLES SOIENT AVANT LE 13 JANVIER
-- ============================================

-- Mettre à jour workoutsession : 2, 4, 6 janvier
UPDATE workoutsession
SET 
  created_at = '2026-01-02T10:00:00Z',
  date = '2026-01-02',
  updated_at = '2026-01-02T10:00:00Z'
WHERE id = 'a1111111-1111-1111-1111-111111111111';

UPDATE workoutsession
SET 
  created_at = '2026-01-04T14:00:00Z',
  date = '2026-01-04',
  updated_at = '2026-01-04T14:00:00Z'
WHERE id = 'a2222222-2222-2222-2222-222222222222';

UPDATE workoutsession
SET 
  created_at = '2026-01-06T16:00:00Z',
  date = '2026-01-06',
  updated_at = '2026-01-06T16:00:00Z'
WHERE id = 'a3333333-3333-3333-3333-333333333333';

-- Mettre à jour workoutexercise pour la séance 1 (2 janvier)
UPDATE workoutexercise
SET 
  created_at = '2026-01-02T10:00:00Z',
  updated_at = '2026-01-02T10:00:00Z'
WHERE session_id = 'a1111111-1111-1111-1111-111111111111';

-- Mettre à jour workoutexercise pour la séance 2 (4 janvier)
UPDATE workoutexercise
SET 
  created_at = '2026-01-04T14:00:00Z',
  updated_at = '2026-01-04T14:00:00Z'
WHERE session_id = 'a2222222-2222-2222-2222-222222222222';

-- Mettre à jour workoutexercise pour la séance 3 (6 janvier)
UPDATE workoutexercise
SET 
  created_at = '2026-01-06T16:00:00Z',
  updated_at = '2026-01-06T16:00:00Z'
WHERE session_id = 'a3333333-3333-3333-3333-333333333333';

-- Mettre à jour performedsession : 2, 4, 6, 10, 12 janvier
UPDATE performedsession
SET 
  started_at = '2026-01-02T10:00:00Z',
  ended_at = '2026-01-02T11:15:00Z',
  created_at = '2026-01-02T10:00:00Z'
WHERE id = 'c1111111-1111-1111-1111-111111111111';

UPDATE performedsession
SET 
  started_at = '2026-01-04T14:00:00Z',
  ended_at = '2026-01-04T15:30:00Z',
  created_at = '2026-01-04T14:00:00Z'
WHERE id = 'c2222222-2222-2222-2222-222222222222';

UPDATE performedsession
SET 
  started_at = '2026-01-06T16:00:00Z',
  ended_at = '2026-01-06T17:45:00Z',
  created_at = '2026-01-06T16:00:00Z'
WHERE id = 'c3333333-3333-3333-3333-333333333333';

UPDATE performedsession
SET 
  started_at = '2026-01-10T10:00:00Z',
  ended_at = '2026-01-10T11:20:00Z',
  created_at = '2026-01-10T10:00:00Z'
WHERE id = 'c4444444-4444-4444-4444-444444444444';

UPDATE performedsession
SET 
  started_at = '2026-01-12T14:00:00Z',
  ended_at = '2026-01-12T15:50:00Z',
  created_at = '2026-01-12T14:00:00Z'
WHERE id = 'c5555555-5555-5555-5555-555555555555';

-- Mettre à jour exerciseset pour la séance 1 (2 janvier)
UPDATE exerciseset
SET created_at = created_at - INTERVAL '3 days'
WHERE performed_session_id = 'c1111111-1111-1111-1111-111111111111'
  AND created_at >= '2026-01-05' AND created_at < '2026-01-06';

-- Mettre à jour exerciseset pour la séance 2 (4 janvier)
UPDATE exerciseset
SET created_at = created_at - INTERVAL '6 days'
WHERE performed_session_id = 'c2222222-2222-2222-2222-222222222222'
  AND created_at >= '2026-01-10' AND created_at < '2026-01-11';

-- Mettre à jour exerciseset pour la séance 3 (6 janvier)
UPDATE exerciseset
SET created_at = created_at - INTERVAL '9 days'
WHERE performed_session_id = 'c3333333-3333-3333-3333-333333333333'
  AND created_at >= '2026-01-15' AND created_at < '2026-01-16';

-- Mettre à jour exerciseset pour la séance 4 (10 janvier)
UPDATE exerciseset
SET created_at = created_at - INTERVAL '10 days'
WHERE performed_session_id = 'c4444444-4444-4444-4444-444444444444'
  AND created_at >= '2026-01-20' AND created_at < '2026-01-21';

-- Mettre à jour exerciseset pour la séance 5 (12 janvier)
UPDATE exerciseset
SET created_at = created_at - INTERVAL '13 days'
WHERE performed_session_id = 'c5555555-5555-5555-5555-555555555555'
  AND created_at >= '2026-01-25' AND created_at < '2026-01-26';

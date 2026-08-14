-- ============================================
-- IMAGE DE DÉMONSTRATION PAR EXERCICE
-- ============================================
-- GIF de démonstration (source : WorkoutX API, réhébergé sur notre propre bucket
-- pour ne pas dépendre d'une clé API côté client).

ALTER TABLE exercise
ADD COLUMN IF NOT EXISTS image_url TEXT;

COMMENT ON COLUMN exercise.image_url IS 'GIF de démonstration de l''exercice';

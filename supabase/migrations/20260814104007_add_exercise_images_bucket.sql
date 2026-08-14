-- ============================================
-- BUCKET STORAGE : IMAGES DES EXERCICES
-- ============================================
-- Bucket public en lecture (GIFs de démonstration, pas de donnée sensible).
-- L'écriture est réservée au service role (upload fait par un script serveur,
-- jamais depuis le client, pour ne pas exposer la clé API WorkoutX).

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('exercise-images', 'exercise-images', true, 5242880, ARRAY['image/gif', 'image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Public read access to exercise images" ON storage.objects;
CREATE POLICY "Public read access to exercise images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'exercise-images');

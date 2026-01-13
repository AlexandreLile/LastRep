-- ============================================
-- SUPPRESSION : Extension pgjwt dépréciée
-- ============================================
-- L'extension pgjwt est dépréciée dans les nouvelles versions de PostgreSQL
-- et doit être supprimée avant de mettre à jour.
-- 
-- Cette extension n'est pas utilisée dans ce projet car Supabase gère
-- les JWT automatiquement via son infrastructure d'authentification.

-- Vérifier si l'extension existe avant de la supprimer
DO $$
BEGIN
  -- Supprimer l'extension si elle existe
  IF EXISTS (
    SELECT 1 
    FROM pg_extension 
    WHERE extname = 'pgjwt'
  ) THEN
    DROP EXTENSION IF EXISTS pgjwt CASCADE;
    RAISE NOTICE 'Extension pgjwt supprimée avec succès';
  ELSE
    RAISE NOTICE 'Extension pgjwt n''existe pas, aucune action nécessaire';
  END IF;
END $$;

-- Note: Si vous avez des fonctions ou triggers qui utilisent pgjwt,
-- vous devrez les modifier avant d'exécuter cette migration.
-- Dans ce projet, aucune fonction n'utilise pgjwt, donc la suppression est sûre.

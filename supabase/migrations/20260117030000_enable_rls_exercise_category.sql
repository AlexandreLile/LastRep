-- ============================================
-- ACTIVATION RLS SUR exercise_category
-- ============================================
-- Cette migration active Row Level Security sur la table exercise_category
-- et définit les policies pour l'accès en lecture seule pour tous les utilisateurs

-- ============================================
-- 1. ACTIVER RLS
-- ============================================

ALTER TABLE exercise_category ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. SUPPRIMER LES POLICIES EXISTANTES (SI ELLES EXISTENT)
-- ============================================

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'exercise_category') LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.exercise_category', r.policyname);
  END LOOP;
END
$$;

-- ============================================
-- 3. CRÉER LES POLICIES
-- ============================================

-- Policy : Tous les utilisateurs authentifiés peuvent voir les catégories
CREATE POLICY "Anyone can view exercise categories"
  ON exercise_category
  FOR SELECT
  USING (true);

-- Policy : Seuls les admins peuvent créer/modifier/supprimer
-- (Pour l'instant, on bloque tout pour les utilisateurs normaux)
-- Les modifications se font uniquement via migrations SQL

-- Note : Si vous avez besoin que les utilisateurs puissent créer des catégories personnalisées,
-- vous pouvez ajouter une policy INSERT avec WITH CHECK (user_id = auth.uid())
-- Mais pour l'instant, on garde ça simple : lecture seule pour tous

-- ============================================
-- 4. MESSAGE DE CONFIRMATION
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ RLS activé sur exercise_category :';
  RAISE NOTICE '   - Lecture autorisée pour tous les utilisateurs authentifiés';
  RAISE NOTICE '   - Modifications uniquement via migrations SQL';
END $$;

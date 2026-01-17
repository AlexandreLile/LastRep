-- ============================================
-- TABLE : Tracking des suppressions de compte
-- ============================================
-- Cette table permet de tracker quand un utilisateur supprime son compte
-- IMPORTANT : On garde l'email car le user_id sera supprimé avec le compte

CREATE TABLE IF NOT EXISTS public.account_deletion_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID, -- Peut être NULL après suppression
  email TEXT NOT NULL, -- On garde l'email pour référence
  deleted_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB, -- Informations supplémentaires (nb séances, etc.)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les recherches par email et date
CREATE INDEX IF NOT EXISTS idx_account_deletion_log_email ON public.account_deletion_log(email);
CREATE INDEX IF NOT EXISTS idx_account_deletion_log_deleted_at ON public.account_deletion_log(deleted_at DESC);

-- RLS : Seuls les admins peuvent voir cette table
ALTER TABLE public.account_deletion_log ENABLE ROW LEVEL SECURITY;

-- Policy : Seuls les admins peuvent lire (via service_role)
-- Les utilisateurs normaux ne peuvent pas lire cette table
CREATE POLICY "Only admins can read deletion logs"
  ON public.account_deletion_log
  FOR SELECT
  USING (false); -- Personne ne peut lire via authenticated, seulement via service_role

-- Commentaire
COMMENT ON TABLE public.account_deletion_log IS 
'Table de tracking des suppressions de compte. Permet de garder une trace des comptes supprimés pour analytics.';

-- ============================================
-- MODIFIER LA FONCTION delete_user_account
-- ============================================
-- On ajoute le logging AVANT la suppression

CREATE OR REPLACE FUNCTION public.delete_user_account(user_uuid uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  session_ids uuid[];
  user_email TEXT;
  session_count INTEGER := 0;
  exercise_count INTEGER := 0;
BEGIN
  -- Vérifier que l'utilisateur supprime bien son propre compte
  IF user_uuid != auth.uid() THEN
    RAISE EXCEPTION 'Vous ne pouvez supprimer que votre propre compte';
  END IF;

  -- Récupérer l'email de l'utilisateur AVANT suppression
  SELECT email INTO user_email
  FROM auth.users
  WHERE id = user_uuid;

  -- Compter les séances et exercices pour metadata
  SELECT COUNT(*) INTO session_count
  FROM workoutsession
  WHERE user_id = user_uuid;

  SELECT COUNT(*) INTO exercise_count
  FROM exercise
  WHERE user_id = user_uuid AND is_custom = true;

  -- LOGGER LA SUPPRESSION AVANT DE SUPPRIMER
  INSERT INTO public.account_deletion_log (
    user_id,
    email,
    metadata
  ) VALUES (
    user_uuid,
    COALESCE(user_email, 'unknown'),
    jsonb_build_object(
      'session_count', session_count,
      'custom_exercise_count', exercise_count,
      'deletion_initiated_at', NOW()
    )
  );

  -- Récupérer les IDs des séances de l'utilisateur
  SELECT ARRAY_AGG(id) INTO session_ids
  FROM workoutsession
  WHERE user_id = user_uuid;

  -- 1. Supprimer les séries (exerciseset)
  DELETE FROM exerciseset
  WHERE user_id = user_uuid;

  -- 2. Supprimer les séances effectuées (performedsession)
  DELETE FROM performedsession
  WHERE user_id = user_uuid;

  -- 3. Supprimer les exercices des séances (workoutexercise)
  -- Si l'utilisateur a des séances
  IF session_ids IS NOT NULL AND array_length(session_ids, 1) > 0 THEN
    DELETE FROM workoutexercise
    WHERE session_id = ANY(session_ids);
  END IF;

  -- 4. Supprimer les séances (workoutsession)
  DELETE FROM workoutsession
  WHERE user_id = user_uuid;

  -- 5. Supprimer les exercices personnalisés (exercise où user_id = user_uuid)
  DELETE FROM exercise
  WHERE user_id = user_uuid AND is_custom = true;

  -- Note : La suppression du compte Supabase Auth doit être faite séparément
  -- car elle nécessite les privilèges admin. L'utilisateur sera déconnecté
  -- et le compte pourra être supprimé manuellement ou via une Edge Function.
END;
$$;

-- Commentaire de sécurité
COMMENT ON FUNCTION public.delete_user_account(uuid) IS 
'Sécurisé : search_path fixe, vérifie que l''utilisateur supprime son propre compte. Supprime toutes les données utilisateur en cascade. Log la suppression dans account_deletion_log avant suppression.';

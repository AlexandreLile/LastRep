-- ============================================
-- FONCTION : Suppression de compte utilisateur en cascade
-- ============================================
-- Cette fonction supprime toutes les données d'un utilisateur en cascade
-- pour respecter le RGPD et permettre la suppression de compte

CREATE OR REPLACE FUNCTION public.delete_user_account(user_uuid uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  session_ids uuid[];
BEGIN
  -- Vérifier que l'utilisateur supprime bien son propre compte
  IF user_uuid != auth.uid() THEN
    RAISE EXCEPTION 'Vous ne pouvez supprimer que votre propre compte';
  END IF;

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
'Sécurisé : search_path fixe, vérifie que l''utilisateur supprime son propre compte. Supprime toutes les données utilisateur en cascade.';

-- Grant pour permettre aux utilisateurs d'appeler cette fonction
GRANT EXECUTE ON FUNCTION public.delete_user_account(uuid) TO authenticated;

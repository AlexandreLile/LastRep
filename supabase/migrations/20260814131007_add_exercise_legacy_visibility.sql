-- ============================================
-- REMPLACEMENT DU CATALOGUE D'EXERCICES (WorkoutX)
-- ============================================
-- Le catalogue global actuel est remplacé par le catalogue complet WorkoutX
-- (images propres, appariées 1:1, sans erreur de matching). Les anciens
-- exercices ne sont PAS supprimés : ils sont marqués "legacy" pour ne plus
-- apparaître aux nouveaux utilisateurs, mais restent visibles et utilisables
-- par les utilisateurs qui les ont déjà utilisés (séances, séries, stats),
-- afin de ne jamais casser leur historique/progression.

ALTER TABLE exercise
ADD COLUMN IF NOT EXISTS is_legacy BOOLEAN NOT NULL DEFAULT false;

-- Tous les exercices globaux actuels deviennent "legacy"
-- (les futurs exercices importés seront is_legacy = false par défaut)
UPDATE exercise SET is_legacy = true WHERE is_custom = false;

CREATE INDEX IF NOT EXISTS idx_exercise_is_legacy ON exercise(is_legacy);

-- ============================================
-- FONCTION DE VISIBILITÉ
-- ============================================
-- Remplace un SELECT direct sur exercise pour le catalogue affiché à l'utilisateur.
-- Retourne :
--   - les exercices personnalisés de l'utilisateur
--   - les nouveaux exercices globaux (is_legacy = false)
--   - les anciens exercices globaux (is_legacy = true) UNIQUEMENT si l'utilisateur
--     les a déjà utilisés (séries loggées ou exercice ajouté à une séance)
--
-- Pas de SECURITY DEFINER : s'appuie sur les policies RLS existantes de
-- exercise / exerciseset / workoutexercise / workoutsession pour rester cohérente
-- avec les droits d'accès déjà en place.

CREATE OR REPLACE FUNCTION get_visible_exercises()
RETURNS SETOF exercise
LANGUAGE sql
STABLE
AS $$
  SELECT e.*
  FROM exercise e
  WHERE
    (e.is_custom = true AND e.user_id = auth.uid())
    OR (e.is_custom = false AND e.is_legacy = false)
    OR (
      e.is_custom = false
      AND e.is_legacy = true
      AND auth.uid() IS NOT NULL
      AND (
        EXISTS (
          SELECT 1 FROM exerciseset es
          WHERE es.exercise_id = e.id AND es.user_id = auth.uid()
        )
        OR EXISTS (
          SELECT 1 FROM workoutexercise we
          JOIN workoutsession ws ON ws.id = we.session_id
          WHERE we.exercise_id = e.id AND ws.user_id = auth.uid()
        )
      )
    );
$$;

COMMENT ON FUNCTION get_visible_exercises() IS
'Catalogue visible pour l''utilisateur courant : nouveaux exercices + ses exercices personnalisés + anciens exercices déjà utilisés par lui. Les anciens exercices jamais utilisés (legacy) restent en base mais disparaissent des nouveaux catalogues.';

-- ============================================
-- CYCLES D'ENTRAÎNEMENT
-- ============================================
-- Ajoute la notion de cycle (programme sur une période) avec des créneaux
-- nommés (ex: "Push A", "Jambes"). Les séances existantes restent libres
-- et non impactées (cycle_slot_id nullable sur performedsession).

-- ============================================
-- TABLE : cycle
-- ============================================

CREATE TABLE IF NOT EXISTS public.cycle (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        VARCHAR NOT NULL,
  started_at  DATE NOT NULL,
  ended_at    DATE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cycle_user_id ON public.cycle(user_id);
CREATE INDEX IF NOT EXISTS idx_cycle_started_at ON public.cycle(started_at DESC);

ALTER TABLE public.cycle ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own cycles"
  ON public.cycle FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own cycles"
  ON public.cycle FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own cycles"
  ON public.cycle FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own cycles"
  ON public.cycle FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

COMMENT ON TABLE public.cycle IS
'Cycle d''entraînement : regroupe des créneaux de séances sur une période définie.';

-- ============================================
-- TABLE : cycle_slot
-- ============================================
-- Un créneau = une position nommée dans un cycle (ex: "Push A").
-- Il peut être lié à un template workoutsession existant (optionnel).

CREATE TABLE IF NOT EXISTS public.cycle_slot (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id            UUID NOT NULL REFERENCES public.cycle(id) ON DELETE CASCADE,
  workout_session_id  UUID REFERENCES public.workoutsession(id) ON DELETE SET NULL,
  name                VARCHAR NOT NULL,
  slot_order          INT NOT NULL DEFAULT 0,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cycle_slot_cycle_id ON public.cycle_slot(cycle_id);
CREATE INDEX IF NOT EXISTS idx_cycle_slot_workout_session ON public.cycle_slot(workout_session_id);

ALTER TABLE public.cycle_slot ENABLE ROW LEVEL SECURITY;

-- Accès via la table parente cycle (même user)
CREATE POLICY "Users can view their own cycle slots"
  ON public.cycle_slot FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.cycle
      WHERE public.cycle.id = public.cycle_slot.cycle_id
        AND public.cycle.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can insert slots into their own cycles"
  ON public.cycle_slot FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.cycle
      WHERE public.cycle.id = public.cycle_slot.cycle_id
        AND public.cycle.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update their own cycle slots"
  ON public.cycle_slot FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.cycle
      WHERE public.cycle.id = public.cycle_slot.cycle_id
        AND public.cycle.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can delete their own cycle slots"
  ON public.cycle_slot FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.cycle
      WHERE public.cycle.id = public.cycle_slot.cycle_id
        AND public.cycle.user_id = (SELECT auth.uid())
    )
  );

COMMENT ON TABLE public.cycle_slot IS
'Créneau nommé dans un cycle (ex: "Push A", "Jambes"). Lié optionnellement à un template workoutsession.';

-- ============================================
-- TABLE : cycle_measurement
-- ============================================
-- Mensurations optionnelles en début/fin de cycle.
-- type = ''start'' | ''end''

CREATE TABLE IF NOT EXISTS public.cycle_measurement (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id    UUID NOT NULL REFERENCES public.cycle(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type        VARCHAR NOT NULL CHECK (type IN ('start', 'end')),
  measured_at DATE NOT NULL DEFAULT CURRENT_DATE,
  weight_kg   NUMERIC(5,2),
  arm_cm      NUMERIC(5,2),
  waist_cm    NUMERIC(5,2),
  chest_cm    NUMERIC(5,2),
  thigh_cm    NUMERIC(5,2),
  calf_cm     NUMERIC(5,2),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (cycle_id, type)
);

CREATE INDEX IF NOT EXISTS idx_cycle_measurement_cycle_id ON public.cycle_measurement(cycle_id);

ALTER TABLE public.cycle_measurement ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own cycle measurements"
  ON public.cycle_measurement FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own cycle measurements"
  ON public.cycle_measurement FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own cycle measurements"
  ON public.cycle_measurement FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own cycle measurements"
  ON public.cycle_measurement FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

COMMENT ON TABLE public.cycle_measurement IS
'Mensurations optionnelles (poids, tour de bras, etc.) à la création et clôture d''un cycle.';

-- ============================================
-- MODIFIER : performedsession
-- ============================================
-- Ajout du lien optionnel vers un créneau de cycle.
-- NULL = séance libre (comportement actuel inchangé).

ALTER TABLE public.performedsession
  ADD COLUMN IF NOT EXISTS cycle_slot_id UUID REFERENCES public.cycle_slot(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_performedsession_cycle_slot ON public.performedsession(cycle_slot_id)
  WHERE cycle_slot_id IS NOT NULL;

COMMENT ON COLUMN public.performedsession.cycle_slot_id IS
'Créneau du cycle auquel cette séance est rattachée. NULL = séance libre hors cycle.';

-- ============================================
-- MODIFIER : delete_user_account
-- ============================================
-- Ajouter la suppression des cycles dans la cascade.

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
  IF user_uuid != auth.uid() THEN
    RAISE EXCEPTION 'Vous ne pouvez supprimer que votre propre compte';
  END IF;

  SELECT email INTO user_email FROM auth.users WHERE id = user_uuid;

  SELECT COUNT(*) INTO session_count FROM workoutsession WHERE user_id = user_uuid;
  SELECT COUNT(*) INTO exercise_count FROM exercise WHERE user_id = user_uuid AND is_custom = true;

  INSERT INTO public.account_deletion_log (user_id, email, metadata)
  VALUES (
    user_uuid,
    COALESCE(user_email, 'unknown'),
    jsonb_build_object(
      'session_count', session_count,
      'custom_exercise_count', exercise_count,
      'deletion_initiated_at', NOW()
    )
  );

  SELECT ARRAY_AGG(id) INTO session_ids FROM workoutsession WHERE user_id = user_uuid;

  -- Séries
  DELETE FROM exerciseset WHERE user_id = user_uuid;

  -- Séances effectuées (cycle_slot_id mis à NULL par ON DELETE SET NULL sur cycle_slot)
  DELETE FROM performedsession WHERE user_id = user_uuid;

  -- Exercices des templates
  IF session_ids IS NOT NULL AND array_length(session_ids, 1) > 0 THEN
    DELETE FROM workoutexercise WHERE session_id = ANY(session_ids);
  END IF;

  -- Templates de séances
  DELETE FROM workoutsession WHERE user_id = user_uuid;

  -- Cycles (cascade vers cycle_slot et cycle_measurement via ON DELETE CASCADE)
  DELETE FROM cycle WHERE user_id = user_uuid;

  -- Exercices personnalisés
  DELETE FROM exercise WHERE user_id = user_uuid AND is_custom = true;
END;
$$;

COMMENT ON FUNCTION public.delete_user_account(uuid) IS
'Sécurisé : search_path fixe, vérifie que l''utilisateur supprime son propre compte. Supprime toutes les données utilisateur en cascade (inclut les cycles). Log la suppression avant exécution.';

-- ============================================
-- CORRECTIF : trigger d'inscription cassé (search_path)
-- ============================================
-- Le trigger AFTER INSERT sur auth.users (create_free_subscription, introduit
-- lors d'un test de l'intégration Stripe) fait "INSERT INTO subscriptions"
-- sans qualifier le schéma. Exécutée depuis le contexte auth.users, cette
-- fonction SECURITY DEFINER ne trouve pas la table (qui existe pourtant dans
-- public) car le search_path n'inclut pas public dans ce contexte.
-- Résultat : toute nouvelle inscription échoue avec "relation subscriptions
-- does not exist". On qualifie explicitement public.subscriptions.

CREATE OR REPLACE FUNCTION public.create_free_subscription()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.subscriptions (user_id, status, plan)
  VALUES (NEW.id, 'free', 'free')
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

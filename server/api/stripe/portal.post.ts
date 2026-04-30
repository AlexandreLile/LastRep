import { createClient } from '@supabase/supabase-js'
import { getStripe } from '~/server/utils/stripe'

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()

  const authHeader = getHeader(event, 'authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    throw createError({ statusCode: 401, message: 'Non authentifié' })
  }
  const token = authHeader.slice(7)

  const supabase = createClient(
    config.supabase.url,
    config.supabase.serviceKey,
    { auth: { persistSession: false } }
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    throw createError({ statusCode: 401, message: 'Token invalide' })
  }

  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('stripe_customer_id')
    .eq('user_id', user.id)
    .single()

  if (!subscription?.stripe_customer_id) {
    throw createError({ statusCode: 400, message: 'Aucun abonnement Stripe trouvé' })
  }

  const stripe = getStripe()
  const appUrl = config.public.appUrl || 'http://localhost:3000'

  const portalSession = await stripe.billingPortal.sessions.create({
    customer: subscription.stripe_customer_id,
    return_url: `${appUrl}/abonnement`,
  })

  return { url: portalSession.url }
})

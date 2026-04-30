import { createClient } from '@supabase/supabase-js'
import { getStripe } from '~/server/utils/stripe'

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()

  const authHeader = getHeader(event, 'authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    throw createError({ statusCode: 401, message: 'Non authentifié' })
  }
  const token = authHeader.slice(7)

  const body = await readBody(event)
  const { priceId } = body

  if (!priceId) {
    throw createError({ statusCode: 400, message: 'priceId requis' })
  }

  const supabase = createClient(
    config.supabase.url,
    config.supabase.serviceKey,
    { auth: { persistSession: false } }
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    throw createError({ statusCode: 401, message: 'Token invalide' })
  }

  const stripe = getStripe()

  // Récupérer ou créer le customer Stripe
  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('stripe_customer_id')
    .eq('user_id', user.id)
    .single()

  let customerId = subscription?.stripe_customer_id

  if (!customerId) {
    const customer = await stripe.customers.create({
      email: user.email,
      metadata: { supabase_user_id: user.id },
    })
    customerId = customer.id

    await supabase
      .from('subscriptions')
      .upsert({
        user_id: user.id,
        stripe_customer_id: customerId,
        status: 'free',
        plan: 'free',
      }, { onConflict: 'user_id' })
  }

  const appUrl = config.public.appUrl || 'http://localhost:3000'

  const session = await stripe.checkout.sessions.create({
    customer: customerId,
    payment_method_types: ['card'],
    mode: 'subscription',
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${appUrl}/abonnement?success=true&session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${appUrl}/abonnement?canceled=true`,
    subscription_data: {
      metadata: { supabase_user_id: user.id },
    },
    allow_promotion_codes: true,
    locale: 'fr',
  })

  return { url: session.url }
})

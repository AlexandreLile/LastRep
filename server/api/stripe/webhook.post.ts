import Stripe from 'stripe'
import { createClient } from '@supabase/supabase-js'
import { getStripe } from '~/server/utils/stripe'

const PLAN_MAP: Record<string, string> = {}

function getPlanFromPriceId(priceId: string, config: any): string {
  if (priceId === config.stripePriceMonthly) return 'premium_monthly'
  if (priceId === config.stripePriceYearly) return 'premium_yearly'
  return 'premium_monthly'
}

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const stripe = getStripe()

  const body = await readRawBody(event)
  const sig = getHeader(event, 'stripe-signature')

  if (!sig || !body) {
    throw createError({ statusCode: 400, message: 'Signature ou body manquant' })
  }

  let stripeEvent: Stripe.Event

  try {
    stripeEvent = stripe.webhooks.constructEvent(body, sig, config.stripeWebhookSecret)
  } catch (err: any) {
    throw createError({ statusCode: 400, message: `Webhook Error: ${err.message}` })
  }

  const supabase = createClient(
    config.supabase.url,
    config.supabase.serviceKey,
    { auth: { persistSession: false } }
  )

  switch (stripeEvent.type) {
    case 'checkout.session.completed': {
      const session = stripeEvent.data.object as Stripe.Checkout.Session
      if (session.mode !== 'subscription') break

      const stripeSubscription = await stripe.subscriptions.retrieve(session.subscription as string)
      const userId = stripeSubscription.metadata.supabase_user_id || session.metadata?.supabase_user_id

      if (!userId) break

      const priceId = stripeSubscription.items.data[0]?.price.id

      await supabase.from('subscriptions').upsert({
        user_id: userId,
        stripe_customer_id: session.customer as string,
        stripe_subscription_id: stripeSubscription.id,
        stripe_price_id: priceId,
        status: stripeSubscription.status,
        plan: getPlanFromPriceId(priceId, config),
        current_period_start: new Date(stripeSubscription.current_period_start * 1000).toISOString(),
        current_period_end: new Date(stripeSubscription.current_period_end * 1000).toISOString(),
        cancel_at_period_end: stripeSubscription.cancel_at_period_end,
      }, { onConflict: 'user_id' })
      break
    }

    case 'customer.subscription.updated': {
      const sub = stripeEvent.data.object as Stripe.Subscription
      const priceId = sub.items.data[0]?.price.id

      await supabase.from('subscriptions')
        .update({
          stripe_price_id: priceId,
          status: sub.status,
          plan: getPlanFromPriceId(priceId, config),
          current_period_start: new Date(sub.current_period_start * 1000).toISOString(),
          current_period_end: new Date(sub.current_period_end * 1000).toISOString(),
          cancel_at_period_end: sub.cancel_at_period_end,
        })
        .eq('stripe_subscription_id', sub.id)
      break
    }

    case 'customer.subscription.deleted': {
      const sub = stripeEvent.data.object as Stripe.Subscription

      await supabase.from('subscriptions')
        .update({
          status: 'canceled',
          plan: 'free',
          stripe_subscription_id: null,
          stripe_price_id: null,
          cancel_at_period_end: false,
        })
        .eq('stripe_subscription_id', sub.id)
      break
    }

    case 'invoice.payment_failed': {
      const invoice = stripeEvent.data.object as Stripe.Invoice
      if (!invoice.subscription) break

      await supabase.from('subscriptions')
        .update({ status: 'past_due' })
        .eq('stripe_subscription_id', invoice.subscription as string)
      break
    }
  }

  return { received: true }
})

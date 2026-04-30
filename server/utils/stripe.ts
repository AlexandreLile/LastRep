import Stripe from 'stripe'

let stripeInstance: Stripe | null = null

export function getStripe(): Stripe {
  if (!stripeInstance) {
    const config = useRuntimeConfig()
    if (!config.stripeSecretKey) {
      throw new Error('STRIPE_SECRET_KEY is not configured')
    }
    stripeInstance = new Stripe(config.stripeSecretKey, {
      apiVersion: '2025-04-30.basil',
    })
  }
  return stripeInstance
}

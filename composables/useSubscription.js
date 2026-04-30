import { ref, computed } from 'vue'
import { useSupabaseClient, useSupabaseUser, useSupabaseSession } from '#imports'

const subscription = ref(null)
const loading = ref(false)
const initialized = ref(false)

export function useSubscription() {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const session = useSupabaseSession()

  const isPremium = computed(() => {
    const s = subscription.value
    return s?.status === 'active' || s?.status === 'trialing'
  })

  const isYearly = computed(() => subscription.value?.plan === 'premium_yearly')
  const isCanceling = computed(() => subscription.value?.cancel_at_period_end === true)

  const periodEnd = computed(() => {
    if (!subscription.value?.current_period_end) return null
    return new Date(subscription.value.current_period_end)
  })

  async function fetchSubscription() {
    if (!user.value) return

    loading.value = true
    try {
      const { data } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('user_id', user.value.id)
        .single()

      subscription.value = data || { status: 'free', plan: 'free' }
      initialized.value = true
    } catch {
      subscription.value = { status: 'free', plan: 'free' }
    } finally {
      loading.value = false
    }
  }

  async function getAuthToken() {
    if (session.value?.access_token) {
      return session.value.access_token
    }
    const { data } = await supabase.auth.getSession()
    return data.session?.access_token
  }

  async function startCheckout(priceId) {
    const token = await getAuthToken()
    if (!token) throw new Error('Non authentifié')

    const { url } = await $fetch('/api/stripe/checkout', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: { priceId },
    })

    if (url) window.location.href = url
  }

  async function openPortal() {
    const token = await getAuthToken()
    if (!token) throw new Error('Non authentifié')

    const { url } = await $fetch('/api/stripe/portal', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    })

    if (url) window.location.href = url
  }

  return {
    subscription,
    loading,
    initialized,
    isPremium,
    isYearly,
    isCanceling,
    periodEnd,
    fetchSubscription,
    startCheckout,
    openPortal,
  }
}

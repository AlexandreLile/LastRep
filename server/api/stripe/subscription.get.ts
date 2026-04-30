import { createClient } from '@supabase/supabase-js'

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()

  const authHeader = getHeader(event, 'authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    throw createError({ statusCode: 401, message: 'Non authentifié' })
  }
  const token = authHeader.slice(7)

  const supabaseUrl = config.supabase?.url || process.env.SUPABASE_URL || process.env.NUXT_PUBLIC_SUPABASE_URL
  const serviceKey = config.supabase?.serviceKey || process.env.SUPABASE_SERVICE_KEY

  const supabase = createClient(
    supabaseUrl!,
    serviceKey!,
    { auth: { persistSession: false } }
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    throw createError({ statusCode: 401, message: 'Token invalide' })
  }

  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('*')
    .eq('user_id', user.id)
    .single()

  return {
    subscription: subscription || { status: 'free', plan: 'free' },
    isPremium: subscription?.status === 'active' || subscription?.status === 'trialing',
  }
})

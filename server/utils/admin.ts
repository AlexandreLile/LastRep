import { createClient } from '@supabase/supabase-js'
import { getHeader } from 'h3'
import type { H3Event } from 'h3'

function getAdminEmails(): string[] {
  return (process.env.ADMIN_EMAILS || '')
    .split(',')
    .map(email => email.trim().toLowerCase())
    .filter(Boolean)
}

// L'app stocke la session Supabase uniquement en localStorage (pas de cookies SSR,
// voir useSsrCookies:false dans nuxt.config.ts) : le serveur ne peut pas lire l'auth
// via les cookies comme le ferait serverSupabaseUser. Le client doit donc transmettre
// son access_token via l'en-tête Authorization, qu'on valide ici auprès de Supabase.
async function getAuthenticatedUser(event: H3Event) {
  const authHeader = getHeader(event, 'authorization')
  const token = authHeader?.replace(/^Bearer\s+/i, '')
  if (!token) return null

  const supabaseUrl = process.env.SUPABASE_URL || process.env.NUXT_PUBLIC_SUPABASE_URL
  const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_KEY || process.env.NUXT_PUBLIC_SUPABASE_KEY
  if (!supabaseUrl || !supabaseAnonKey) return null

  const supabase = createClient(supabaseUrl, supabaseAnonKey)
  const { data, error } = await supabase.auth.getUser(token)
  if (error) return null
  return data.user
}

export async function isAdminEvent(event: H3Event): Promise<boolean> {
  const user = await getAuthenticatedUser(event)
  if (!user?.email) return false
  return getAdminEmails().includes(user.email.toLowerCase())
}

export async function requireAdmin(event: H3Event) {
  const user = await getAuthenticatedUser(event)
  if (!user) {
    throw createError({ statusCode: 401, statusMessage: 'Non authentifié' })
  }
  if (!user.email || !getAdminEmails().includes(user.email.toLowerCase())) {
    throw createError({ statusCode: 403, statusMessage: 'Accès réservé aux administrateurs' })
  }
  return user
}

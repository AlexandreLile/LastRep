/**
 * API Route Admin - Liste des utilisateurs
 * 
 * ⚠️ SÉCURITÉ : Cette route :
 * - Utilise la service key (accès complet)
 * - N'est accessible qu'en développement
 * - Doit être protégée par le middleware admin
 * 
 * Retourne la liste des utilisateurs avec email, nom, prénom
 */

export default defineEventHandler(async (event) => {
  // Vérifier que nous ne sommes PAS en production
  if (process.env.NODE_ENV === 'production') {
    throw createError({
      statusCode: 403,
      statusMessage: 'Admin dashboard not available in production'
    })
  }

  // Récupérer la config runtime (Nuxt 3)
  const config = useRuntimeConfig()
  
  // Vérifier la service key (depuis runtime config ou env)
  const serviceKey = config.supabase?.serviceKey || process.env.SUPABASE_SERVICE_KEY
  
  // Debug pour voir ce qui est chargé
  console.log('🔍 Debug service key:', {
    hasConfig: !!config.supabase?.serviceKey,
    hasEnv: !!process.env.SUPABASE_SERVICE_KEY,
    configKeyLength: config.supabase?.serviceKey?.length || 0,
    envKeyLength: process.env.SUPABASE_SERVICE_KEY?.length || 0,
    keyStartsWith: serviceKey?.substring(0, 10) || 'none'
  })
  
  if (!serviceKey) {
    console.error('❌ SUPABASE_SERVICE_KEY manquante. Vérifie ton .env.local')
    throw createError({
      statusCode: 500,
      statusMessage: 'Service key not configured. Vérifie que SUPABASE_SERVICE_KEY est dans .env.local et redémarre le serveur'
    })
  }
  
  // Vérifier le format de la clé (Supabase utilise des JWT qui commencent par 'eyJ')
  if (!serviceKey.startsWith('eyJ') && !serviceKey.startsWith('sb_')) {
    console.warn('⚠️ Format de clé suspect. Supabase service_role key commence normalement par "eyJ" (JWT)')
  }

  const supabaseUrl = config.supabase?.url || process.env.SUPABASE_URL || process.env.NUXT_PUBLIC_SUPABASE_URL
  if (!supabaseUrl) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Supabase URL not configured'
    })
  }

  try {
    // Créer un client Supabase avec la service key (accès admin)
    const { createClient } = await import('@supabase/supabase-js')
    const supabaseAdmin = createClient(supabaseUrl, serviceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Récupérer tous les utilisateurs depuis auth.users
    const { data: { users }, error } = await supabaseAdmin.auth.admin.listUsers()

    if (error) {
      throw error
    }

    // Récupérer les statistiques de séances pour tous les utilisateurs avec des requêtes SQL optimisées
    const userIds = users.map(u => u.id)
    
    // Compter les séances créées (workoutsession) par utilisateur avec GROUP BY
    const { data: workoutSessionsData, error: workoutError } = await supabaseAdmin
      .from('workoutsession')
      .select('user_id')
    
    // Compter les séances effectuées (performedsession) par utilisateur
    const { data: performedSessionsData, error: performedError } = await supabaseAdmin
      .from('performedsession')
      .select('user_id')
    
    // Récupérer les comptes supprimés depuis account_deletion_log
    const { data: deletedAccounts, error: deletedError } = await supabaseAdmin
      .from('account_deletion_log')
      .select('email, deleted_at, user_id')
    
    if (workoutError) {
      console.warn('Erreur lors du comptage des séances créées:', workoutError)
    }
    
    if (performedError) {
      console.warn('Erreur lors du comptage des séances effectuées:', performedError)
    }
    
    if (deletedError) {
      console.warn('Erreur lors de la récupération des comptes supprimés:', deletedError)
    }
    
    // Créer des maps pour un accès rapide O(1)
    const workoutSessionsMap = new Map()
    if (workoutSessionsData) {
      workoutSessionsData.forEach(session => {
        if (session.user_id) {
          const count = workoutSessionsMap.get(session.user_id) || 0
          workoutSessionsMap.set(session.user_id, count + 1)
        }
      })
    }
    
    const performedSessionsMap = new Map()
    if (performedSessionsData) {
      performedSessionsData.forEach(session => {
        if (session.user_id) {
          const count = performedSessionsMap.get(session.user_id) || 0
          performedSessionsMap.set(session.user_id, count + 1)
        }
      })
    }
    
    // Map des comptes supprimés (par email et user_id)
    const deletedAccountsMap = new Map()
    if (deletedAccounts) {
      deletedAccounts.forEach(deleted => {
        // Indexer par email (principal)
        if (deleted.email) {
          deletedAccountsMap.set(deleted.email.toLowerCase(), {
            deleted_at: deleted.deleted_at,
            user_id: deleted.user_id
          })
        }
        // Indexer aussi par user_id si disponible
        if (deleted.user_id) {
          deletedAccountsMap.set(deleted.user_id, {
            deleted_at: deleted.deleted_at,
            email: deleted.email
          })
        }
      })
    }

    // Formater les données pour l'affichage
    const formattedUsers = users.map(user => {
      const userEmail = user.email?.toLowerCase() || ''
      const deletedInfo = deletedAccountsMap.get(userEmail) || deletedAccountsMap.get(user.id)
      
      return {
        id: user.id,
        email: user.email || 'N/A',
        first_name: user.user_metadata?.first_name || '',
        last_name: user.user_metadata?.last_name || '',
        full_name: `${user.user_metadata?.first_name || ''} ${user.user_metadata?.last_name || ''}`.trim() || 'N/A',
        created_at: user.created_at,
        last_sign_in_at: user.last_sign_in_at,
        email_confirmed_at: user.email_confirmed_at,
        is_active: !user.banned_at,
        workout_sessions_count: workoutSessionsMap.get(user.id) || 0,
        performed_sessions_count: performedSessionsMap.get(user.id) || 0,
        is_deleted: !!deletedInfo,
        deleted_at: deletedInfo?.deleted_at || null
      }
    })

    return {
      success: true,
      count: formattedUsers.length,
      users: formattedUsers
    }
  } catch (error: any) {
    console.error('Error fetching users:', error)
    throw createError({
      statusCode: 500,
      statusMessage: error.message || 'Failed to fetch users'
    })
  }
})

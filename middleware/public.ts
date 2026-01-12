export default defineNuxtRouteMiddleware(async (to) => {
  // Liste des routes publiques
  const publicRoutes = [
    '/login',
    '/register',
    '/reset-password',
    '/update-password',
    '/check-email',
    '/auth/callback'
  ]

  // Si la route est publique, on laisse passer
  if (publicRoutes.includes(to.path)) {
    return
  }

  // Attendre que la session soit restaurée depuis le localStorage
  // Les plugins s'exécutent après les middlewares, donc on doit attendre manuellement
  if (process.client) {
    const supabase = useSupabaseClient()
    
    // Vérifier d'abord si on a déjà une session
    let { data: sessionData } = await supabase.auth.getSession()
    
    // Si pas de session, attendre un peu et réessayer (pour laisser le temps aux plugins de restaurer)
    if (!sessionData?.session) {
      await new Promise(resolve => setTimeout(resolve, 500))
      sessionData = (await supabase.auth.getSession()).data
    }
    
    // Si toujours pas de session, essayer de rafraîchir
    if (!sessionData?.session) {
      try {
        const { data: refreshData } = await supabase.auth.refreshSession()
        if (refreshData?.session) {
          sessionData = refreshData
        }
      } catch (e) {
        // Ignorer les erreurs de refresh
      }
    }
    
    // Si toujours pas de session après toutes les tentatives, rediriger
    if (!sessionData?.session) {
      return navigateTo('/login')
    }
  } else {
    // Côté serveur, utiliser useSupabaseUser directement
    const user = useSupabaseUser()
    if (!user.value) {
      return navigateTo('/login')
    }
  }
}) 
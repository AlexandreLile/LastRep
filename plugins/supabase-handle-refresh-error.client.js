/**
 * Plugin pour gérer les erreurs de refresh token invalide
 * Nettoie automatiquement le localStorage si le refresh token est invalide
 */
export default defineNuxtPlugin({
  name: 'supabase-handle-refresh-error',
  enforce: 'pre',
  setup(nuxtApp) {
    if (process.client) {
      const supabase = useSupabaseClient()
      
      // Fonction pour nettoyer la session invalide
      const clearInvalidSession = async () => {
        console.warn('🔄 Refresh token invalide, nettoyage de la session...')
        
        // Nettoyer le localStorage des tokens Supabase
        if (typeof window !== 'undefined' && window.localStorage) {
          const keysToRemove = []
          for (let i = 0; i < window.localStorage.length; i++) {
            const key = window.localStorage.key(i)
            if (key && (key.startsWith('sb-') || key.includes('supabase.auth'))) {
              keysToRemove.push(key)
            }
          }
          keysToRemove.forEach(key => window.localStorage.removeItem(key))
          window.localStorage.removeItem('authenticated')
          window.localStorage.removeItem('auth_timestamp')
        }
        
        // Déconnecter proprement
        try {
          await supabase.auth.signOut()
        } catch (e) {
          // Ignorer les erreurs de signOut si la session est déjà invalide
        }
        
        // Rediriger vers login si on n'y est pas déjà
        if (typeof window !== 'undefined' && !window.location.pathname.includes('/login')) {
          window.location.href = '/login'
        }
      }
      
      // Écouter les erreurs réseau qui peuvent indiquer un refresh token invalide
      if (typeof window !== 'undefined' && window.addEventListener) {
        window.addEventListener('unhandledrejection', (event) => {
          const error = event.reason
          const errorMessage = error?.message || error?.toString() || ''
          
          // Détecter les erreurs de refresh token
          if (
            errorMessage.includes('Invalid Refresh Token') ||
            errorMessage.includes('Refresh Token Not Found') ||
            (errorMessage.includes('refresh_token') && errorMessage.includes('400'))
          ) {
            event.preventDefault() // Empêcher l'affichage de l'erreur dans la console
            clearInvalidSession()
          }
        })
      }
      
      // Écouter les changements d'état d'authentification
      supabase.auth.onAuthStateChange((event, session) => {
        // Si on reçoit un événement de déconnexion, c'est normal
        if (event === 'SIGNED_OUT') {
          // Ne rien faire, c'est normal
        }
      })
    }
  }
})

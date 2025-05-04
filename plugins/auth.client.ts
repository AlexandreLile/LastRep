import { useSupabaseClient, useSupabaseUser } from '#imports'

export default defineNuxtPlugin({
  name: 'auth-persistence',
  enforce: 'pre', // Exécuté avant les autres plugins
  async setup() {
    const supabase = useSupabaseClient()
    const user = useSupabaseUser()

    // Vérifier et restaurer la session depuis localStorage
    try {
      // S'assurer que nous sommes côté client
      if (process.client) {
        // Essayer de récupérer la session stockée localement
        const { data, error } = await supabase.auth.getSession()
        
        if (error) {
          console.error('Erreur lors de la récupération de la session:', error.message)
        }
        
        // Si nous avons une session mais pas d'utilisateur, essayer de rafraîchir
        if (data?.session && !user.value) {
          const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession()
          
          if (refreshError) {
            console.error('Erreur lors du rafraîchissement de la session:', refreshError.message)
          }
        }
      }
    } catch (e) {
      console.error('Erreur inattendue lors de la vérification de l\'authentification:', e)
    }
  }
}) 
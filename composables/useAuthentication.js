import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useSupabaseClient } from '#imports'
import { useRouter, useRoute } from 'vue-router'
import { clearCachedUser, clearAllOfflineData } from '~/utils/offlineTraining'

export const useAuthentication = () => {
  const supabase = useSupabaseClient()
  const router = useRouter()
  const route = useRoute()
  
  const user = ref(null)
  const loading = ref(true)
  const initialized = ref(false)
  const error = ref(null)
  
  // État de l'authentification
  const isAuthenticated = computed(() => !!user.value)
  
  // Vérifier si l'utilisateur est authentifié
  const checkAuth = async () => {
    try {
      loading.value = true
      error.value = null
      
      // Récupérer la session
      const { data, error: sessionError } = await supabase.auth.getSession()
      
      if (sessionError) {
        throw sessionError
      }
      
      if (data.session) {
        // Utilisateur authentifié
        user.value = data.session.user
        
        // Stocker l'état d'authentification
        if (process.client && window.localStorage) {
          localStorage.setItem('authenticated', 'true')
          localStorage.setItem('auth_timestamp', Date.now().toString())
        }
      } else {
        // Essayer de récupérer la session
        const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession()
        
        if (!refreshError && refreshData.session) {
          user.value = refreshData.session.user
          
          // Stocker l'état d'authentification
          if (process.client && window.localStorage) {
            localStorage.setItem('authenticated', 'true')
            localStorage.setItem('auth_timestamp', Date.now().toString())
          }
        } else {
          user.value = null
          
          // Effacer l'état d'authentification
          if (process.client && window.localStorage) {
            localStorage.removeItem('authenticated')
            localStorage.removeItem('auth_timestamp')
          }
        }
      }
    } catch (err) {
      console.error('Erreur lors de la vérification de l\'authentification:', err)
      error.value = err.message
      user.value = null
    } finally {
      loading.value = false
      initialized.value = true
    }
  }
  
  // Se connecter
  const login = async (email, password) => {
    try {
      loading.value = true
      error.value = null
      
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
        options: {
          persistSession: true
        }
      })
      
      if (authError) {
        throw authError
      }
      
      user.value = data.user
      
      // Forcer une attente courte pour s'assurer que la session est bien établie
      await new Promise(resolve => setTimeout(resolve, 200))
      
      // Rediriger vers la page d'accueil ou la page précédente
      const redirectTo = route.query.redirect || '/'
      router.push(redirectTo)
      
      return { success: true }
    } catch (err) {
      console.error('Erreur de connexion:', err)
      error.value = err.message
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }
  
  // Se déconnecter
  const logout = async () => {
    try {
      loading.value = true
      
      const { error: signOutError } = await supabase.auth.signOut()
      
      if (signOutError) {
        throw signOutError
      }
      
      user.value = null
      
      // Effacer l'état d'authentification et le cache offline
      if (process.client && window.localStorage) {
        localStorage.removeItem('authenticated')
        localStorage.removeItem('auth_timestamp')
        // Effacer le cache utilisateur pour le mode offline
        clearCachedUser()
        // Optionnel: effacer toutes les données offline (sessions en cours, etc.)
        // clearAllOfflineData()
      }
      
      // Rediriger vers la page de connexion
      router.push('/login')
      
      return { success: true }
    } catch (err) {
      console.error('Erreur de déconnexion:', err)
      error.value = err.message
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }
  
  // Initialiser l'authentification
  onMounted(async () => {
    await checkAuth()
    
    // Écouter les changements d'authentification
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
        if (session) {
          user.value = session.user
        }
      } else if (event === 'SIGNED_OUT') {
        user.value = null
      }
    })
    
    // Nettoyer l'abonnement
    onBeforeUnmount(() => {
      if (subscription) subscription.unsubscribe()
    })
  })
  
  return {
    user,
    loading,
    initialized,
    error,
    isAuthenticated,
    checkAuth,
    login,
    logout
  }
} 
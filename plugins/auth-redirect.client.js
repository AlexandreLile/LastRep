export default defineNuxtPlugin({
  name: 'auth-redirect',
  enforce: 'post', // S'exécute après les plugins 'pre' comme supabase-init
  async setup(nuxtApp) {
    // Ce plugin s'exécute côté client pour gérer les redirections d'authentification
    const router = useRouter();
    const route = useRoute();
  
    if (process.client) {
    // Liste des pages qui ne nécessitent pas d'authentification
    const publicPages = [
      '/login',
      '/register',
      '/reset-password',
      '/update-password',
      '/check-email',
      '/auth/callback'
    ];
    
    router.beforeEach(async (to, from, next) => {
      // Attendre que le DOM soit prêt et que Supabase soit initialisé
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Vérifier si la page est publique
      const isPublicPage = publicPages.some(page => to.path.startsWith(page));
      
      try {
        const supabase = useSupabaseClient();
        
        // Si on vient de la page de callback, attendre un peu plus pour laisser la session s'établir
        if (from.path === '/auth/callback') {
          await new Promise(resolve => setTimeout(resolve, 500));
        }
        
        // Essayer de récupérer la session avec plusieurs tentatives pour gérer le refresh
        let session = null;
        let attempts = 0;
        const maxAttempts = 3;
        
        while (attempts < maxAttempts && !session) {
          const { data, error } = await supabase.auth.getSession();
          
          if (error) {
            console.error('Erreur lors de la récupération de la session:', error);
            break;
          }
          
          if (data.session) {
            session = data.session;
            break;
          }
          
          // Si pas de session, attendre un peu et réessayer (pour gérer le refresh)
          if (attempts < maxAttempts - 1) {
            await new Promise(resolve => setTimeout(resolve, 200));
          }
          attempts++;
        }
        
        // Si toujours pas de session après les tentatives, essayer de rafraîchir
        if (!session) {
          try {
            const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
            if (!refreshError && refreshData.session) {
              session = refreshData.session;
            }
          } catch (refreshErr) {
            console.warn('Impossible de rafraîchir la session:', refreshErr);
          }
        }
        
        // Utilisateur non authentifié tentant d'accéder à une page protégée
        if (!session && !isPublicPage) {
          console.log('Redirection vers login: utilisateur non authentifié sur page protégée');
          return next({
            path: '/login',
            query: { redirect: to.fullPath }
          });
        }
        
        // Utilisateur authentifié tentant d'accéder à une page d'authentification
        // Ne pas rediriger si on vient de se connecter (pour éviter une boucle)
        if (session && isPublicPage && to.path !== '/auth/callback' && from.path !== '/auth/callback') {
          console.log('Redirection vers accueil: utilisateur authentifié sur page publique');
          return next('/');
        }
        
        // Dans tous les autres cas, continuer
        return next();
      } catch (err) {
        console.error('Erreur lors de la vérification d\'authentification:', err);
        
        // En cas d'erreur sur une page protégée, rediriger vers login
        // Sauf si on est sur le callback ou qu'on vient du callback
        if (!isPublicPage && to.path !== '/auth/callback' && from.path !== '/auth/callback') {
          return next('/login');
        }
        
        // Dans tous les autres cas, continuer
        return next();
      }
    });
    }
  }
}); 
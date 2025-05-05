export default defineNuxtPlugin(async (nuxtApp) => {
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
      // Attendre que le DOM soit prêt
      await new Promise(resolve => setTimeout(resolve, 10));
      
      // Vérifier si la page est publique
      const isPublicPage = publicPages.some(page => to.path.startsWith(page));
      
      try {
        const supabase = useSupabaseClient();
        const { data, error } = await supabase.auth.getSession();
        
        // Utilisateur non authentifié tentant d'accéder à une page protégée
        if (!data.session && !isPublicPage) {
          console.log('Redirection vers login: utilisateur non authentifié sur page protégée');
          return next({
            path: '/login',
            query: { redirect: to.fullPath }
          });
        }
        
        // Utilisateur authentifié tentant d'accéder à une page d'authentification
        if (data.session && isPublicPage && to.path !== '/auth/callback') {
          console.log('Redirection vers accueil: utilisateur authentifié sur page publique');
          return next('/');
        }
        
        // Dans tous les autres cas, continuer
        return next();
      } catch (err) {
        console.error('Erreur lors de la vérification d\'authentification:', err);
        
        // En cas d'erreur sur une page protégée, rediriger vers login
        if (!isPublicPage) {
          return next('/login');
        }
        
        // Dans tous les autres cas, continuer
        return next();
      }
    });
  }
}); 
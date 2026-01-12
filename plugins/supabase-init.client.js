// Plugin pour initialiser Supabase côté client
export default defineNuxtPlugin({
  name: 'supabase-init',
  enforce: 'pre', // S'exécute avant les autres plugins
  async setup(nuxtApp) {
    // Récupérer les instances Supabase
    const supabase = useSupabaseClient();
    const user = useSupabaseUser();
    
    // Attente courte pour s'assurer que le navigateur est prêt
    if (process.client) {
      await new Promise(resolve => setTimeout(resolve, 50));
    }

    // Récupérer la session au démarrage côté client uniquement
    try {
      // Attendre que le plugin de restauration ait fini (s'il existe)
      await new Promise(resolve => setTimeout(resolve, 200));
      
      // Vérifier si nous avons une session active
      let { data, error } = await supabase.auth.getSession();
      
      if (error) {
        console.error('Erreur lors de la récupération de la session initiale:', error);
        // Si erreur avec oauth_client_id, nettoyer le localStorage corrompu
        if (error.message?.includes('oauth_client_id')) {
          console.log('Nettoyage de la session corrompue');
          if (process.client && window.localStorage) {
            localStorage.removeItem('sb-auth-token');
          }
          // Forcer une déconnexion pour nettoyer
          await supabase.auth.signOut();
          return;
        }
        // Pour les autres erreurs, ne pas essayer de rafraîchir si pas de session
        return;
      }
      
      if (data?.session) {
        console.log('Session active détectée au démarrage');
        
        // Vérifier que la session n'est pas expirée
        const expiresAt = data.session.expires_at;
        if (expiresAt && expiresAt * 1000 < Date.now()) {
          console.log('Session expirée, tentative de rafraîchissement');
          try {
            const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
            if (!refreshError && refreshData?.session) {
              data = refreshData;
              console.log('Session rafraîchie avec succès');
            } else {
              console.warn('Impossible de rafraîchir la session expirée');
            }
          } catch (refreshErr) {
            console.warn('Erreur lors du rafraîchissement de la session expirée:', refreshErr);
          }
        }
        
        // Ne pas stocker manuellement - Supabase gère déjà le stockage automatiquement
        // Le stockage manuel cause des problèmes avec oauth_client_id
        if (process.client && window.localStorage) {
          localStorage.setItem('supabase.auth.session.active', 'true');
          localStorage.setItem('supabase.auth.session.timestamp', Date.now().toString());
        }
      } else {
        console.log('Pas de session active au démarrage');
        
        // Ne pas essayer de rafraîchir si pas de session - cela causerait une erreur
        // Supabase restaurera automatiquement la session depuis son stockage si elle existe
        console.log('Pas de session active, Supabase la restaurera automatiquement si disponible');
        
        // Nettoyer les flags si la session n'est plus valide
        if (process.client && window.localStorage) {
          localStorage.removeItem('supabase.auth.session.active');
          localStorage.removeItem('supabase.auth.session.timestamp');
        }
      }
    } catch (err) {
      console.error('Erreur critique lors de l\'initialisation de Supabase:', err);
    }
    
    return {
      provide: {
        supabaseInitialized: true
      }
    };
  }
}); 
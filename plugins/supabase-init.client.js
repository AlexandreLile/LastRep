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
      // Attendre un peu plus pour laisser Supabase initialiser complètement
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Vérifier si nous avons une session active
      let { data, error } = await supabase.auth.getSession();
      
      if (error) {
        console.error('Erreur lors de la récupération de la session initiale:', error);
        // Essayer de rafraîchir même en cas d'erreur
        try {
          const refreshResult = await supabase.auth.refreshSession();
          if (!refreshResult.error && refreshResult.data.session) {
            data = refreshResult.data;
            error = null;
          }
        } catch (refreshErr) {
          console.warn('Impossible de rafraîchir la session:', refreshErr);
        }
      }
      
      if (data?.session) {
        console.log('Session active détectée au démarrage');
        
        // Si on a une session, tenter de la rafraîchir pour s'assurer qu'elle est valide
        try {
          await supabase.auth.refreshSession();
        } catch (refreshErr) {
          console.warn('Erreur lors du rafraîchissement de la session:', refreshErr);
        }
        
        // Stocker les infos de session dans le localStorage pour plus de robustesse
        if (process.client && window.localStorage) {
          localStorage.setItem('supabase.auth.session.active', 'true');
          localStorage.setItem('supabase.auth.session.timestamp', Date.now().toString());
        }
      } else {
        console.log('Pas de session active au démarrage, tentative de récupération');
        
        // Essayer de rafraîchir la session même si getSession ne retourne rien
        // Cela peut récupérer une session depuis le localStorage
        try {
          const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
          
          if (!refreshError && refreshData?.session) {
            console.log('Session récupérée via refreshSession');
            // Stocker les infos de session dans le localStorage
            if (process.client && window.localStorage) {
              localStorage.setItem('supabase.auth.session.active', 'true');
              localStorage.setItem('supabase.auth.session.timestamp', Date.now().toString());
            }
          } else {
            // Vérifier si nous avons des données de session stockées dans le localStorage
            if (process.client && window.localStorage) {
              const hasStoredSession = localStorage.getItem('supabase.auth.session.active') === 'true';
              
              if (hasStoredSession) {
                console.log('Session détectée dans le localStorage, mais refreshSession a échoué');
                // Nettoyer le flag si la session n'est plus valide
                localStorage.removeItem('supabase.auth.session.active');
                localStorage.removeItem('supabase.auth.session.timestamp');
              }
            }
          }
        } catch (refreshErr) {
          console.warn('Erreur lors de la tentative de récupération de session:', refreshErr);
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
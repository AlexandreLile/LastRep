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
        // Essayer de rafraîchir même en cas d'erreur
        try {
          const refreshResult = await supabase.auth.refreshSession();
          if (!refreshResult.error && refreshResult.data.session) {
            data = refreshResult.data;
            error = null;
            console.log('Session récupérée après erreur initiale');
          }
        } catch (refreshErr) {
          console.warn('Impossible de rafraîchir la session:', refreshErr);
        }
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
        
        // Stocker les infos de session dans le localStorage pour plus de robustesse
        if (process.client && window.localStorage) {
          localStorage.setItem('supabase.auth.session.active', 'true');
          localStorage.setItem('supabase.auth.session.timestamp', Date.now().toString());
          // Sauvegarder aussi la session complète
          localStorage.setItem('supabase.auth.session', JSON.stringify(data.session));
        }
      } else {
        console.log('Pas de session active au démarrage');
        
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
              localStorage.setItem('supabase.auth.session', JSON.stringify(refreshData.session));
            }
          } else {
            // Nettoyer les flags si la session n'est plus valide
            if (process.client && window.localStorage) {
              const hasStoredSession = localStorage.getItem('supabase.auth.session.active') === 'true';
              
              if (hasStoredSession) {
                console.log('Session détectée dans le localStorage, mais refreshSession a échoué');
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
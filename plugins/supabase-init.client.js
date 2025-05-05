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
      // Vérifier si nous avons une session active
      const { data, error } = await supabase.auth.getSession();
      
      if (error) {
        console.error('Erreur lors de la récupération de la session initiale:', error);
        return;
      }
      
      if (data?.session) {
        console.log('Session active détectée au démarrage');
        
        // Si on a une session, tenter de la rafraîchir
        await supabase.auth.refreshSession();
        
        // Stocker les infos de session dans le localStorage pour plus de robustesse
        if (process.client && window.localStorage) {
          localStorage.setItem('supabase.auth.session.active', 'true');
          localStorage.setItem('supabase.auth.session.timestamp', Date.now().toString());
        }
      } else {
        console.log('Pas de session active au démarrage');
        
        // Vérifier si nous avons des données de session stockées dans le localStorage
        if (process.client && window.localStorage) {
          const hasStoredSession = localStorage.getItem('supabase.auth.session.active') === 'true';
          
          if (hasStoredSession) {
            console.log('Session détectée dans le localStorage, tentative de récupération');
            // Tenter de récupérer la session à partir des tokens stockés
            await supabase.auth.refreshSession();
          }
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
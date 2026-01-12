export default defineNuxtPlugin(async (nuxtApp) => {
  const supabase = useSupabaseClient();
  const user = useSupabaseUser();

  // Configuration de la persistance maximale de session
  const setupPersistence = async () => {
    try {
      // Forcer la persistance dans le localStorage
      localStorage.setItem('supabase.auth.token', 'persist');
      
      // S'assurer que la persistance est activée dans la configuration
      const { data, error } = await supabase.auth.getSession();
      
      if (data?.session) {
        console.log('Session exists, persistence handled by Supabase');
        // Ne pas stocker manuellement - Supabase gère déjà le stockage automatiquement
        // Le stockage manuel cause des problèmes avec oauth_client_id
      }
    } catch (err) {
      console.error('Error setting up persistence:', err);
    }
  };

  // Configurer les écouteurs d'événements de rafraîchissement
  const setupRefreshListeners = () => {
    // Écouter les changements d'état d'authentification
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      console.log('Auth state changed:', event);
      
      if (event === 'TOKEN_REFRESHED') {
        console.log('Token refreshed successfully');
        // Supabase gère automatiquement le stockage, pas besoin de stocker manuellement
      } else if (event === 'SIGNED_IN') {
        console.log('User signed in, persistence handled by Supabase');
        setupPersistence();
      } else if (event === 'SIGNED_OUT') {
        console.log('User signed out');
        // Nettoyer uniquement nos données personnalisées, pas celles de Supabase
        localStorage.removeItem('supabase.auth.persistence');
        localStorage.removeItem('supabase.auth.session.active');
        localStorage.removeItem('supabase.auth.session.timestamp');
      }
    });

    // Nettoyer l'abonnement quand l'application est déchargée
    nuxtApp.hook('app:unmount', () => {
      console.log('App unmounting, cleaning up Supabase subscription');
      if (subscription) subscription.unsubscribe();
    });

    // Rafraîchir la session périodiquement (toutes les 4 heures au lieu de 12)
    const refreshInterval = setInterval(async () => {
      try {
        // Vérifier d'abord si une session existe
        const { data: sessionData } = await supabase.auth.getSession();
        if (!sessionData?.session) {
          return; // Pas de session, ne pas essayer de rafraîchir
        }
        
        const { data, error } = await supabase.auth.refreshSession();
        if (error) {
          // Si erreur avec oauth_client_id, nettoyer
          if (error.message?.includes('oauth_client_id')) {
            console.log('Cleaning corrupted session on scheduled refresh');
            localStorage.removeItem('sb-auth-token');
            await supabase.auth.signOut();
          } else {
            console.warn('Scheduled refresh error:', error);
          }
        } else if (data.session) {
          console.log('Session refreshed on schedule');
        }
      } catch (err) {
        console.error('Error during scheduled refresh:', err);
      }
    }, 4 * 60 * 60 * 1000); // 4 heures

    // Nettoyer l'intervalle quand l'application est déchargée
    nuxtApp.hook('app:unmount', () => {
      clearInterval(refreshInterval);
    });
  };

  // Récupérer une session - vérifier d'abord si elle existe avant de rafraîchir
  const recoverSession = async () => {
    try {
      // Vérifier d'abord si une session existe
      const { data: sessionData, error: sessionError } = await supabase.auth.getSession();
      
      if (sessionError) {
        // Si erreur avec oauth_client_id, nettoyer le localStorage
        if (sessionError.message?.includes('oauth_client_id')) {
          console.log('Cleaning corrupted session');
          localStorage.removeItem('sb-auth-token');
          return false;
        }
        return false;
      }
      
      // Si pas de session, ne pas essayer de rafraîchir
      if (!sessionData?.session) {
        return false;
      }
      
      // Si session existe, essayer de la rafraîchir
      const { data, error } = await supabase.auth.refreshSession();
      
      if (error) {
        // Si erreur avec oauth_client_id, nettoyer
        if (error.message?.includes('oauth_client_id')) {
          console.log('Cleaning corrupted session after refresh attempt');
          localStorage.removeItem('sb-auth-token');
          await supabase.auth.signOut();
        }
        return false;
      }
      
      if (data.session) {
        console.log('Session refreshed successfully');
        return true;
      }
      
      return false;
    } catch (err) {
      // Ignorer les erreurs silencieusement
      return false;
    }
  };

  // Configurer un gestionnaire d'événements pour rafraîchir la session quand la fenêtre redevient active
  const setupVisibilityListener = () => {
    const handleVisibilityChange = async () => {
      if (document.visibilityState === 'visible') {
        try {
          // Vérifier d'abord si une session existe
          const { data: sessionData } = await supabase.auth.getSession();
          if (!sessionData?.session) {
            return; // Pas de session, ne pas essayer de rafraîchir
          }
          
          const { data, error } = await supabase.auth.refreshSession();
          if (error) {
            // Si erreur avec oauth_client_id, nettoyer
            if (error.message?.includes('oauth_client_id')) {
              console.log('Cleaning corrupted session on visibility change');
              localStorage.removeItem('sb-auth-token');
              await supabase.auth.signOut();
            } else {
              console.warn('Error refreshing on visibility change:', error);
            }
          } else if (data.session) {
            console.log('Session refreshed on visibility change');
          }
        } catch (err) {
          console.error('Error refreshing on visibility change:', err);
        }
      }
    };

    // Ajouter l'écouteur d'événements
    document.addEventListener('visibilitychange', handleVisibilityChange);

    // Nettoyer l'écouteur quand l'application est déchargée
    nuxtApp.hook('app:unmount', () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    });
  };
  
  // Configurer un listener pour les événements beforeunload
  const setupBeforeUnloadListener = () => {
    const handleBeforeUnload = async () => {
      // Supabase gère automatiquement la sauvegarde, pas besoin de stocker manuellement
      // Juste s'assurer que la session est à jour
      await supabase.auth.getSession();
    };
    
    window.addEventListener('beforeunload', handleBeforeUnload);
    
    nuxtApp.hook('app:unmount', () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
    });
  };

  // Vérifier la session initiale et nettoyer si corrompue
  try {
    const { data: sessionData, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      console.warn('Session error detected, cleaning up:', sessionError);
      // Nettoyer le localStorage de Supabase si la session est corrompue
      if (process.client && sessionError.message?.includes('oauth_client_id')) {
        console.log('Cleaning corrupted session from localStorage');
        localStorage.removeItem('sb-auth-token');
        // Forcer une déconnexion
        await supabase.auth.signOut();
      }
      return;
    }
    
    if (sessionData?.session) {
      console.log('User is authenticated, session is valid');
      await setupPersistence();
    } else {
      console.log('No active session');
    }
  } catch (err) {
    console.error('Error checking initial session:', err);
  }

  // Configurer les écouteurs même si l'utilisateur n'est pas encore connecté
  setupRefreshListeners();
  setupVisibilityListener();
  setupBeforeUnloadListener();

  // Forcer la persistance même si l'utilisateur se connecte après le chargement de l'application
  nuxtApp.hook('app:mounted', async () => {
    if (user.value) {
      setupPersistence();
    } else {
      // Vérifier si une session existe avant d'essayer de récupérer
      const { data: sessionData } = await supabase.auth.getSession();
      if (sessionData?.session) {
        // Session existe, on peut essayer de récupérer
        await recoverSession();
      }
    }
  });
  
  // Vérifier et rafraîchir la session à intervalle court pendant les 2 premières minutes
  // pour assurer la stabilité de la session après le chargement initial
  let initialStabilityChecks = 0;
  const stabilityInterval = setInterval(async () => {
    initialStabilityChecks++;
    
    if (initialStabilityChecks >= 4) { // 4 vérifications (30s * 4 = 2min)
      clearInterval(stabilityInterval);
      return;
    }
    
    if (!user.value) {
      // Vérifier d'abord si une session existe
      const { data: sessionData } = await supabase.auth.getSession();
      if (sessionData?.session) {
        await recoverSession();
      }
    } else {
      try {
        // Vérifier d'abord si une session existe avant de rafraîchir
        const { data: sessionData } = await supabase.auth.getSession();
        if (sessionData?.session) {
          const { error } = await supabase.auth.refreshSession();
          if (error && error.message?.includes('oauth_client_id')) {
            console.log('Cleaning corrupted session during stability check');
            localStorage.removeItem('sb-auth-token');
            await supabase.auth.signOut();
          } else {
            await setupPersistence();
          }
        }
      } catch (err) {
        console.warn('Error during stability check:', err);
      }
    }
  }, 30 * 1000); // Vérifier toutes les 30 secondes
  
  // Nettoyer l'intervalle si l'application est déchargée
  nuxtApp.hook('app:unmount', () => {
    clearInterval(stabilityInterval);
  });

  // Gérer les événements de chargement de page
  window.addEventListener('load', async () => {
    // Vérifier si l'utilisateur est connecté après le chargement de la page
    const { data, error } = await supabase.auth.getSession();
    if (error && error.message?.includes('oauth_client_id')) {
      console.log('Cleaning corrupted session on page load');
      localStorage.removeItem('sb-auth-token');
      await supabase.auth.signOut();
    } else if (data?.session) {
      await setupPersistence();
    }
    // Ne pas essayer de récupérer si pas de session - cela causerait une erreur
  });

  // Tentative de récupération immédiate avant le montage complet
  await recoverSession();
  
  return {
    provide: {
      enhanceSession: setupPersistence
    }
  }
}); 
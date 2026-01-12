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
        const { data, error } = await supabase.auth.refreshSession();
        if (error) {
          console.error('Scheduled refresh error:', error);
          // Tenter une récupération via la session stockée
          await recoverSession();
        } else if (data.session) {
          console.log('Session refreshed on schedule');
          // Supabase gère automatiquement le stockage
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

  // Récupérer une session - laisser Supabase gérer le stockage automatiquement
  const recoverSession = async () => {
    try {
      // Ne pas essayer de récupérer depuis notre stockage manuel
      // Laisser Supabase utiliser son propre mécanisme (sb-auth-token)
      // Juste essayer de rafraîchir la session si elle existe
      const { data, error } = await supabase.auth.refreshSession();
      
      if (error) {
        // Pas d'erreur si pas de session, c'est normal
        if (!error.message?.includes('session_not_found')) {
          console.warn('Error refreshing session:', error);
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
        console.log('Page became visible, refreshing session');
        try {
          const { data, error } = await supabase.auth.refreshSession();
          if (error) {
            console.warn('Error refreshing on visibility change:', error);
            // Tenter une récupération via la session stockée
            await recoverSession();
          } else if (data.session) {
            console.log('Session refreshed on visibility change');
            // Supabase gère automatiquement le stockage
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

  // Essayer de rafraîchir la session initiale et configurer la persistance
  if (user.value) {
    console.log('User is authenticated, enhancing session persistence');
    
    // Rafraîchir la session actuelle
    try {
      const { data, error } = await supabase.auth.refreshSession();
      if (error) {
        console.error('Initial session refresh error:', error);
        // Tenter une récupération via la session stockée
        const recovered = await recoverSession();
        if (!recovered) {
          console.warn('Could not recover session, will try to set up persistence anyway');
        }
      } else if (data.session) {
        console.log('Initial session refreshed successfully');
      }
      
      // Configurer la persistance de session dans tous les cas
      await setupPersistence();
    } catch (err) {
      console.error('Error refreshing initial session:', err);
    }
  } else {
    // Si pas d'utilisateur actif, tenter une récupération de session
    console.log('No active user, attempting session recovery');
    await recoverSession();
  }

  // Configurer les écouteurs même si l'utilisateur n'est pas encore connecté
  setupRefreshListeners();
  setupVisibilityListener();
  setupBeforeUnloadListener();

  // Forcer la persistance même si l'utilisateur se connecte après le chargement de l'application
  nuxtApp.hook('app:mounted', () => {
    if (user.value) {
      setupPersistence();
    } else {
      // Tenter une récupération de session au montage de l'application
      recoverSession();
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
      await recoverSession();
    } else {
      try {
        await supabase.auth.refreshSession();
        await setupPersistence();
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
    const { data } = await supabase.auth.getSession();
    if (data?.session) {
      await setupPersistence();
    } else {
      await recoverSession();
    }
  });

  // Tentative de récupération immédiate avant le montage complet
  await recoverSession();
  
  return {
    provide: {
      enhanceSession: setupPersistence
    }
  }
}); 
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
        console.log('Session exists, enhancing persistence');
        
        // Stocker explicitement le refresh token dans le localStorage avec une date d'expiration longue
        if (data.session.refresh_token) {
          const persistData = {
            refresh_token: data.session.refresh_token,
            expires_at: new Date().getTime() + (30 * 24 * 60 * 60 * 1000) // 30 jours
          };
          localStorage.setItem('supabase.auth.persistence', JSON.stringify(persistData));
        }
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
      } else if (event === 'SIGNED_IN') {
        console.log('User signed in, setting up persistence');
        setupPersistence();
      } else if (event === 'SIGNED_OUT') {
        console.log('User signed out');
      }
    });

    // Nettoyer l'abonnement quand l'application est déchargée
    nuxtApp.hook('app:unmount', () => {
      console.log('App unmounting, cleaning up Supabase subscription');
      if (subscription) subscription.unsubscribe();
    });

    // Rafraîchir la session périodiquement (toutes les 12 heures)
    const refreshInterval = setInterval(async () => {
      try {
        const { data, error } = await supabase.auth.refreshSession();
        if (error) {
          console.error('Scheduled refresh error:', error);
        } else if (data.session) {
          console.log('Session refreshed on schedule');
        }
      } catch (err) {
        console.error('Error during scheduled refresh:', err);
      }
    }, 12 * 60 * 60 * 1000); // 12 heures

    // Nettoyer l'intervalle quand l'application est déchargée
    nuxtApp.hook('app:unmount', () => {
      clearInterval(refreshInterval);
    });
  };

  // Configurer un gestionnaire d'événements pour rafraîchir la session quand la fenêtre redevient active
  const setupVisibilityListener = () => {
    const handleVisibilityChange = async () => {
      if (document.visibilityState === 'visible') {
        console.log('Page became visible, refreshing session');
        try {
          const { data, error } = await supabase.auth.refreshSession();
          if (!error && data.session) {
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

  // Essayer de rafraîchir la session initiale et configurer la persistance
  if (user.value) {
    console.log('User is authenticated, enhancing session persistence');
    
    // Rafraîchir la session actuelle
    try {
      const { data, error } = await supabase.auth.refreshSession();
      if (error) {
        console.error('Initial session refresh error:', error);
      } else if (data.session) {
        console.log('Initial session refreshed successfully');
        
        // Configurer la persistance de session
        await setupPersistence();
      }
    } catch (err) {
      console.error('Error refreshing initial session:', err);
    }
  }

  // Configurer les écouteurs même si l'utilisateur n'est pas encore connecté
  setupRefreshListeners();
  setupVisibilityListener();

  // Forcer la persistance même si l'utilisateur se connecte après le chargement de l'application
  nuxtApp.hook('app:mounted', () => {
    if (user.value) {
      setupPersistence();
    }
  });
}); 
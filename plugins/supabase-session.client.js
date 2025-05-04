export default defineNuxtPlugin(async (nuxtApp) => {
  const supabase = useSupabaseClient();
  const user = useSupabaseUser();

  // Vérifier si l'utilisateur est connecté
  if (user.value) {
    console.log('User is authenticated, setting up session refresh');
    
    // Configurer la récupération automatique de session
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'TOKEN_REFRESHED') {
        console.log('Token refreshed successfully');
      }
      
      if (event === 'SIGNED_OUT') {
        console.log('User signed out');
      }
    });

    // Essayer de rafraîchir manuellement la session pour s'assurer qu'elle est valide
    try {
      const { data, error } = await supabase.auth.refreshSession();
      if (error) {
        console.error('Session refresh error:', error);
      } else {
        console.log('Session refreshed on app startup');
      }
    } catch (err) {
      console.error('Error refreshing session:', err);
    }

    // Nettoyer l'abonnement quand l'application est déchargée
    // Utilisons le hook de nuxtApp au lieu de onBeforeUnmount
    nuxtApp.hook('app:beforeMount', () => {
      // Ce code s'exécute avant que l'application ne soit montée
    });
    
    // Hook pour le nettoyage
    nuxtApp.hook('app:unmount', () => {
      console.log('App unmounting, cleaning up Supabase subscription');
      if (subscription) subscription.unsubscribe();
    });
  }
}); 
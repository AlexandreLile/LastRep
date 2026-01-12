// Plugin pour restaurer la session Supabase au démarrage depuis le localStorage
export default defineNuxtPlugin({
  name: 'supabase-restore-session',
  enforce: 'pre', // S'exécute en premier, avant supabase-init
  async setup(nuxtApp) {
    if (!process.client) return;
    
    const supabase = useSupabaseClient();
    
    // Ne pas attendre le load complet, restaurer immédiatement
    // Le module Supabase s'initialise déjà rapidement
    await new Promise(resolve => setTimeout(resolve, 50));
    
    try {
      // Vérifier d'abord si Supabase a déjà une session
      const { data: existingSession } = await supabase.auth.getSession();
      
      if (existingSession?.session) {
        console.log('Session déjà présente, pas besoin de restauration');
        return;
      }
      
      // Ne pas essayer de restaurer depuis notre stockage manuel
      // Supabase gère automatiquement le stockage dans 'sb-auth-token'
      // Juste forcer une vérification de session qui déclenchera la restauration automatique
      if (!existingSession?.session) {
        // Essayer de rafraîchir - Supabase restaurera automatiquement depuis son propre stockage
        try {
          const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
          if (refreshError && !refreshError.message?.includes('session_not_found')) {
            console.warn('Erreur lors du rafraîchissement:', refreshError);
          } else if (refreshData?.session) {
            console.log('Session restaurée automatiquement par Supabase');
          }
        } catch (e) {
          // Ignorer silencieusement
        }
      }
      
      // Nettoyer les anciennes données de stockage manuel qui causent des problèmes
      localStorage.removeItem('supabase.auth.session');
      localStorage.removeItem('supabase.auth.persistence');
    } catch (error) {
      console.error('Erreur lors de la restauration de session:', error);
    }
  }
});


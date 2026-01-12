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
      // Vérifier si le stockage Supabase existe et s'il est corrompu
      if (!existingSession?.session) {
        const supabaseStorage = localStorage.getItem('sb-auth-token');
        if (supabaseStorage) {
          try {
            // Vérifier si le stockage est valide
            const parsed = JSON.parse(supabaseStorage);
            // Si le stockage existe mais pas de session, il est peut-être corrompu
            // Ne pas essayer de rafraîchir car cela causerait l'erreur oauth_client_id
            console.log('Stockage Supabase présent mais pas de session active - laisser Supabase gérer');
          } catch (e) {
            // Stockage corrompu, nettoyer
            console.log('Stockage Supabase corrompu, nettoyage');
            localStorage.removeItem('sb-auth-token');
          }
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


// Plugin pour restaurer la session Supabase au démarrage depuis le localStorage
export default defineNuxtPlugin({
  name: 'supabase-restore-session',
  enforce: 'pre', // S'exécute en premier, avant supabase-init
  async setup(nuxtApp) {
    if (!process.client) return;
    
    const supabase = useSupabaseClient();
    
    // Attendre que le navigateur soit prêt
    await new Promise(resolve => {
      if (document.readyState === 'complete') {
        resolve();
      } else {
        window.addEventListener('load', resolve);
      }
    });
    
    // Petit délai supplémentaire pour laisser Supabase s'initialiser
    await new Promise(resolve => setTimeout(resolve, 100));
    
    try {
      // Vérifier d'abord si Supabase a déjà une session
      const { data: existingSession } = await supabase.auth.getSession();
      
      if (existingSession?.session) {
        console.log('Session déjà présente, pas besoin de restauration');
        return;
      }
      
      // Essayer de restaurer depuis le localStorage
      const storedSession = localStorage.getItem('supabase.auth.session');
      
      if (storedSession) {
        try {
          const sessionData = JSON.parse(storedSession);
          
          // Vérifier si la session n'est pas expirée
          if (sessionData.expires_at && sessionData.expires_at < Date.now()) {
            console.log('Session stockée expirée, nettoyage');
            localStorage.removeItem('supabase.auth.session');
            return;
          }
          
          // Essayer de restaurer la session avec le refresh token
          if (sessionData.refresh_token) {
            console.log('Tentative de restauration de session depuis localStorage');
            
            const { data, error } = await supabase.auth.refreshSession({
              refresh_token: sessionData.refresh_token
            });
            
            if (error) {
              console.warn('Erreur lors de la restauration de session:', error);
              // Si le refresh token est invalide, nettoyer
              if (error.message?.includes('refresh_token') || error.message?.includes('invalid')) {
                localStorage.removeItem('supabase.auth.session');
                localStorage.removeItem('supabase.auth.persistence');
              }
            } else if (data.session) {
              console.log('Session restaurée avec succès');
              // Mettre à jour la session stockée
              localStorage.setItem('supabase.auth.session', JSON.stringify(data.session));
            }
          } else if (sessionData.access_token && sessionData.refresh_token) {
            // Essayer de restaurer avec setSession
            console.log('Tentative de restauration avec setSession');
            const { data, error } = await supabase.auth.setSession({
              access_token: sessionData.access_token,
              refresh_token: sessionData.refresh_token
            });
            
            if (error) {
              console.warn('Erreur lors de setSession:', error);
            } else if (data.session) {
              console.log('Session restaurée avec setSession');
            }
          }
        } catch (parseError) {
          console.error('Erreur lors du parsing de la session stockée:', parseError);
          localStorage.removeItem('supabase.auth.session');
        }
      }
      
      // Vérifier aussi le format standard de Supabase (sb-auth-token)
      // Supabase stocke la session dans localStorage avec une clé spécifique
      const supabaseStorageKey = 'sb-auth-token';
      const supabaseStorage = localStorage.getItem(supabaseStorageKey);
      
      if (supabaseStorage && !existingSession?.session) {
        try {
          const parsed = JSON.parse(supabaseStorage);
          if (parsed && parsed.length > 0) {
            const sessionItem = parsed.find(item => item && item.access_token);
            if (sessionItem) {
              console.log('Session trouvée dans le stockage Supabase standard');
              // La session devrait être automatiquement récupérée par Supabase
              // Mais on peut forcer une vérification
              await supabase.auth.getSession();
            }
          }
        } catch (e) {
          console.warn('Erreur lors de la lecture du stockage Supabase:', e);
        }
      }
    } catch (error) {
      console.error('Erreur lors de la restauration de session:', error);
    }
  }
});


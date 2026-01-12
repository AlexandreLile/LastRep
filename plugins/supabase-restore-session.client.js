// Plugin simplifié - laisser Supabase gérer la restauration automatiquement
export default defineNuxtPlugin({
  name: 'supabase-restore-session',
  enforce: 'pre',
  setup(nuxtApp) {
    // Ne rien faire - laisser Supabase restaurer automatiquement la session
    // Le module @nuxtjs/supabase restaure automatiquement depuis 'sb-auth-token'
    // avec persistSession: true dans la configuration
  }
});

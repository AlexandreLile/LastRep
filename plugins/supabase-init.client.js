// Plugin simplifié - laisser Supabase gérer l'initialisation automatiquement
export default defineNuxtPlugin({
  name: 'supabase-init',
  enforce: 'pre',
  async setup(nuxtApp) {
    // Ne rien faire - laisser Supabase s'initialiser automatiquement
    // Le module @nuxtjs/supabase gère déjà l'initialisation et la restauration de session
  }
});

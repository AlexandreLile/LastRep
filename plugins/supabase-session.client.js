// Plugin simplifié - laisser Supabase gérer la persistance automatiquement
// Le module @nuxtjs/supabase gère déjà la persistance avec persistSession: true
export default defineNuxtPlugin({
  name: 'supabase-session',
  enforce: 'post',
  setup(nuxtApp) {
    // Ne rien faire - laisser Supabase gérer automatiquement la persistance
    // Le module @nuxtjs/supabase restaure automatiquement la session depuis le localStorage
    // avec la clé 'sb-auth-token' configurée dans nuxt.config.ts
  }
});

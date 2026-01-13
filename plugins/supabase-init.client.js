// Plugin pour s'assurer que les variables d'environnement sont bien chargées
export default defineNuxtPlugin({
  name: 'supabase-init',
  enforce: 'pre',
  async setup(nuxtApp) {
    // Vérifier que les variables sont bien définies
    const config = useRuntimeConfig()
    const supabaseUrl = config.public.supabaseUrl || process.env.SUPABASE_URL || process.env.NUXT_PUBLIC_SUPABASE_URL
    const supabaseKey = config.public.supabaseAnonKey || process.env.SUPABASE_KEY || process.env.SUPABASE_ANON_KEY || process.env.NUXT_PUBLIC_SUPABASE_KEY
    
    if (!supabaseUrl || !supabaseKey) {
      console.error('❌ Variables Supabase manquantes:', {
        supabaseUrl: !!supabaseUrl,
        supabaseKey: !!supabaseKey,
        env: {
          SUPABASE_URL: !!process.env.SUPABASE_URL,
          SUPABASE_KEY: !!process.env.SUPABASE_KEY,
          NUXT_PUBLIC_SUPABASE_URL: !!process.env.NUXT_PUBLIC_SUPABASE_URL,
          NUXT_PUBLIC_SUPABASE_KEY: !!process.env.NUXT_PUBLIC_SUPABASE_KEY,
        }
      })
    }
  }
});

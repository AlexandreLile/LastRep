import tailwindcss from "@tailwindcss/vite";
import { defineNuxtConfig } from 'nuxt/config'
import { config } from 'dotenv'
import { resolve } from 'path'

// Charger explicitement le fichier .env.local
config({ path: resolve(process.cwd(), '.env.local') })

// Charger les variables d'environnement explicitement
const supabaseUrl = process.env.SUPABASE_URL || process.env.NUXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_KEY || process.env.NUXT_PUBLIC_SUPABASE_KEY

// Debug: vérifier que les variables sont chargées
if (!supabaseUrl || !supabaseKey) {
  console.warn('⚠️ Variables Supabase manquantes:', {
    SUPABASE_URL: !!process.env.SUPABASE_URL,
    SUPABASE_ANON_KEY: !!process.env.SUPABASE_ANON_KEY,
    SUPABASE_KEY: !!process.env.SUPABASE_KEY,
    NUXT_PUBLIC_SUPABASE_URL: !!process.env.NUXT_PUBLIC_SUPABASE_URL,
    NUXT_PUBLIC_SUPABASE_KEY: !!process.env.NUXT_PUBLIC_SUPABASE_KEY,
  })
}

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2024-11-01",
  devtools: { enabled: false },
  css: ["~/assets/css/tailwind.css"],
  pages: true,

  vite: {
    plugins: [tailwindcss()],
  },

  modules: ["shadcn-nuxt", "@nuxtjs/supabase"],
  shadcn: {
    /**
     * Prefix for all the imported component
     */
    prefix: "",
    /**
     * Directory that the component lives in.
     * @default "./components/ui"
     */
    componentDir: "./components/ui",
  },

  // Configuration runtime pour exposer les variables d'environnement
  runtimeConfig: {
    // Variables privées (côté serveur uniquement)
    supabase: {
      serviceKey: process.env.SUPABASE_SERVICE_KEY,
      url: process.env.SUPABASE_URL || process.env.NUXT_PUBLIC_SUPABASE_URL,
    },
    // Variables publiques (accessibles côté client)
    public: {
      supabase: {
        url: process.env.NUXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL,
        key: process.env.NUXT_PUBLIC_SUPABASE_KEY || process.env.SUPABASE_KEY || process.env.SUPABASE_ANON_KEY,
      },
      // Fallback pour compatibilité
      supabaseUrl: process.env.NUXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL,
      supabaseAnonKey: process.env.NUXT_PUBLIC_SUPABASE_KEY || process.env.SUPABASE_KEY || process.env.SUPABASE_ANON_KEY,
    }
  },

  supabase: {
    // Forcer les variables d'environnement si elles ne sont pas chargées automatiquement
    ...(supabaseUrl && supabaseKey ? {
      url: supabaseUrl,
      key: supabaseKey,
    } : {}),
    redirect: false, // Désactiver les redirections automatiques du module, on gère ça manuellement
    redirectOptions: {
      login: "/login",
      callback: "/auth/callback",
      exclude: [
        "/reset-password",
        "/update-password",
        "/register",
        "/check-email",
        "/auth/callback",
      ],
    },
    useSsrCookies: false,
    cookieOptions: {
      maxAge: 60 * 60 * 24 * 30, // 30 jours en secondes
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production"
    },
    clientOptions: {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        // Ne pas spécifier storage explicitement - laisser Supabase utiliser localStorage par défaut
        // storage: typeof window !== 'undefined' ? window.localStorage : undefined,
        // storageKey: 'sb-auth-token', // Laisser la clé par défaut
        flowType: 'pkce',
        // Gérer les erreurs de refresh token
        storage: typeof window !== 'undefined' ? window.localStorage : undefined,
        storageKey: 'sb-auth-token'
      }
    },
    serviceKey: process.env.SUPABASE_SERVICE_KEY,
  },

  nitro: {
    routeRules: {
      '/': { ssr: false },
      '/**': { ssr: false },
      // Bloquer les routes admin en production
      '/admin/**': process.env.NODE_ENV === 'production' 
        ? { redirect: { to: '/', statusCode: 404 } }
        : { ssr: false },
      '/api/admin/**': process.env.NODE_ENV === 'production'
        ? { redirect: { to: '/', statusCode: 404 } }
        : {}
    },
    prerender: {
      crawlLinks: false,
      routes: [],
      // Exclure les routes admin du build en production
      exclude: process.env.NODE_ENV === 'production' 
        ? ['/admin/**', '/api/admin/**']
        : []
    },
    // Exclure les fichiers admin du build en production
    ...(process.env.NODE_ENV === 'production' ? {
      publicAssets: {
        exclude: ['admin/**']
      }
    } : {})
  },
  
  ssr: false,
  
  experimental: {
    payloadExtraction: false,
    clientFallback: true,
    renderJsonPayloads: false,
    asyncContext: false
  },
  
  app: {
    head: {
      charset: 'utf-8',
      viewport: 'width=device-width, initial-scale=1',
      title: 'LastRep - Votre compagnon d\'entraînement',
      meta: [
        { name: 'description', content: 'Suivez vos entraînements et progressez avec LastRep' },
        { name: 'theme-color', content: '#FE751C' },
        { name: 'apple-mobile-web-app-capable', content: 'yes' },
        { name: 'apple-mobile-web-app-status-bar-style', content: 'default' },
        { name: 'apple-mobile-web-app-title', content: 'LastRep' },
        { name: 'mobile-web-app-capable', content: 'yes' }
      ],
      link: [
        { rel: 'icon', type: 'image/png', href: '/favicon.png' },
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/favicon.png' },
        { rel: 'apple-touch-icon', sizes: '152x152', href: '/favicon.png' },
        { rel: 'apple-touch-icon', sizes: '144x144', href: '/favicon.png' },
        { rel: 'apple-touch-icon', sizes: '120x120', href: '/favicon.png' },
        { rel: 'apple-touch-icon', sizes: '114x114', href: '/favicon.png' },
        { rel: 'apple-touch-icon', sizes: '76x76', href: '/favicon.png' },
        { rel: 'apple-touch-icon', sizes: '72x72', href: '/favicon.png' },
        { rel: 'apple-touch-icon', sizes: '60x60', href: '/favicon.png' },
        { rel: 'apple-touch-icon', sizes: '57x57', href: '/favicon.png' },
        { rel: 'apple-touch-icon', href: '/favicon.png' },
        { rel: 'manifest', href: '/manifest.json' }
      ]
    },
    pageTransition: false,
    layoutTransition: false,
    keepalive: false
  }
});

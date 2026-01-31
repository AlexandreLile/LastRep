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

  modules: ["shadcn-nuxt", "@nuxtjs/supabase", "@vite-pwa/nuxt"],
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
        flowType: 'pkce'
      }
    },
    serviceKey: process.env.SUPABASE_SERVICE_KEY,
  },

  pwa: {
    registerType: 'autoUpdate',
    // Inclure tous les assets dans le SW
    includeAssets: ['favicon.png', 'logo.png', 'apple-touch-icon.png'],
    manifest: {
      name: 'LastRep',
      short_name: 'LastRep',
      description: "Votre compagnon d'entraînement pour suivre vos progrès",
      start_url: '/',
      display: 'standalone',
      background_color: '#0a0a0a',
      theme_color: '#FE751C',
      orientation: 'portrait',
      icons: [
        {
          src: '/logo-192.png',
          sizes: '192x192',
          type: 'image/png',
          purpose: 'any'
        },
        {
          src: '/logo-512.png',
          sizes: '512x512',
          type: 'image/png',
          purpose: 'any'
        },
        {
          src: '/logo-192.png',
          sizes: '192x192',
          type: 'image/png',
          purpose: 'maskable'
        },
        {
          src: '/logo-512.png',
          sizes: '512x512',
          type: 'image/png',
          purpose: 'maskable'
        }
      ]
    },
    workbox: {
      // Pré-cacher TOUS les fichiers générés par le build
      globPatterns: ['**/*.{js,css,html,ico,png,svg,woff,woff2}'],
      // Fallback pour toutes les navigations SPA
      navigateFallback: '/index.html',
      // Ne pas appliquer le fallback aux appels API
      navigateFallbackDenylist: [
        /^\/api/,
        /supabase\.co/,
        /\.json$/
      ],
      // Activer immédiatement le nouveau SW
      skipWaiting: true,
      clientsClaim: true,
      // Nettoyer les anciens caches
      cleanupOutdatedCaches: true,
      // Runtime caching pour les ressources externes
      runtimeCaching: [
        {
          // Requêtes de navigation - Network First avec fallback cache
          urlPattern: ({ request }) => request.mode === 'navigate',
          handler: 'NetworkFirst',
          options: {
            cacheName: 'pages-cache',
            networkTimeoutSeconds: 3,
            expiration: {
              maxEntries: 50,
              maxAgeSeconds: 60 * 60 * 24 * 7
            }
          }
        },
        {
          // Assets statiques
          urlPattern: /\.(?:js|css)$/i,
          handler: 'StaleWhileRevalidate',
          options: {
            cacheName: 'static-assets',
            expiration: {
              maxEntries: 100,
              maxAgeSeconds: 60 * 60 * 24 * 30
            }
          }
        },
        {
          // Images
          urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp|ico)$/i,
          handler: 'CacheFirst',
          options: {
            cacheName: 'images-cache',
            expiration: {
              maxEntries: 100,
              maxAgeSeconds: 60 * 60 * 24 * 30
            }
          }
        },
        {
          // Polices
          urlPattern: /\.(?:woff|woff2|ttf|eot)$/i,
          handler: 'CacheFirst',
          options: {
            cacheName: 'fonts-cache',
            expiration: {
              maxEntries: 30,
              maxAgeSeconds: 60 * 60 * 24 * 365
            }
          }
        }
      ]
    },
    devOptions: {
      enabled: false
    }
  },

  nitro: {
    routeRules: {
      '/': { ssr: false },
      '/**': { ssr: false }
    },
    prerender: {
      crawlLinks: false,
      routes: []
    }
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
        { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' },
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' },
        { rel: 'apple-touch-icon', sizes: '152x152', href: '/apple-touch-icon.png' },
        { rel: 'apple-touch-icon', sizes: '144x144', href: '/apple-touch-icon.png' },
        { rel: 'apple-touch-icon', sizes: '120x120', href: '/apple-touch-icon.png' },
        { rel: 'apple-touch-icon', sizes: '114x114', href: '/apple-touch-icon.png' },
        { rel: 'apple-touch-icon', sizes: '76x76', href: '/apple-touch-icon.png' },
        { rel: 'apple-touch-icon', sizes: '72x72', href: '/apple-touch-icon.png' },
        { rel: 'apple-touch-icon', sizes: '60x60', href: '/apple-touch-icon.png' },
        { rel: 'apple-touch-icon', sizes: '57x57', href: '/apple-touch-icon.png' }
        // manifest géré automatiquement par @vite-pwa/nuxt
      ]
    },
    pageTransition: false,
    layoutTransition: false,
    keepalive: false
  }
});

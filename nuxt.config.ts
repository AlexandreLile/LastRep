import tailwindcss from "@tailwindcss/vite";
import { defineNuxtConfig } from 'nuxt/config'

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

  supabase: {
    redirectOptions: {
      login: "/login",
      callback: "/auth/callback",
      exclude: [
        "/reset-password",
        "/update-password",
        "/register",
        "/check-email",
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
        storage: typeof window !== 'undefined' ? window.localStorage : undefined,
        storageKey: 'sb-auth-token',
        flowType: 'pkce'
      }
    },
    serviceKey: process.env.SUPABASE_SERVICE_KEY,
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
      link: [
        { rel: 'icon', type: 'image/svg+xml', href: '/Favicone.svg' }
      ]
    },
    pageTransition: false,
    layoutTransition: false,
    keepalive: false
  }
});

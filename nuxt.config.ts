import tailwindcss from "@tailwindcss/vite";
import { defineNuxtConfig } from 'nuxt/config'

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2024-11-01",
  devtools: { enabled: true },
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
    cookieOptions: {
      secure: process.env.NODE_ENV === 'production',
      path: '/',
      maxAge: 60 * 60 * 24 * 7, // 7 jours
      domain: process.env.NODE_ENV === 'production' ? '' : undefined, // Le domaine sera automatiquement défini
      sameSite: 'lax'
    },
    clientOptions: {
      auth: {
        flowType: 'pkce',
        detectSessionInUrl: true,
        persistSession: true,
        autoRefreshToken: true,
      }
    }
  },

  nitro: {
    prerender: {
      crawlLinks: false,
      routes: ["/"],
    },
  },
  experimental: {
    payloadExtraction: false,
  },
});

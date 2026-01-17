/**
 * Middleware Admin - BLOQUE EN PRODUCTION
 * 
 * Ce middleware vérifie que :
 * 1. L'environnement n'est PAS en production
 * 2. L'utilisateur est authentifié
 * 
 * ⚠️ IMPORTANT : Cette route ne doit JAMAIS être accessible en production
 */
export default defineNuxtRouteMiddleware((to) => {
  // BLOQUER EN PRODUCTION - SÉCURITÉ CRITIQUE
  if (process.env.NODE_ENV === 'production') {
    console.error('🚫 ADMIN DASHBOARD: Accès bloqué en production')
    return navigateTo('/')
  }

  // Vérifier que l'utilisateur est authentifié
  const user = useSupabaseUser()
  
  if (!user.value) {
    console.warn('⚠️ ADMIN DASHBOARD: Utilisateur non authentifié')
    return navigateTo('/login?redirect=' + encodeURIComponent(to.fullPath))
  }

  // Optionnel : Vérifier que l'utilisateur est admin
  // Tu peux ajouter une vérification d'email ou de metadata ici
  // Exemple :
  // const adminEmails = ['admin@example.com']
  // if (!adminEmails.includes(user.value.email)) {
  //   return navigateTo('/')
  // }
})

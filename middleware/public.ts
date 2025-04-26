export default defineNuxtRouteMiddleware((to) => {
  // Liste des routes publiques
  const publicRoutes = [
    '/login',
    '/register',
    '/reset-password',
    '/update-password'
  ]

  // Si la route est publique, on laisse passer
  if (publicRoutes.includes(to.path)) {
    return
  }

  // Pour toutes les autres routes, on vérifie l'authentification
  const user = useSupabaseUser()
  if (!user.value) {
    return navigateTo('/login')
  }
}) 
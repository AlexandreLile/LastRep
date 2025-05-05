export default defineNuxtRouteMiddleware(() => {
  const user = useSupabaseUser()
  
  // Si l'utilisateur est connecté et essaie d'accéder aux pages d'authentification
  if (user.value) {
    return navigateTo('/')
  }
}) 
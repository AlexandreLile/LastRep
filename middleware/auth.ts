export default defineNuxtRouteMiddleware((to) => {
  const user = useSupabaseUser()
  
  // Exclure update-password car c'est une page spéciale pour la réinitialisation
  // où l'utilisateur doit être "connecté" temporairement via le hash de réinitialisation
  if (to.path === '/update-password') {
    return
  }
  
  // Si l'utilisateur est connecté et essaie d'accéder aux pages d'authentification
  if (user.value) {
    return navigateTo('/')
  }
}) 
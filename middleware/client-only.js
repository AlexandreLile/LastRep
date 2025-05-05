export default defineNuxtRouteMiddleware((to, from) => {
  // Ce middleware ne fait rien de spécial, mais force le rendu côté client
  // car le middleware s'exécute uniquement côté client lorsque SSR est désactivé
  
  // Forcer l'initialisation des données côté client
  const user = useSupabaseUser();
  
  // Si on est sur une page qui nécessite une authentification mais que l'utilisateur n'est pas connecté
  if (!user.value && !to.path.includes('/login') && !to.path.includes('/register') && 
      !to.path.includes('/reset-password') && !to.path.includes('/update-password') &&
      !to.path.includes('/check-email') && !to.path.includes('/auth/callback')) {
    // Rediriger vers la page de connexion
    return navigateTo('/login');
  }
}); 
export default defineNuxtRouteMiddleware((to) => {
  // Exécuter uniquement côté client
  if (typeof window === 'undefined' || typeof localStorage === 'undefined') {
    return
  }

  // Ne pas rediriger si on est déjà sur une page de training
  if (to.path.includes('/start') || to.path.includes('/exercises/') || to.path.includes('/train')) {
    return
  }

  // Pages d'authentification : ne pas rediriger
  const authPaths = ['/login', '/register', '/reset-password', '/update-password', '/check-email', '/auth/callback']
  if (authPaths.some(path => to.path.includes(path))) {
    return
  }

  // Vérifier si une session est en cours
  try {
    const currentSession = localStorage.getItem('currentSession')
    if (currentSession) {
      const session = JSON.parse(currentSession)
      // Si la session a une date de début mais pas de date de fin, c'est une session en cours
      if (session.started_at && !session.ended_at && session.workout_session_id) {
        console.log('[Session Recovery] Active session found, redirecting to:', session.workout_session_id)
        return navigateTo(`/seances/${session.workout_session_id}/start`)
      }
    }
  } catch (e) {
    console.error('[Session Recovery] Error:', e)
  }
}) 
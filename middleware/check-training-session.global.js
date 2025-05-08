export default defineNuxtRouteMiddleware((to) => {
  // Ne pas rediriger si on est déjà sur la page start ou sur une page d'exercice de la session en cours
  if (to.path.includes('/start') || to.path.includes('/exercises/')) {
    return
  }

  // Vérifier si une session est en cours
  const currentSession = localStorage.getItem('currentSession')
  if (currentSession) {
    try {
      const session = JSON.parse(currentSession)
      // Si la session a une date de début mais pas de date de fin, c'est une session en cours
      if (session.started_at && !session.ended_at) {
        // Rediriger vers la page start de la session en cours
        return navigateTo(`/seances/${session.workout_session_id}/start`)
      }
    } catch (e) {
      console.error('Erreur lors de la vérification de la session:', e)
    }
  }
}) 
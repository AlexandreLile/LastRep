export default defineNuxtRouteMiddleware((to) => {
  // Ne pas exécuter sur le serveur
  if (process.server) return

  // Ne pas vérifier sur la page de démarrage de séance elle-même
  if (to.path.includes('/seances/') && to.path.includes('/start')) return

  // Récupérer la session en cours depuis le localStorage
  const currentSession = localStorage.getItem('currentSession')
  
  if (currentSession) {
    try {
      const sessionData = JSON.parse(currentSession)
      
      // Vérifier si la session a une date de début mais pas de date de fin
      if (sessionData.started_at && !sessionData.ended_at) {
        // Rediriger vers la page de démarrage de la séance
        return navigateTo(`/seances/${sessionData.workout_session_id}/start`)
      }
    } catch (e) {
      console.error('Erreur lors de la vérification de la session:', e)
    }
  }
}) 
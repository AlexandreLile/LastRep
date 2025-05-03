import { ref } from 'vue'

export const usePerformedSession = (supabase) => {
  const performedSession = ref(null)
  const error = ref(null)
  const localSession = ref(null)

  // Charger la session depuis le localStorage au démarrage
  if (process.client) {
    const storedSession = localStorage.getItem('currentSession')
    if (storedSession) {
      localSession.value = JSON.parse(storedSession)
    }
  }

  const prepareSession = (workoutSessionId, userId) => {
    localSession.value = {
      workout_session_id: workoutSessionId,
      user_id: userId,
      started_at: new Date().toISOString()
    }
    // Sauvegarder dans le localStorage
    if (process.client) {
      localStorage.setItem('currentSession', JSON.stringify(localSession.value))
    }
    return localSession.value
  }

  const saveSession = async () => {
    try {
      if (!localSession.value) {
        throw new Error('Aucune session en cours')
      }

      // Créer un objet sans temp_id
      const sessionData = {
        workout_session_id: localSession.value.workout_session_id,
        user_id: localSession.value.user_id,
        started_at: localSession.value.started_at,
        ended_at: new Date().toISOString()
      }

      const { data, error: saveError } = await supabase
        .from('performedsession')
        .insert([sessionData])
        .select()
        .single()

      if (saveError) throw saveError
      performedSession.value = data
      
      // Mettre à jour tous les exerciseSets avec le performed_session_id
      if (data && data.id) {
        const { updateExerciseSetsWithSessionId } = useExerciseSet()
        await updateExerciseSetsWithSessionId(data.id)
      }
      
      localSession.value = null
      // Supprimer du localStorage
      if (process.client) {
        localStorage.removeItem('currentSession')
      }
      return data
    } catch (e) {
      error.value = e.message
      throw e
    }
  }

  const getCurrentSession = () => {
    return localSession.value
  }

  return {
    performedSession,
    error,
    prepareSession,
    saveSession,
    getCurrentSession
  }
} 
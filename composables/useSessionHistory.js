import { ref } from 'vue'

export const useSessionHistory = () => {
  const sessions = ref([])
  const loading = ref(false)
  const error = ref(null)
  
  const loadSessions = async () => {
    try {
      loading.value = true
      error.value = null
      
      const supabase = useSupabaseClient()
      const user = (await supabase.auth.getUser()).data.user
      
      if (!user) {
        throw new Error('Utilisateur non authentifié')
      }
      
      // Récupérer les séances avec le compte des exercices (OPTIMISÉ : une seule requête)
      const { data: sessionData, error: sessionError } = await supabase
        .from('performedsession')
        .select(`
          id,
          workout_session_id,
          started_at,
          ended_at,
          workoutsession (
            id,
            title
          )
        `)
        .eq('user_id', user.id)
        .order('ended_at', { ascending: false })
      
      if (sessionError) throw sessionError
      
      // Récupérer tous les comptes d'exercices en une seule requête (OPTIMISATION N+1)
      const { data: exerciseCounts, error: countError } = await supabase
        .rpc('get_session_exercise_counts', { user_uuid: user.id })
      
      if (countError) {
        console.warn('Erreur lors de la récupération des comptes d\'exercices:', countError)
        // Fallback : continuer sans les comptes
      }
      
      // Créer un map pour accès rapide O(1)
      const exerciseCountMap = new Map()
      if (exerciseCounts) {
        exerciseCounts.forEach(item => {
          exerciseCountMap.set(item.session_id, item.exercise_count)
        })
      }
      
      // Combiner les données
      const sessionsWithExerciseCount = sessionData.map(session => ({
        ...session,
        title: session.workoutsession?.title || 'Séance sans titre',
        exercise_count: exerciseCountMap.get(session.id) || 0
      }))
      
      sessions.value = sessionsWithExerciseCount
    } catch (e) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }
  
  const deleteSession = async (sessionId) => {
    try {
      loading.value = true
      error.value = null
      
      const supabase = useSupabaseClient()
      const user = (await supabase.auth.getUser()).data.user
      
      if (!user) {
        throw new Error('Utilisateur non authentifié')
      }
      
      // Supprimer d'abord les exerciseSets liés à cette session
      const { error: setsError } = await supabase
        .from('exerciseset')
        .delete()
        .eq('performed_session_id', sessionId)
        .eq('user_id', user.id)
      
      if (setsError) throw setsError
      
      // Puis supprimer la session elle-même
      const { error: sessionError } = await supabase
        .from('performedsession')
        .delete()
        .eq('id', sessionId)
        .eq('user_id', user.id)
      
      if (sessionError) throw sessionError
      
      // Mettre à jour la liste des sessions
      sessions.value = sessions.value.filter(session => session.id !== sessionId)
      
      return { success: true }
    } catch (e) {
      error.value = e.message
      return { success: false, error: e.message }
    } finally {
      loading.value = false
    }
  }
  
  return {
    sessions,
    loading,
    error,
    loadSessions,
    deleteSession
  }
} 
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
      
      // Récupérer les séances avec le compte des exercices
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
      
      // Pour chaque session, récupérer le nombre d'exercices distincts
      const sessionsWithExerciseCount = await Promise.all(
        sessionData.map(async (session) => {
          const { data: distinctExercises, error: countError } = await supabase
            .from('exerciseset')
            .select('exercise_id', { count: 'exact', head: false })
            .eq('performed_session_id', session.id)
            .eq('user_id', user.id)
          
          // Compter le nombre d'exercices distincts (valeurs uniques de exercise_id)
          const uniqueExerciseIds = distinctExercises ? 
            [...new Set(distinctExercises.map(set => set.exercise_id))] : 
            [];

          return {
            ...session,
            title: session.workoutsession?.title || 'Séance sans titre',
            exercise_count: uniqueExerciseIds.length
          }
        })
      )
      
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
import { ref } from 'vue'

export const useExerciseSet = () => {
  const exerciseSets = ref([])
  const error = ref(null)
  const loading = ref(false)
  const tempSessionSets = ref([]) // Pour stocker les IDs des sets de la session

  // Initialiser tempSessionSets depuis localStorage si disponible
  if (process.client) {
    const storedSets = localStorage.getItem('tempSessionSets')
    if (storedSets) {
      tempSessionSets.value = JSON.parse(storedSets)
    }
  }

  const addExerciseSet = async (exerciseId, data) => {
    try {
      loading.value = true
      const supabase = useSupabaseClient()
      const user = (await supabase.auth.getUser()).data.user
      
      if (!user) {
        throw new Error('Utilisateur non authentifié')
      }

      const { data: newSet, error: insertError } = await supabase
        .from('exerciseset')
        .insert([
          {
            exercise_id: exerciseId,
            user_id: user.id,
            weight_kg: parseFloat(data.weight),
            reps: parseInt(data.reps),
            rest_seconds: parseInt(data.restTime),
            rpe: data.rpe ? parseFloat(data.rpe) : null,
            note: data.note || null
          }
        ])
        .select()
        .single()

      if (insertError) throw insertError

      // Ajouter l'ID du nouveau set à notre liste temporaire
      if (newSet && newSet.id) {
        tempSessionSets.value.push(newSet.id)
        // Sauvegarder dans localStorage
        if (process.client) {
          localStorage.setItem('tempSessionSets', JSON.stringify(tempSessionSets.value))
        }
      }
      
      exerciseSets.value.push(newSet)
      return { data: newSet, error: null }
    } catch (e) {
      error.value = e.message
      return { data: null, error: e }
    } finally {
      loading.value = false
    }
  }

  const getExerciseSets = async (exerciseId) => {
    try {
      loading.value = true
      const supabase = useSupabaseClient()
      const user = (await supabase.auth.getUser()).data.user
      
      if (!user) {
        throw new Error('Utilisateur non authentifié')
      }

      const { data, error: fetchError } = await supabase
        .from('exerciseset')
        .select('*')
        .eq('exercise_id', exerciseId)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })

      if (fetchError) throw fetchError
      exerciseSets.value = data
      return { data, error: null }
    } catch (e) {
      error.value = e.message
      return { data: null, error: e }
    } finally {
      loading.value = false
    }
  }

  const updateExerciseSetsWithSessionId = async (performedSessionId) => {
    try {
      loading.value = true
      const supabase = useSupabaseClient()
      const user = (await supabase.auth.getUser()).data.user
      
      if (!user) {
        throw new Error('Utilisateur non authentifié')
      }

      // Récupérer la liste des IDs des sets de la session depuis localStorage
      let setIds = []
      if (process.client) {
        const storedSets = localStorage.getItem('tempSessionSets')
        if (storedSets) {
          setIds = JSON.parse(storedSets)
        }
      } else {
        setIds = tempSessionSets.value
      }

      if (setIds.length === 0) {
        return { data: null, error: null }
      }

      // Mettre à jour tous les sets avec le performed_session_id
      const { data, error: updateError } = await supabase
        .from('exerciseset')
        .update({ performed_session_id: performedSessionId })
        .in('id', setIds)
        .eq('user_id', user.id)
        .select()

      if (updateError) throw updateError

      // Effacer la liste temporaire
      tempSessionSets.value = []
      if (process.client) {
        localStorage.removeItem('tempSessionSets')
      }

      return { data, error: null }
    } catch (e) {
      error.value = e.message
      return { data: null, error: e }
    } finally {
      loading.value = false
    }
  }

  return {
    exerciseSets,
    error,
    loading,
    addExerciseSet,
    getExerciseSets,
    updateExerciseSetsWithSessionId
  }
} 
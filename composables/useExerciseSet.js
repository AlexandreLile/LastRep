import { ref } from 'vue'

export const useExerciseSet = () => {
  const exerciseSets = ref([])
  const error = ref(null)
  const loading = ref(false)

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

  return {
    exerciseSets,
    error,
    loading,
    addExerciseSet,
    getExerciseSets
  }
} 
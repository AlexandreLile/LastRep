import { ref } from 'vue'

export const useExerciseStats = () => {
  const exerciseStats = ref([])
  const error = ref(null)
  const loading = ref(false)

  const getExerciseStats = async () => {
    try {
      loading.value = true
      const supabase = useSupabaseClient()
      const user = (await supabase.auth.getUser()).data.user

      if (!user) {
        throw new Error('Utilisateur non authentifié')
      }

      // Nombre de séries par exercice, agrégé côté SQL (évite de rapatrier
      // toutes les lignes exerciseset de l'utilisateur pour les grouper en JS)
      const { data: counts, error: countsError } = await supabase
        .rpc('get_exercise_stats', { user_uuid: user.id })

      if (countsError) throw countsError

      if (!counts || counts.length === 0) {
        exerciseStats.value = []
        return { data: [], error: null }
      }

      // Récupérer les infos des exercices concernés en une seule requête batch
      const exerciseIds = counts.map(c => c.exercise_id)
      const { data: exercises, error: exercisesError } = await supabase
        .from('exercise')
        .select('id, name, primary_muscle, image_url')
        .in('id', exerciseIds)

      if (exercisesError) throw exercisesError

      const exerciseById = new Map((exercises || []).map(ex => [ex.id, ex]))

      const groupedData = counts.map(c => ({
        exercise_id: c.exercise_id,
        exercise: exerciseById.get(c.exercise_id) || null,
        total_sets: Number(c.total_sets) || 0
      }))

      exerciseStats.value = groupedData
      return { data: groupedData, error: null }
    } catch (e) {
      error.value = e.message
      return { data: null, error: e }
    } finally {
      loading.value = false
    }
  }

  return {
    exerciseStats,
    error,
    loading,
    getExerciseStats
  }
} 
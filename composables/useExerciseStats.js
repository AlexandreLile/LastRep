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

      // Récupérer les exercices avec leurs statistiques
      const { data, error: fetchError } = await supabase
        .from('exerciseset')
        .select(`
          exercise_id,
          exercise:exercise_id (
            id,
            name,
            primary_muscle
          )
        `)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })

      if (fetchError) throw fetchError

      // Grouper les résultats côté client
      const groupedData = data.reduce((acc, curr) => {
        const existing = acc.find(item => item.exercise_id === curr.exercise_id)
        if (existing) {
          existing.total_sets = (existing.total_sets || 0) + 1
        } else {
          acc.push({
            exercise_id: curr.exercise_id,
            exercise: curr.exercise,
            total_sets: 1
          })
        }
        return acc
      }, [])

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
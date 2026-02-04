import { ref } from 'vue'
import { useStatsCache } from './useStatsCache'

/**
 * Composable centralisé pour les statistiques utilisateur
 * Utilise le cache pour améliorer les performances
 */
export const useUserStats = () => {
  const supabase = useSupabaseClient()
  const { withCache, invalidate } = useStatsCache()
  const loading = ref(false)
  const error = ref(null)

  /**
   * Récupère les statistiques de séances (total + moyenne hebdomadaire)
   */
  const getSessionStats = async (userId) => {
    return withCache('session_stats', userId, async () => {
      const { data, error: statsError } = await supabase
        .rpc('get_session_stats', { user_uuid: userId })

      if (statsError) throw statsError

      return {
        totalSessions: data[0]?.total_sessions || 0,
        weeklyAverage: data[0]?.weekly_average || 0
      }
    })
  }

  /**
   * Récupère la durée totale d'entraînement
   */
  const getTotalTrainingTime = async (userId) => {
    return withCache('training_time', userId, async () => {
      const { data, error: durationError } = await supabase
        .rpc('get_total_training_time', { user_uuid: userId })

      if (durationError) throw durationError

      return {
        totalMinutes: data[0]?.total_minutes || 0
      }
    })
  }

  /**
   * Récupère le poids total soulevé
   */
  const getTotalWeight = async (userId) => {
    return withCache('total_weight', userId, async () => {
      const { data, error: weightError } = await supabase
        .rpc('get_total_weight', { user_uuid: userId })

      if (weightError) throw weightError

      return {
        totalWeight: data[0]?.total_weight || 0
      }
    })
  }

  /**
   * Récupère le nombre de séances (pour calculer les moyennes)
   */
  const getSessionCount = async (userId) => {
    return withCache('session_count', userId, async () => {
      const { count, error: sessionError } = await supabase
        .from('performedsession')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)

      if (sessionError) throw sessionError

      return {
        count: count || 0
      }
    })
  }

  /**
   * Récupère toutes les stats en une seule fois (optimisé)
   */
  const getAllStats = async (userId) => {
    try {
      loading.value = true
      error.value = null

      const [sessionStats, trainingTime, totalWeight, sessionCount] = await Promise.all([
        getSessionStats(userId),
        getTotalTrainingTime(userId),
        getTotalWeight(userId),
        getSessionCount(userId)
      ])

      return {
        sessionStats,
        trainingTime,
        totalWeight,
        sessionCount: sessionCount.count,
        averageDuration: sessionCount.count > 0 
          ? Math.round(trainingTime.totalMinutes / sessionCount.count) 
          : 0,
        averageWeight: sessionCount.count > 0 
          ? Math.round(totalWeight.totalWeight / sessionCount.count) 
          : 0
      }
    } catch (e) {
      error.value = e.message
      throw e
    } finally {
      loading.value = false
    }
  }

  /**
   * Invalide le cache pour un utilisateur (appelé après une nouvelle séance)
   */
  const invalidateUserCache = (userId) => {
    invalidate('session_stats', userId)
    invalidate('training_time', userId)
    invalidate('total_weight', userId)
    invalidate('session_count', userId)
  }

  return {
    loading,
    error,
    getSessionStats,
    getTotalTrainingTime,
    getTotalWeight,
    getSessionCount,
    getAllStats,
    invalidateUserCache
  }
}

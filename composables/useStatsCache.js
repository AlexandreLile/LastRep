import { ref } from 'vue'

/**
 * Système de cache pour les statistiques
 * Améliore les performances en évitant les requêtes répétées
 */
const cache = ref(new Map())
const CACHE_TTL = 5 * 60 * 1000 // 5 minutes en millisecondes

export const useStatsCache = () => {
  /**
   * Génère une clé de cache basée sur le type et l'utilisateur
   */
  const getCacheKey = (type, userId) => `${type}_${userId}`

  /**
   * Vérifie si les données sont en cache et valides
   */
  const getCached = (type, userId) => {
    const key = getCacheKey(type, userId)
    const cached = cache.value.get(key)
    
    if (!cached) return null
    
    const now = Date.now()
    if (now - cached.timestamp > CACHE_TTL) {
      // Cache expiré
      cache.value.delete(key)
      return null
    }
    
    return cached.data
  }

  /**
   * Met en cache les données
   */
  const setCached = (type, userId, data) => {
    const key = getCacheKey(type, userId)
    cache.value.set(key, {
      data,
      timestamp: Date.now()
    })
  }

  /**
   * Invalide le cache pour un type spécifique
   */
  const invalidate = (type, userId) => {
    const key = getCacheKey(type, userId)
    cache.value.delete(key)
  }

  /**
   * Invalide tout le cache
   */
  const clear = () => {
    cache.value.clear()
  }

  /**
   * Wrapper pour une fonction async avec cache
   */
  const withCache = async (type, userId, fetchFn) => {
    // Vérifier le cache d'abord
    const cached = getCached(type, userId)
    if (cached !== null) {
      return cached
    }

    // Récupérer les données
    const data = await fetchFn()
    
    // Mettre en cache
    setCached(type, userId, data)
    
    return data
  }

  return {
    getCached,
    setCached,
    invalidate,
    clear,
    withCache
  }
}

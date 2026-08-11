import { ref } from 'vue'

/**
 * Système de cache pour les statistiques
 * Améliore les performances en évitant les requêtes répétées
 */
const cache = ref(new Map())
const CACHE_TTL = 5 * 60 * 1000 // 5 minutes en millisecondes

// Requêtes en cours par clé, pour éviter que plusieurs composants montés en
// concurrence (ex: dashboard) ne déclenchent chacun leur propre requête
// avant que la première n'ait eu le temps de poser le cache.
const inFlight = new Map()

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

    // Réutiliser la requête déjà en cours pour cette clé, s'il y en a une
    const key = getCacheKey(type, userId)
    if (inFlight.has(key)) {
      return inFlight.get(key)
    }

    const promise = (async () => {
      try {
        const data = await fetchFn()
        setCached(type, userId, data)
        return data
      } finally {
        inFlight.delete(key)
      }
    })()

    inFlight.set(key, promise)
    return promise
  }

  return {
    getCached,
    setCached,
    invalidate,
    clear,
    withCache
  }
}

// ============================================
// UTILITAIRES OFFLINE - Pattern Local-First
// ============================================
// Toutes les données d'entraînement sont stockées localement
// Sync vers la DB uniquement à la fin de la session

const isClient = () => typeof window !== 'undefined'

// ============================================
// HELPERS LOCALSTORAGE
// ============================================
const readJson = (key, fallback) => {
  if (!isClient()) return fallback
  try {
    const raw = localStorage.getItem(key)
    return raw ? JSON.parse(raw) : fallback
  } catch (e) {
    return fallback
  }
}

const writeJson = (key, value) => {
  if (!isClient()) return false
  try {
    localStorage.setItem(key, JSON.stringify(value))
    return true
  } catch (e) {
    // Si quota dépassé, nettoyer les vieux caches
    if (e.name === 'QuotaExceededError') {
      cleanupOldCache()
      try {
        localStorage.setItem(key, JSON.stringify(value))
        return true
      } catch (e2) {}
    }
    return false
  }
}

const removeKey = (key) => {
  if (!isClient()) return
  try {
    localStorage.removeItem(key)
  } catch (e) {}
}

// Nettoie les caches anciens
const cleanupOldCache = () => {
  if (!isClient()) return
  const keysToRemove = []
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i)
    if (key?.startsWith('offline:') && !key.includes('pending') && !key.includes('sessionSets') && !key.includes('cachedUser')) {
      keysToRemove.push(key)
    }
  }
  keysToRemove.forEach(k => localStorage.removeItem(k))
}

// ============================================
// CLÉS LOCALSTORAGE
// ============================================
const sessionSetsKey = (sessionId) => `offline:sessionSets:${sessionId}`
const pendingSessionsKey = 'offline:pendingPerformedSessions'
const cachedUserKey = 'offline:cachedUser'
const personalBestKey = (exerciseId) => `offline:personalBest:${exerciseId}`

// ============================================
// GESTION DES SETS DE SESSION
// ============================================
export const getSessionSets = (sessionId) => readJson(sessionSetsKey(sessionId), [])

export const saveSessionSets = (sessionId, sets) => writeJson(sessionSetsKey(sessionId), sets)

export const addSessionSet = (sessionId, set) => {
  const sets = getSessionSets(sessionId)
  sets.unshift(set)
  saveSessionSets(sessionId, sets)
  return sets
}

export const updateSessionSet = (sessionId, setId, updates) => {
  const sets = getSessionSets(sessionId)
  const updated = sets.map(s => s.id === setId ? { ...s, ...updates } : s)
  saveSessionSets(sessionId, updated)
  return updated
}

export const removeSessionSet = (sessionId, setId) => {
  const sets = getSessionSets(sessionId)
  const updated = sets.filter(s => s.id !== setId)
  saveSessionSets(sessionId, updated)
  return updated
}

export const clearSessionSets = (sessionId) => removeKey(sessionSetsKey(sessionId))

// ============================================
// GESTION DES SESSIONS EN ATTENTE
// ============================================
export const getPendingSessions = () => readJson(pendingSessionsKey, [])
export const savePendingSessions = (sessions) => writeJson(pendingSessionsKey, sessions)

// ============================================
// CACHE UTILISATEUR
// ============================================
export const cacheUser = (user) => {
  if (!user) return
  writeJson(cachedUserKey, {
    id: user.id,
    email: user.email,
    cachedAt: new Date().toISOString()
  })
}

export const getCachedUser = () => readJson(cachedUserKey, null)
export const clearCachedUser = () => removeKey(cachedUserKey)

// Wrapper pour obtenir l'utilisateur (priorité au cache)
export const getOfflineUser = async (supabase) => {
  // 1. Cache si offline évident
  if (!isOnline()) {
    return getCachedUser()
  }
  
  // 2. Cache récent (< 5 min)
  const cached = getCachedUser()
  if (cached?.cachedAt) {
    const age = Date.now() - new Date(cached.cachedAt).getTime()
    if (age < 5 * 60 * 1000) return cached
  }
  
  // 3. Supabase avec timeout court
  try {
    const result = await Promise.race([
      supabase.auth.getUser(),
      new Promise((_, reject) => setTimeout(() => reject(new Error('TIMEOUT')), 2000))
    ])
    
    if (result?.data?.user) {
      cacheUser(result.data.user)
      return result.data.user
    }
  } catch (e) {}
  
  return cached
}

// ============================================
// CACHE RECORDS PERSONNELS
// ============================================
export const cachePersonalBest = (exerciseId, bestSet) => {
  if (!exerciseId) return
  writeJson(personalBestKey(exerciseId), bestSet)
}

export const getCachedPersonalBest = (exerciseId) => readJson(personalBestKey(exerciseId), null)

// ============================================
// JOURNAL DES RECORDS (pour le streak hebdomadaire)
// ============================================
// Stocké localement uniquement (device-first) : pas de sync serveur,
// donc le compteur repart de zéro si l'utilisateur change d'appareil
// ou vide son stockage local.
const recordEventsKey = 'offline:recordEvents'
const RECORD_EVENTS_MAX_AGE_DAYS = 60

export const logRecordEvent = (exerciseId) => {
  if (!exerciseId) return
  const events = readJson(recordEventsKey, [])
  events.push({ exercise_id: exerciseId, achieved_at: new Date().toISOString() })

  const cutoff = Date.now() - RECORD_EVENTS_MAX_AGE_DAYS * 24 * 60 * 60 * 1000
  const pruned = events.filter((e) => new Date(e.achieved_at).getTime() >= cutoff)
  writeJson(recordEventsKey, pruned)
}

export const getStartOfWeek = (date = new Date()) => {
  const d = new Date(date)
  const day = d.getDay() // 0 = dimanche ... 6 = samedi
  const diffToMonday = day === 0 ? -6 : 1 - day
  d.setDate(d.getDate() + diffToMonday)
  d.setHours(0, 0, 0, 0)
  return d
}

export const getRecordCountSince = (sinceDate) => {
  const events = readJson(recordEventsKey, [])
  return events.filter((e) => new Date(e.achieved_at) >= sinceDate).length
}

// ============================================
// CACHE WORKOUT SESSIONS & EXERCISES
// ============================================
const workoutSessionKey = (sessionId) => `offline:workoutSession:${sessionId}`
const workoutSessionsKey = (userId) => `offline:workoutSessions:${userId}`
const workoutExercisesKey = (sessionId) => `offline:workoutExercises:${sessionId}`
const workoutExerciseKey = (exerciseId) => `offline:workoutExercise:${exerciseId}`

export const cacheWorkoutSession = (sessionId, session) => {
  if (!sessionId) return
  writeJson(workoutSessionKey(sessionId), session)
}

export const getCachedWorkoutSession = (sessionId) => readJson(workoutSessionKey(sessionId), null)

export const cacheWorkoutSessions = (userId, sessions) => {
  if (!userId) return
  writeJson(workoutSessionsKey(userId), sessions)
}

export const getCachedWorkoutSessions = (userId) => readJson(workoutSessionsKey(userId), [])

export const cacheWorkoutExercises = (sessionId, exercises) => {
  if (!sessionId) return
  writeJson(workoutExercisesKey(sessionId), exercises)
}

export const getCachedWorkoutExercises = (sessionId) => readJson(workoutExercisesKey(sessionId), [])

export const cacheWorkoutExercise = (exerciseId, exercise) => {
  if (!exerciseId) return
  writeJson(workoutExerciseKey(exerciseId), exercise)
}

export const getCachedWorkoutExercise = (exerciseId) => readJson(workoutExerciseKey(exerciseId), null)

// ============================================
// UTILITAIRES
// ============================================
export const isOnline = () => {
  if (!isClient()) return true
  return navigator.onLine
}

export const generateLocalId = () => `local-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`

export const isLocalId = (id) => typeof id === 'string' && id.startsWith('local-')

// Vérification de connectivité réelle
export const checkRealConnectivity = async () => {
  if (!isClient()) return true
  if (!navigator.onLine) return false
  
  try {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 2000)
    
    const response = await fetch(`${window.location.origin}/favicon.png?_=${Date.now()}`, {
      method: 'HEAD',
      cache: 'no-store',
      signal: controller.signal
    })
    
    clearTimeout(timeoutId)
    return response.ok
  } catch (e) {
    return false
  }
}

// ============================================
// NETTOYAGE
// ============================================
export const clearAllOfflineData = () => {
  if (!isClient()) return 0
  
  const keysToRemove = []
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i)
    if (key && (key.startsWith('offline:') || key === 'currentSession' || key === 'tempSessionSets')) {
      keysToRemove.push(key)
    }
  }
  
  keysToRemove.forEach(k => localStorage.removeItem(k))
  return keysToRemove.length
}

// Debug: afficher l'état offline
export const debugOfflineState = () => {
  if (!isClient()) return {}
  
  const state = {
    currentSession: readJson('currentSession', null),
    pendingSessions: getPendingSessions(),
    cachedUser: getCachedUser(),
    sessionSetsKeys: []
  }
  
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i)
    if (key?.startsWith('offline:sessionSets:')) {
      const sessionId = key.replace('offline:sessionSets:', '')
      state.sessionSetsKeys.push({
        sessionId,
        count: getSessionSets(sessionId).length
      })
    }
  }
  
  console.log('État offline:', state)
  return state
}

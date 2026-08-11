import { ref } from 'vue'
import { checkRealConnectivity } from '~/utils/offlineTraining'

// ============================================
// COMPOSABLE: usePerformedSession
// Pattern Local-First pour les séances d'entraînement
// ============================================

// État global pour éviter les syncs multiples
let syncInProgress = false
let syncListenerRegistered = false

export const usePerformedSession = (supabase) => {
  const performedSession = ref(null)
  const error = ref(null)
  const localSession = ref(null)
  const saving = ref(false)

  // ============================================
  // INITIALISATION: Charger la session depuis localStorage
  // ============================================
  if (process.client) {
    const stored = localStorage.getItem('currentSession')
    if (stored) {
      try {
        const parsed = JSON.parse(stored)
        // Vérifier que la session est encore active (pas terminée)
        if (parsed.started_at && !parsed.ended_at) {
          localSession.value = parsed
        } else {
          localStorage.removeItem('currentSession')
        }
      } catch (e) {
        localStorage.removeItem('currentSession')
      }
    }
  }

  // ============================================
  // PRÉPARER UNE NOUVELLE SESSION
  // ============================================
  const prepareSession = (workoutSessionId, userId, cycleSlotId = null) => {
    localSession.value = {
      workout_session_id: workoutSessionId,
      user_id: userId,
      started_at: new Date().toISOString(),
      ended_at: null,
      cycle_slot_id: cycleSlotId || null
    }
    if (process.client) {
      localStorage.setItem('currentSession', JSON.stringify(localSession.value))
    }
    return localSession.value
  }

  // ============================================
  // UTILITAIRES LOCALSTORAGE
  // ============================================
  const getSessionSets = (sessionId) => {
    if (!process.client) return []
    try {
      const data = localStorage.getItem(`offline:sessionSets:${sessionId}`)
      return data ? JSON.parse(data) : []
    } catch (e) {
      return []
    }
  }

  const clearSessionSets = (sessionId) => {
    if (process.client) {
      localStorage.removeItem(`offline:sessionSets:${sessionId}`)
    }
  }

  const getPendingSessions = () => {
    if (!process.client) return []
    try {
      const data = localStorage.getItem('offline:pendingPerformedSessions')
      return data ? JSON.parse(data) : []
    } catch (e) {
      return []
    }
  }

  const savePendingSessions = (sessions) => {
    if (process.client) {
      localStorage.setItem('offline:pendingPerformedSessions', JSON.stringify(sessions))
    }
  }

  // ============================================
  // NORMALISER UN SET POUR LA DB
  // ============================================
  const normalizeSetForDB = (set, performedSessionId, userId) => {
    // Copier et nettoyer les propriétés locales
    const { 
      id, offline, local_only, localId, synced, 
      pendingSync, queuedAt, attempts, workoutSessionId,
      ...cleanSet 
    } = set
    
    return {
      ...cleanSet,
      performed_session_id: performedSessionId,
      user_id: userId
    }
  }

  // ============================================
  // RÉCUPÉRER L'UTILISATEUR (cache prioritaire)
  // ============================================
  const getUserId = async () => {
    // 1. Priorité au user_id stocké dans la session locale
    if (localSession.value?.user_id) {
      return localSession.value.user_id
    }
    
    // 2. Cache localStorage
    if (process.client) {
      try {
        const cached = localStorage.getItem('offline:cachedUser')
        if (cached) {
          const user = JSON.parse(cached)
          if (user?.id) return user.id
        }
      } catch (e) {}
    }
    
    // 3. Supabase (avec timeout court)
    try {
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('TIMEOUT')), 2000)
      )
      
      const result = await Promise.race([
        supabase.auth.getUser(),
        timeoutPromise
      ])
      
      if (result?.data?.user?.id) {
        // Mettre en cache pour usage futur
        if (process.client) {
          localStorage.setItem('offline:cachedUser', JSON.stringify({
            id: result.data.user.id,
            email: result.data.user.email,
            cachedAt: new Date().toISOString()
          }))
        }
        return result.data.user.id
      }
    } catch (e) {}
    
    return null
  }

  // ============================================
  // SAUVEGARDER LA SESSION (fin d'entraînement)
  // ============================================
  const saveSession = async () => {
    if (saving.value) return { inProgress: true }
    if (!localSession.value) throw new Error('Aucune session en cours')

    saving.value = true
    
    try {
      // Récupérer l'ID utilisateur
      const userId = await getUserId()
      if (!userId) throw new Error('Utilisateur non authentifié')

      // Auto-rattachement au cycle actif si la séance n'a pas été démarrée depuis un cycle
      if (!localSession.value.cycle_slot_id) {
        try {
          const { data: slots } = await supabase
            .from('cycle_slot')
            .select('id, cycle:cycle_id(ended_at)')
            .eq('workout_session_id', localSession.value.workout_session_id)
          const activeSlot = (slots || []).find(s => s.cycle && s.cycle.ended_at === null)
          if (activeSlot) localSession.value.cycle_slot_id = activeSlot.id
        } catch (_) {}
      }

      // Préparer les données de session
      const sessionData = {
        workout_session_id: localSession.value.workout_session_id,
        user_id: userId,
        started_at: localSession.value.started_at,
        ended_at: new Date().toISOString(),
        ...(localSession.value.cycle_slot_id ? { cycle_slot_id: localSession.value.cycle_slot_id } : {})
      }

      // Récupérer les sets locaux (filtrer les marquages manuels)
      const localSets = getSessionSets(localSession.value.workout_session_id)
      const realSets = localSets.filter(set => !set.manually_marked)

      // Vérifier la connectivité
      const isConnected = await checkRealConnectivity()

      if (!isConnected) {
        // MODE OFFLINE: Mettre en queue pour sync ultérieure
        const pending = getPendingSessions()
        const exists = pending.some(s => 
          s.workout_session_id === sessionData.workout_session_id && 
          s.started_at === sessionData.started_at
        )
        
        if (!exists) {
          pending.push(sessionData)
          savePendingSessions(pending)
        }
        
        // Ne PAS effacer les sets (on en a besoin pour la sync)
        localSession.value = null
        if (process.client) localStorage.removeItem('currentSession')
        
        return { offline: true, setsCount: realSets.length }
      }

      // MODE ONLINE: Sync immédiate
      // D'abord sync les sessions en attente
      await syncPendingSessions()

      // Créer la session performée
      const { data: createdSession, error: sessionError } = await supabase
        .from('performedsession')
        .insert([sessionData])
        .select()
        .single()

      if (sessionError) throw sessionError
      performedSession.value = createdSession

      // Insérer les séries en batch
      if (realSets.length > 0) {
        const setsPayload = realSets.map(set => 
          normalizeSetForDB(set, createdSession.id, userId)
        )
        
        const { error: setsError } = await supabase
          .from('exerciseset')
          .insert(setsPayload)

        if (setsError) throw setsError
      }

      // Nettoyage complet
      const workoutSessionId = localSession.value.workout_session_id
      clearSessionSets(workoutSessionId)
      localSession.value = null
      
      if (process.client) {
        localStorage.removeItem('currentSession')
        localStorage.removeItem('tempSessionSets')
      }

      return performedSession.value
      
    } catch (e) {
      error.value = e.message
      throw e
    } finally {
      saving.value = false
    }
  }

  // ============================================
  // SYNC DES SESSIONS EN ATTENTE
  // ============================================
  const syncPendingSessions = async () => {
    if (syncInProgress) return
    
    const pending = getPendingSessions()
    if (!pending.length) return

    syncInProgress = true
    const remaining = []

    try {
      for (const sessionData of pending) {
        try {
          // Créer la session
          const { data: created, error: err } = await supabase
            .from('performedsession')
            .insert([sessionData])
            .select()
            .single()

          if (err) throw err

          // Récupérer et insérer les sets
          const sets = getSessionSets(sessionData.workout_session_id)
          const realSets = sets.filter(s => !s.manually_marked)
          
          if (realSets.length > 0) {
            const payload = realSets.map(s => 
              normalizeSetForDB(s, created.id, sessionData.user_id)
            )
            
            await supabase.from('exerciseset').insert(payload)
          }

          // Nettoyer les sets de cette session
          clearSessionSets(sessionData.workout_session_id)
          
        } catch (e) {
          // Garder pour réessayer plus tard
          remaining.push(sessionData)
        }
      }

      savePendingSessions(remaining)
    } finally {
      syncInProgress = false
    }
  }

  // ============================================
  // CONFIGURATION SYNC AUTOMATIQUE
  // ============================================
  const setupOfflineSync = () => {
    if (!process.client || syncListenerRegistered) return
    syncListenerRegistered = true
    
    window.addEventListener('online', () => {
      // Délai court pour que la connexion soit stable
      setTimeout(syncPendingSessions, 1000)
    })
    
    // Sync au démarrage si online
    if (navigator.onLine) {
      syncPendingSessions()
    }
  }

  // ============================================
  // GETTERS
  // ============================================
  const getCurrentSession = () => localSession.value

  const hasActiveSession = () => {
    return localSession.value?.started_at && !localSession.value?.ended_at
  }

  return {
    performedSession,
    error,
    prepareSession,
    saveSession,
    getCurrentSession,
    hasActiveSession,
    syncPendingSessions,
    setupOfflineSync
  }
}

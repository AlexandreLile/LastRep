import { ref } from 'vue'

// ─── CALCULS ────────────────────────────────────────────────────────────────

/**
 * Calcule les stats d'une séance réalisée à partir de ses séries.
 * Seules les séries avec weight_kg ET reps contribuent au kg/rep moyen.
 * Les autres types (cardio, isométrie) sont ignorés dans les aggrégats de charge.
 */
const computeSessionStats = (sets) => {
  // Grouper par exercice
  const byExercise = {}
  for (const set of sets) {
    const id = set.exercise_id
    if (!byExercise[id]) byExercise[id] = { exercise: set.exercise, sets: [] }
    byExercise[id].sets.push(set)
  }

  let sessionVolume = 0
  let sessionTotalReps = 0
  const exercises = []

  for (const [exerciseId, { exercise, sets: exSets }] of Object.entries(byExercise)) {
    let exVolume = 0
    let exTotalReps = 0
    let bestSetValue = 0

    for (const s of exSets) {
      const w = parseFloat(s.weight_kg) || 0
      const r = parseInt(s.reps) || 0
      if (w > 0 && r > 0) {
        exVolume += w * r
        exTotalReps += r
        bestSetValue = Math.max(bestSetValue, w * r)
      }
    }

    const kgPerRep = exTotalReps > 0 ? exVolume / exTotalReps : null
    sessionVolume += exVolume
    sessionTotalReps += exTotalReps

    exercises.push({
      exercise_id: exerciseId,
      exercise,
      volume: exVolume,
      total_reps: exTotalReps,
      kg_per_rep: kgPerRep,
      best_set_value: bestSetValue > 0 ? bestSetValue : null,
      sets_count: exSets.length
    })
  }

  return {
    volume: sessionVolume,
    total_reps: sessionTotalReps,
    kg_per_rep: sessionTotalReps > 0 ? sessionVolume / sessionTotalReps : null,
    exercises
  }
}

/**
 * Pour chaque session, calcule les stats et la comparaison avec la précédente
 * occurrence du même créneau.
 * sessions = tableau trié par started_at croissant.
 */
const computeSlotProgression = (sessions) => {
  return sessions.map((session, idx) => {
    const stats = computeSessionStats(session.sets || [])
    const prev = idx > 0 ? computeSessionStats(sessions[idx - 1].sets || []) : null

    const diff = (curr, prevVal) => {
      if (curr == null || prevVal == null || prevVal === 0) return null
      return ((curr - prevVal) / prevVal) * 100
    }

    const comparison = prev
      ? {
          volume_diff_pct: diff(stats.volume, prev.volume),
          kg_per_rep_diff_pct: diff(stats.kg_per_rep, prev.kg_per_rep),
          exercises: stats.exercises.map(ex => {
            const prevEx = prev.exercises.find(e => e.exercise_id === ex.exercise_id)
            return {
              ...ex,
              volume_diff_pct: diff(ex.volume, prevEx?.volume),
              kg_per_rep_diff_pct: diff(ex.kg_per_rep, prevEx?.kg_per_rep)
            }
          })
        }
      : null

    return {
      performed_session_id: session.id,
      started_at: session.started_at,
      ended_at: session.ended_at,
      occurrence: idx + 1,
      stats,
      comparison
    }
  })
}

// ─── COMPOSABLE ─────────────────────────────────────────────────────────────

export const useCycleStats = () => {
  const loading = ref(false)
  const error = ref(null)

  /**
   * Charge et calcule les stats de progression pour un créneau donné.
   * Retourne les occurrences avec comparaison intégrée.
   */
  const fetchSlotProgression = async (slotId) => {
    loading.value = true
    error.value = null
    try {
      const supabase = useSupabaseClient()
      const { data, error: err } = await supabase
        .from('performedsession')
        .select(`
          id, started_at, ended_at,
          sets:exerciseset (
            id, exercise_id, weight_kg, reps,
            exercise:exercise_id (id, name, primary_muscle, measurement_type)
          )
        `)
        .eq('cycle_slot_id', slotId)
        .order('started_at', { ascending: true })

      if (err) throw err

      const progression = computeSlotProgression(data || [])
      return { data: progression, error: null }
    } catch (e) {
      error.value = e.message
      return { data: null, error: e.message }
    } finally {
      loading.value = false
    }
  }

  /**
   * Stats d'une seule séance réalisée (sans comparaison).
   * Utile pour la page de détail d'une performedsession de cycle.
   */
  const fetchPerformedSessionStats = async (performedSessionId, slotId) => {
    loading.value = true
    error.value = null
    try {
      const supabase = useSupabaseClient()

      // Charger toutes les occurrences du créneau pour avoir le contexte de comparaison
      const { data: allSessions, error: err } = await supabase
        .from('performedsession')
        .select(`
          id, started_at, ended_at,
          sets:exerciseset (
            id, exercise_id, weight_kg, reps,
            exercise:exercise_id (id, name, primary_muscle, measurement_type)
          )
        `)
        .eq('cycle_slot_id', slotId)
        .order('started_at', { ascending: true })

      if (err) throw err

      const progression = computeSlotProgression(allSessions || [])
      const result = progression.find(p => p.performed_session_id === performedSessionId)

      return { data: result || null, error: null }
    } catch (e) {
      error.value = e.message
      return { data: null, error: e.message }
    } finally {
      loading.value = false
    }
  }

  /**
   * Différence entre deux mensurations (début/fin).
   * Retourne un objet avec valeur absolue et % pour chaque champ.
   */
  const computeMeasurementDiff = (start, end) => {
    if (!start || !end) return null
    const fields = ['weight_kg', 'arm_cm', 'waist_cm', 'chest_cm', 'thigh_cm', 'calf_cm']
    const result = {}
    for (const field of fields) {
      const s = parseFloat(start[field])
      const e = parseFloat(end[field])
      if (!isNaN(s) && !isNaN(e)) {
        result[field] = {
          start: s,
          end: e,
          diff: e - s,
          diff_pct: s !== 0 ? ((e - s) / s) * 100 : null
        }
      }
    }
    return Object.keys(result).length > 0 ? result : null
  }

  return {
    loading,
    error,
    fetchSlotProgression,
    fetchPerformedSessionStats,
    computeMeasurementDiff
  }
}

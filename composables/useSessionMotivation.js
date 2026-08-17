import { getOfflineUser, cachePersonalBest } from '~/utils/offlineTraining'

// Meilleure série d'un exercice selon son measurement_type — même logique
// que isBetterSet() dans la page de logging, pour rester cohérent avec ce
// qui déclenche une célébration de record.
export const pickBestSet = (sets, measurementType) => {
  if (!sets.length) return null
  const type = measurementType || 'weight_reps'

  if (type === 'time' || type === 'time_reps') {
    return sets.reduce((best, s) => (!best || (s.duration_seconds || 0) > (best.duration_seconds || 0)) ? s : best, null)
  }
  if (type === 'reps') {
    return sets.reduce((best, s) => (!best || (s.reps || 0) > (best.reps || 0)) ? s : best, null)
  }
  if (type === 'distance' || type === 'time_distance') {
    return sets.reduce((best, s) => (!best || (s.distance_meters || 0) > (best.distance_meters || 0)) ? s : best, null)
  }
  return sets.reduce((best, s) => {
    if (!best) return s
    if ((s.weight_kg || 0) > (best.weight_kg || 0)) return s
    if ((s.weight_kg || 0) === (best.weight_kg || 0) && (s.reps || 0) > (best.reps || 0)) return s
    return best
  }, null)
}

// Charge les données motivationnelles d'une séance (records battus la
// dernière fois + records en jeu). Best-effort : ne doit jamais bloquer
// l'affichage appelant si ça échoue.
// `exercises` attend des objets { exercise_id, measurement_type }.
export const loadSessionMotivation = async (supabase, { sessionId, exercises }) => {
  const empty = { isFirstTime: false, lastSessionPrCount: 0, recordsInPlay: 0 }
  try {
    const user = await getOfflineUser(supabase)
    const exerciseIds = exercises.map(e => e.exercise_id).filter(Boolean)
    if (!user || !exerciseIds.length) return empty

    const { data: lastPerformed } = await supabase
      .from('performedsession')
      .select('id')
      .eq('workout_session_id', sessionId)
      .eq('user_id', user.id)
      .not('ended_at', 'is', null)
      .order('ended_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (!lastPerformed) return { isFirstTime: true, lastSessionPrCount: 0, recordsInPlay: 0 }

    const { data: allSets } = await supabase
      .from('exerciseset')
      .select('exercise_id, weight_kg, reps, duration_seconds, distance_meters, created_at, performed_session_id')
      .eq('user_id', user.id)
      .in('exercise_id', exerciseIds)

    const setsByExercise = new Map()
    ;(allSets || []).forEach((s) => {
      if (!setsByExercise.has(s.exercise_id)) setsByExercise.set(s.exercise_id, [])
      setsByExercise.get(s.exercise_id).push(s)
    })

    let recordsInPlay = 0
    let lastSessionPrCount = 0

    exercises.forEach((ex) => {
      const type = ex.measurement_type || 'weight_reps'
      const sets = setsByExercise.get(ex.exercise_id) || []
      if (!sets.length) return

      const best = pickBestSet(sets, type)
      if (!best) return
      recordsInPlay++
      cachePersonalBest(ex.exercise_id, best)
      if (best.performed_session_id === lastPerformed.id) lastSessionPrCount++
    })

    return { isFirstTime: false, lastSessionPrCount, recordsInPlay }
  } catch (e) {
    return empty
  }
}

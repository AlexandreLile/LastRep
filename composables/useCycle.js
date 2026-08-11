import { ref } from 'vue'

export const useCycle = () => {
  const cycles = ref([])
  const loading = ref(false)
  const error = ref(null)

  // ─── CYCLES ──────────────────────────────────────────────────────────────

  const fetchCycles = async () => {
    loading.value = true
    error.value = null
    try {
      const supabase = useSupabaseClient()
      const { data, error: err } = await supabase
        .from('cycle')
        .select(`
          *,
          slots:cycle_slot (
            id, name, slot_order, workout_session_id,
            workout_session:workout_session_id (id, title),
            performed_sessions:performedsession!performedsession_cycle_slot_id_fkey (
              id, started_at, ended_at
            )
          ),
          measurements:cycle_measurement (*)
        `)
        .order('started_at', { ascending: false })

      if (err) throw err
      cycles.value = (data || []).map(normalizeCycle)
      return { data: cycles.value, error: null }
    } catch (e) {
      error.value = e.message
      return { data: null, error: e.message }
    } finally {
      loading.value = false
    }
  }

  const fetchCycle = async (cycleId) => {
    loading.value = true
    error.value = null
    try {
      const supabase = useSupabaseClient()
      const { data, error: err } = await supabase
        .from('cycle')
        .select(`
          *,
          slots:cycle_slot (
            id, name, slot_order, workout_session_id,
            workout_session:workout_session_id (id, title),
            performed_sessions:performedsession!performedsession_cycle_slot_id_fkey (
              id, started_at, ended_at
            )
          ),
          measurements:cycle_measurement (*)
        `)
        .eq('id', cycleId)
        .single()

      if (err) throw err
      return { data: normalizeCycle(data), error: null }
    } catch (e) {
      error.value = e.message
      return { data: null, error: e.message }
    } finally {
      loading.value = false
    }
  }

  const createCycle = async ({ name, started_at, ended_at, slots = [], measurements = {} }) => {
    loading.value = true
    error.value = null
    try {
      const supabase = useSupabaseClient()
      const user = (await supabase.auth.getUser()).data.user
      if (!user) throw new Error('Utilisateur non authentifié')

      // 1. Créer le cycle
      const { data: cycle, error: cycleErr } = await supabase
        .from('cycle')
        .insert({ name, started_at, ended_at: ended_at || null, user_id: user.id })
        .select()
        .single()
      if (cycleErr) throw cycleErr

      // 2. Créer les créneaux si fournis
      if (slots.length > 0) {
        const { error: slotsErr } = await supabase
          .from('cycle_slot')
          .insert(slots.map((s, i) => ({
            cycle_id: cycle.id,
            name: s.name,
            slot_order: i,
            workout_session_id: s.workout_session_id || null
          })))
        if (slotsErr) throw slotsErr
      }

      // 3. Créer la mensuration de début si fournie
      if (measurements.start && hasMeasurementData(measurements.start)) {
        const { error: mErr } = await supabase
          .from('cycle_measurement')
          .insert({
            cycle_id: cycle.id,
            user_id: user.id,
            type: 'start',
            measured_at: started_at,
            ...pickMeasurementFields(measurements.start)
          })
        if (mErr) throw mErr
      }

      await fetchCycles()
      return { success: true, data: cycle }
    } catch (e) {
      error.value = e.message
      return { success: false, error: e.message }
    } finally {
      loading.value = false
    }
  }

  const updateCycle = async (cycleId, updates) => {
    loading.value = true
    error.value = null
    try {
      const supabase = useSupabaseClient()
      const { data, error: err } = await supabase
        .from('cycle')
        .update(updates)
        .eq('id', cycleId)
        .select()
        .single()
      if (err) throw err
      const idx = cycles.value.findIndex(c => c.id === cycleId)
      if (idx !== -1) cycles.value[idx] = { ...cycles.value[idx], ...data }
      return { success: true, data }
    } catch (e) {
      error.value = e.message
      return { success: false, error: e.message }
    } finally {
      loading.value = false
    }
  }

  const deleteCycle = async (cycleId) => {
    loading.value = true
    error.value = null
    try {
      const supabase = useSupabaseClient()
      const { error: err } = await supabase.from('cycle').delete().eq('id', cycleId)
      if (err) throw err
      cycles.value = cycles.value.filter(c => c.id !== cycleId)
      return { success: true }
    } catch (e) {
      error.value = e.message
      return { success: false, error: e.message }
    } finally {
      loading.value = false
    }
  }

  // ─── CRÉNEAUX ────────────────────────────────────────────────────────────

  const createSlot = async (cycleId, { name, slot_order, workout_session_id }) => {
    try {
      const supabase = useSupabaseClient()
      const { data, error: err } = await supabase
        .from('cycle_slot')
        .insert({ cycle_id: cycleId, name, slot_order, workout_session_id: workout_session_id || null })
        .select()
        .single()
      if (err) throw err
      return { success: true, data }
    } catch (e) {
      return { success: false, error: e.message }
    }
  }

  const updateSlot = async (slotId, updates) => {
    try {
      const supabase = useSupabaseClient()
      const { data, error: err } = await supabase
        .from('cycle_slot')
        .update(updates)
        .eq('id', slotId)
        .select()
        .single()
      if (err) throw err
      return { success: true, data }
    } catch (e) {
      return { success: false, error: e.message }
    }
  }

  const deleteSlot = async (slotId) => {
    try {
      const supabase = useSupabaseClient()
      const { data, error: err } = await supabase.from('cycle_slot').delete().eq('id', slotId).select()
      if (err) throw err
      // Une RLS qui ne matche aucune ligne ne renvoie pas d'erreur : on vérifie donc explicitement
      if (!data || data.length === 0) throw new Error('Ce créneau n\'a pas pu être supprimé (introuvable ou accès refusé)')
      return { success: true }
    } catch (e) {
      return { success: false, error: e.message }
    }
  }

  // ─── MENSURATIONS ────────────────────────────────────────────────────────

  const saveMeasurement = async (cycleId, type, fields, measured_at) => {
    try {
      const supabase = useSupabaseClient()
      const user = (await supabase.auth.getUser()).data.user
      if (!user) throw new Error('Utilisateur non authentifié')

      const { data, error: err } = await supabase
        .from('cycle_measurement')
        .upsert(
          {
            cycle_id: cycleId,
            user_id: user.id,
            type,
            measured_at: measured_at || new Date().toISOString().split('T')[0],
            ...pickMeasurementFields(fields)
          },
          { onConflict: 'cycle_id,type' }
        )
        .select()
        .single()
      if (err) throw err
      return { success: true, data }
    } catch (e) {
      return { success: false, error: e.message }
    }
  }

  // ─── LIER UNE SÉANCE RÉALISÉE À UN CRÉNEAU ───────────────────────────────
  // Appelé à la fin d'une séance démarrée depuis un créneau de cycle

  const linkPerformedSessionToSlot = async (performedSessionId, slotId) => {
    try {
      const supabase = useSupabaseClient()
      const { error: err } = await supabase
        .from('performedsession')
        .update({ cycle_slot_id: slotId })
        .eq('id', performedSessionId)
      if (err) throw err
      return { success: true }
    } catch (e) {
      return { success: false, error: e.message }
    }
  }

  // ─── UTILITAIRES ─────────────────────────────────────────────────────────

  const normalizeCycle = (cycle) => ({
    ...cycle,
    slots: [...(cycle.slots || [])].sort((a, b) => a.slot_order - b.slot_order),
    measurement_start: (cycle.measurements || []).find(m => m.type === 'start') || null,
    measurement_end: (cycle.measurements || []).find(m => m.type === 'end') || null
  })

  const MEASUREMENT_FIELDS = ['weight_kg', 'arm_cm', 'waist_cm', 'chest_cm', 'thigh_cm', 'calf_cm']

  const pickMeasurementFields = (obj) =>
    Object.fromEntries(MEASUREMENT_FIELDS.map(k => [k, obj[k] ?? null]))

  const hasMeasurementData = (obj) =>
    MEASUREMENT_FIELDS.some(k => obj[k] != null && obj[k] !== '')

  return {
    cycles,
    loading,
    error,
    fetchCycles,
    fetchCycle,
    createCycle,
    updateCycle,
    deleteCycle,
    createSlot,
    updateSlot,
    deleteSlot,
    saveMeasurement,
    linkPerformedSessionToSlot,
    hasMeasurementData
  }
}

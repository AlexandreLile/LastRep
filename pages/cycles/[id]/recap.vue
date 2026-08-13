<template>
  <div class="relative space-y-6">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8 bg-card rounded-xl p-6">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4" />
      {{ error }}
    </div>

    <template v-else-if="cycle">
      <!-- Header -->
      <div class="bg-card rounded-xl p-6">
        <Button
          variant="outline"
          size="sm"
          class="flex items-center gap-2 mb-4"
          @click="navigateTo('/cycles')"
        >
          <ArrowLeft class="h-4 w-4" /> Cycles
        </Button>
        <div class="flex items-center gap-4">
          <div class="w-14 h-14 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
            <Trophy class="w-7 h-7 text-primary" />
          </div>
          <div>
            <p class="text-xs font-medium text-primary uppercase tracking-wide mb-0.5">Cycle terminé</p>
            <h2 class="text-2xl font-bold">{{ cycle.name }}</h2>
            <p class="text-sm text-muted-foreground mt-0.5">
              {{ formatDate(cycle.started_at) }} → {{ formatDate(cycle.ended_at) }}
              <span class="ml-1 text-muted-foreground/60">· {{ cycleDuration }} jours</span>
            </p>
          </div>
        </div>
      </div>

      <!-- Stats globaux -->
      <div class="grid grid-cols-3 gap-4">
        <div class="bg-card rounded-xl p-6 border border-border text-center">
          <p class="text-2xl font-bold text-foreground">{{ totalSessions }}</p>
          <p class="text-xs text-muted-foreground mt-1">séances</p>
        </div>
        <div class="bg-card rounded-xl p-6 border border-border text-center">
          <div v-if="loadingWeight" class="flex justify-center py-1">
            <div class="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-primary"></div>
          </div>
          <template v-else>
            <p class="text-2xl font-bold text-foreground">{{ formatWeight(totalWeight) }}</p>
            <p class="text-xs text-muted-foreground mt-1">soulevé</p>
          </template>
        </div>
        <div class="bg-card rounded-xl p-6 border border-border text-center">
          <p class="text-2xl font-bold text-foreground">{{ formatDuration(totalMinutes) }}</p>
          <p class="text-xs text-muted-foreground mt-1">d'entraînement</p>
        </div>
      </div>

      <!-- Mensurations -->
      <div v-if="cycle.measurement_start || cycle.measurement_end" class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Ruler class="w-5 h-5 text-primary" />
          </div>
          <h3 class="text-lg font-semibold">Évolution des mensurations</h3>
        </div>

        <div class="space-y-3">
          <div
            v-for="row in measurementRows"
            :key="row.key"
            class="flex items-center justify-between py-2 border-b border-border/50 last:border-0"
          >
            <span class="text-sm text-muted-foreground">{{ row.label }}</span>
            <div class="flex items-center gap-4 text-sm">
              <span v-if="cycle.measurement_start?.[row.key]" class="text-muted-foreground">
                {{ formatMeasure(cycle.measurement_start[row.key], row.unit) }}
              </span>
              <span v-if="cycle.measurement_start && cycle.measurement_end" class="text-muted-foreground">→</span>
              <span v-if="cycle.measurement_end?.[row.key]" class="font-medium">
                {{ formatMeasure(cycle.measurement_end[row.key], row.unit) }}
              </span>
              <span
                v-if="measurementDiff?.[row.key]"
                class="text-xs font-semibold px-2 py-0.5 rounded-full"
                :class="diffClass(measurementDiff[row.key].diff, row.key)"
              >
                {{ measurementDiff[row.key].diff > 0 ? '+' : '' }}{{ measurementDiff[row.key].diff.toFixed(1) }} {{ row.unit }}
              </span>
              <span v-else-if="!cycle.measurement_end?.[row.key] && !cycle.measurement_start?.[row.key]" class="text-muted-foreground">—</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Progression par créneau -->
      <div class="space-y-4">
        <h3 class="text-base font-semibold px-1">Progression par créneau</h3>

        <div v-if="loadingSlots" class="flex justify-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
        </div>

        <div v-else v-for="slot in slotsProgression" :key="slot.id" class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center justify-between mb-4">
            <div>
              <h4 class="font-semibold">{{ slot.name }}</h4>
              <p class="text-xs text-muted-foreground">{{ slot.sessions.length }} séance{{ slot.sessions.length !== 1 ? 's' : '' }}</p>
            </div>
            <button
              class="text-xs text-muted-foreground hover:text-primary transition-colors"
              @click="navigateTo(`/cycles/${cycleId}/slots/${slot.id}`)"
            >
              Détail →
            </button>
          </div>

          <div v-if="slot.sessions.length === 0" class="text-xs text-muted-foreground py-2">
            Aucune séance réalisée
          </div>

          <template v-else>
            <!-- Évolution globale s1 → sN -->
            <div v-if="slot.sessions.length >= 2" class="grid grid-cols-2 gap-3 mb-4">
              <div class="bg-muted/40 rounded-lg p-3">
                <p class="text-xs text-muted-foreground mb-1">Volume total</p>
                <p class="text-base font-bold">{{ formatKg(slot.sessions[slot.sessions.length - 1].stats.volume) }}</p>
                <DiffBadge :pct="slotVolumePct(slot)" />
              </div>
              <div class="bg-muted/40 rounded-lg p-3">
                <p class="text-xs text-muted-foreground mb-1">Kg/rep moyen</p>
                <p class="text-base font-bold">
                  {{ slot.sessions[slot.sessions.length - 1].stats.kg_per_rep?.toFixed(1) ?? '—' }}
                </p>
                <DiffBadge :pct="slotKgPerRepPct(slot)" />
              </div>
            </div>

            <!-- Tableau exercices : s1 → sN -->
            <div class="overflow-x-auto">
              <table class="w-full text-xs">
                <thead>
                  <tr class="text-left text-muted-foreground border-b">
                    <th class="pb-2 font-medium">Exercice</th>
                    <th
                      v-for="s in slot.sessions"
                      :key="s.performed_session_id"
                      class="pb-2 font-medium text-right px-2"
                    >
                      S{{ s.occurrence }}
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border/40">
                  <tr v-for="ex in exercisesForSlot(slot)" :key="ex.exercise_id">
                    <td class="py-2 text-muted-foreground pr-4 truncate max-w-[120px]">{{ ex.name }}</td>
                    <td
                      v-for="s in slot.sessions"
                      :key="s.performed_session_id"
                      class="py-2 text-right px-2 font-medium"
                    >
                      {{ kgPerRepForExercise(s, ex.exercise_id) }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, defineComponent, h } from 'vue'
import { useRoute } from 'vue-router'
import { AlertTriangle, ArrowLeft, Trophy, Ruler, TrendingUp, TrendingDown, Minus } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { useCycle } from '~/composables/useCycle'
import { useCycleStats } from '~/composables/useCycleStats'

const route = useRoute()
const cycleId = route.params.id

const { fetchCycle } = useCycle()
const { fetchSlotProgression, computeMeasurementDiff } = useCycleStats()

const loading = ref(true)
const loadingWeight = ref(false)
const loadingSlots = ref(false)
const error = ref(null)
const cycle = ref(null)
const totalWeight = ref(0)
const slotsProgression = ref([])

// ── Computed ────────────────────────────────────────────────────────────────

const totalSessions = computed(() =>
  (cycle.value?.slots || []).reduce((s, slot) => s + (slot.performed_sessions?.length || 0), 0)
)

const totalMinutes = computed(() =>
  (cycle.value?.slots || [])
    .flatMap(s => s.performed_sessions || [])
    .reduce((sum, s) => {
      if (!s.started_at || !s.ended_at) return sum
      return sum + Math.round((new Date(s.ended_at) - new Date(s.started_at)) / 60000)
    }, 0)
)

const cycleDuration = computed(() => {
  if (!cycle.value?.started_at || !cycle.value?.ended_at) return '?'
  return Math.round((new Date(cycle.value.ended_at) - new Date(cycle.value.started_at)) / 86400000)
})

const measurementDiff = computed(() =>
  computeMeasurementDiff(cycle.value?.measurement_start, cycle.value?.measurement_end)
)

// ── Helpers slots progression ───────────────────────────────────────────────

const slotVolumePct = (slot) => {
  if (slot.sessions.length < 2) return null
  const first = slot.sessions[0].stats.volume
  const last = slot.sessions[slot.sessions.length - 1].stats.volume
  if (!first) return null
  return ((last - first) / first) * 100
}

const slotKgPerRepPct = (slot) => {
  if (slot.sessions.length < 2) return null
  const first = slot.sessions[0].stats.kg_per_rep
  const last = slot.sessions[slot.sessions.length - 1].stats.kg_per_rep
  if (first == null || last == null || first === 0) return null
  return ((last - first) / first) * 100
}

const exercisesForSlot = (slot) => {
  const map = {}
  for (const s of slot.sessions) {
    for (const ex of s.stats.exercises) {
      if (!map[ex.exercise_id]) map[ex.exercise_id] = { exercise_id: ex.exercise_id, name: ex.exercise?.name || '?' }
    }
  }
  return Object.values(map)
}

const kgPerRepForExercise = (session, exerciseId) => {
  const ex = session.stats.exercises.find(e => e.exercise_id === exerciseId)
  if (!ex || ex.kg_per_rep == null) return '—'
  return `${ex.kg_per_rep.toFixed(1)}`
}

// ── DiffBadge inline ────────────────────────────────────────────────────────

const DiffBadge = defineComponent({
  props: { pct: { type: Number, default: null } },
  setup(props) {
    return () => {
      if (props.pct == null) return null
      const pos = props.pct > 0
      const zero = Math.abs(props.pct) < 0.1
      const color = zero ? 'text-muted-foreground' : pos ? 'text-green-500' : 'text-red-500'
      const icon = zero ? h(Minus, { class: 'h-3 w-3' })
        : pos ? h(TrendingUp, { class: 'h-3 w-3' })
        : h(TrendingDown, { class: 'h-3 w-3' })
      return h('span', { class: `flex items-center gap-0.5 ${color} text-xs font-medium mt-0.5` },
        [icon, `${pos ? '+' : ''}${props.pct.toFixed(1)}%`])
    }
  }
})

// ── Formatters ──────────────────────────────────────────────────────────────

const measurementRows = [
  { key: 'weight_kg', label: 'Poids', unit: 'kg' },
  { key: 'arm_cm', label: 'Tour de bras', unit: 'cm' },
  { key: 'waist_cm', label: 'Tour de taille', unit: 'cm' },
  { key: 'chest_cm', label: 'Tour de poitrine', unit: 'cm' },
  { key: 'thigh_cm', label: 'Tour de cuisse', unit: 'cm' },
  { key: 'calf_cm', label: 'Tour de mollet', unit: 'cm' },
]

const diffClass = (diff, key) => {
  const positive = key === 'waist_cm' ? diff < 0 : diff > 0
  return positive ? 'bg-green-500/10 text-green-600' : diff === 0 ? 'bg-muted text-muted-foreground' : 'bg-red-500/10 text-red-600'
}

const formatDate = (d) => {
  if (!d) return ''
  return new Date(d).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })
}

const formatMeasure = (val, unit) => val != null ? `${parseFloat(val).toFixed(unit === 'kg' ? 1 : 0)} ${unit}` : '—'

const formatWeight = (w) => {
  if (!w) return '0kg'
  if (w >= 1000000) return `${(w / 1000000).toFixed(1)}T`
  if (w >= 1000) return `${(w / 1000).toFixed(1)}K`
  return `${Math.round(w)}kg`
}

const formatDuration = (minutes) => {
  if (!minutes) return '0min'
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return h > 0 ? `${h}h${m > 0 ? `${m}m` : ''}` : `${minutes}min`
}

const formatKg = (v) => {
  if (!v) return '0'
  if (v >= 1000) return `${(v / 1000).toFixed(1)}t`
  return `${Math.round(v)}`
}

// ── Chargement ──────────────────────────────────────────────────────────────

const loadWeight = async (sessionIds) => {
  if (!sessionIds.length) return
  loadingWeight.value = true
  const supabase = useSupabaseClient()
  const { data } = await supabase
    .from('exerciseset')
    .select('weight_kg, reps')
    .in('performed_session_id', sessionIds)
  totalWeight.value = (data || []).reduce((sum, s) => {
    return sum + (s.weight_kg && s.reps ? s.weight_kg * s.reps : 0)
  }, 0)
  loadingWeight.value = false
}

const loadSlotsProgression = async (slots) => {
  loadingSlots.value = true
  const results = await Promise.all(
    slots.map(async (slot) => {
      const { data } = await fetchSlotProgression(slot.id)
      return { id: slot.id, name: slot.name, sessions: data || [] }
    })
  )
  slotsProgression.value = results
  loadingSlots.value = false
}

onMounted(async () => {
  try {
    const { data, error: err } = await fetchCycle(cycleId)
    if (err) throw new Error(err)
    if (!data) throw new Error('Cycle introuvable')
    cycle.value = data

    const sessionIds = (data.slots || [])
      .flatMap(s => s.performed_sessions || [])
      .map(s => s.id)

    await Promise.all([
      loadWeight(sessionIds),
      loadSlotsProgression(data.slots || [])
    ])
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})
</script>

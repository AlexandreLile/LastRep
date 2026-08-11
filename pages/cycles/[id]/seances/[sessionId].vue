<template>
  <div class="relative space-y-6">
    <!-- Chargement -->
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <!-- Erreur -->
    <div v-else-if="error" class="text-red-500 text-center py-8 bg-card rounded-xl p-6">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4" />
      {{ error }}
    </div>

    <template v-else-if="sessionData">
      <!-- Header -->
      <div class="bg-card rounded-xl p-6">
        <button
          class="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground mb-3 transition-colors"
          @click="navigateTo(`/cycles/${cycleId}`)"
        >
          <ChevronLeft class="h-4 w-4" /> {{ slotName || 'Cycle' }}
        </button>
        <div class="flex items-start justify-between gap-3">
          <div>
            <p class="text-xs text-muted-foreground mb-1">
              Occurrence #{{ sessionData.occurrence }}
              <span v-if="slotName"> · {{ slotName }}</span>
            </p>
            <h2 class="text-xl font-bold">{{ formatDate(sessionData.started_at) }}</h2>
            <p v-if="sessionData.ended_at" class="text-sm text-muted-foreground mt-0.5">
              Durée : {{ duration(sessionData.started_at, sessionData.ended_at) }}
            </p>
          </div>
          <Button
            v-if="slotSessionId"
            @click="refaire"
            class="flex items-center gap-1.5 flex-shrink-0"
          >
            <Play class="h-4 w-4" />
            Refaire
          </Button>
        </div>
      </div>

      <!-- Récap global -->
      <div class="grid grid-cols-2 gap-4">
        <div class="bg-card rounded-xl p-5 text-center">
          <p class="text-xs text-muted-foreground mb-1">Volume total</p>
          <p class="text-2xl font-bold text-primary">{{ formatKg(sessionData.stats.volume) }}</p>
          <p class="text-xs text-muted-foreground">kg·reps</p>
          <DiffBadge v-if="sessionData.comparison" :pct="sessionData.comparison.volume_diff_pct" class="mt-1 justify-center" />
        </div>
        <div class="bg-card rounded-xl p-5 text-center">
          <p class="text-xs text-muted-foreground mb-1">Kg/rep moyen</p>
          <p class="text-2xl font-bold text-primary">
            {{ sessionData.stats.kg_per_rep != null ? sessionData.stats.kg_per_rep.toFixed(1) : '—' }}
          </p>
          <p class="text-xs text-muted-foreground">kg/rep</p>
          <DiffBadge v-if="sessionData.comparison" :pct="sessionData.comparison.kg_per_rep_diff_pct" class="mt-1 justify-center" />
        </div>
      </div>

      <!-- Détail par exercice -->
      <div class="bg-card rounded-xl p-6">
        <div class="flex items-center gap-3 mb-5">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Dumbbell class="w-5 h-5 text-primary" />
          </div>
          <h3 class="text-lg font-semibold">Détail par exercice</h3>
        </div>

        <div v-if="!sessionData.stats.exercises.length" class="text-sm text-muted-foreground py-4 text-center">
          Aucune série enregistrée pour cette séance.
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="ex in sessionData.stats.exercises"
            :key="ex.exercise_id"
            class="border rounded-xl p-4"
          >
            <div class="flex items-start justify-between gap-2 mb-3">
              <div>
                <h4 class="font-medium">{{ ex.exercise?.name || 'Exercice inconnu' }}</h4>
                <p class="text-xs text-muted-foreground">{{ ex.exercise?.primary_muscle }}</p>
              </div>
              <span class="text-xs bg-muted/60 px-2 py-0.5 rounded-full text-muted-foreground flex-shrink-0">
                {{ ex.sets_count }} série{{ ex.sets_count !== 1 ? 's' : '' }}
              </span>
            </div>

            <div class="grid grid-cols-3 gap-3">
              <!-- Volume -->
              <div class="text-center">
                <p class="text-base font-semibold">{{ formatKg(ex.volume) }}</p>
                <p class="text-xs text-muted-foreground">Volume</p>
                <DiffBadge
                  v-if="sessionData.comparison"
                  :pct="getExComparison(ex.exercise_id, 'volume_diff_pct')"
                  class="mt-0.5 justify-center text-xs"
                />
              </div>
              <!-- Kg/rep -->
              <div class="text-center">
                <p class="text-base font-semibold">
                  {{ ex.kg_per_rep != null ? ex.kg_per_rep.toFixed(1) : '—' }}
                </p>
                <p class="text-xs text-muted-foreground">Kg/rep</p>
                <DiffBadge
                  v-if="sessionData.comparison"
                  :pct="getExComparison(ex.exercise_id, 'kg_per_rep_diff_pct')"
                  class="mt-0.5 justify-center text-xs"
                />
              </div>
              <!-- Meilleure série -->
              <div class="text-center">
                <p class="text-base font-semibold">
                  {{ ex.best_set_value != null ? formatKg(ex.best_set_value) : '—' }}
                </p>
                <p class="text-xs text-muted-foreground">Meilleure série</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Première occurrence : pas de comparaison -->
      <div v-if="!sessionData.comparison" class="text-center text-sm text-muted-foreground py-2">
        Première occurrence de ce créneau — la progression sera visible à la prochaine séance.
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted, defineComponent, h } from 'vue'
import { useRoute } from 'vue-router'
import { AlertTriangle, ChevronLeft, Dumbbell, Play, TrendingUp, TrendingDown, Minus } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { useCycleStats } from '~/composables/useCycleStats'
import { useCycle } from '~/composables/useCycle'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { getOfflineUser } from '~/utils/offlineTraining'

const route = useRoute()
const cycleId = route.params.id
const sessionId = route.params.sessionId

const { loading, error, fetchPerformedSessionStats } = useCycleStats()
const { fetchCycle } = useCycle()

const sessionData = ref(null)
const slotId = ref(null)
const slotName = ref(null)
const slotSessionId = ref(null)

// Composant inline badge de progression
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
      const text = `${pos ? '+' : ''}${props.pct.toFixed(1)}%`
      return h('span', { class: `flex items-center gap-0.5 ${color} text-xs font-medium` }, [icon, text])
    }
  }
})

const getExComparison = (exerciseId, key) => {
  if (!sessionData.value?.comparison?.exercises) return null
  return sessionData.value.comparison.exercises.find(e => e.exercise_id === exerciseId)?.[key] ?? null
}

const refaire = async () => {
  if (!slotSessionId.value || !slotId.value) return
  const supabase = useSupabaseClient()
  const { prepareSession } = usePerformedSession(supabase)
  const user = await getOfflineUser(supabase)
  if (!user) return
  prepareSession(slotSessionId.value, user.id, slotId.value)
  navigateTo(`/seances/${slotSessionId.value}/start?slot=${slotId.value}&cycle=${cycleId}`)
}

const load = async () => {
  // Charger le cycle pour récupérer le slotId de cette performedsession
  const { data: cycle } = await fetchCycle(cycleId)
  if (cycle) {
    for (const slot of cycle.slots || []) {
      const match = (slot.performed_sessions || []).find(s => s.id === sessionId)
      if (match) {
        slotId.value = slot.id
        slotName.value = slot.name
        slotSessionId.value = slot.workout_session_id
        break
      }
    }
  }

  if (!slotId.value) {
    error.value = 'Créneau introuvable pour cette séance.'
    return
  }

  const { data } = await fetchPerformedSessionStats(sessionId, slotId.value)
  sessionData.value = data
}

const formatDate = (d) => {
  if (!d) return ''
  return new Date(d).toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
}

const formatKg = (v) => {
  if (v == null || v === 0) return '0'
  return v >= 1000 ? `${(v / 1000).toFixed(1)}t` : `${Math.round(v)}`
}

const duration = (start, end) => {
  const mins = Math.round((new Date(end) - new Date(start)) / 60000)
  if (mins < 60) return `${mins} min`
  return `${Math.floor(mins / 60)}h${mins % 60 > 0 ? String(mins % 60).padStart(2, '0') : ''}`
}

onMounted(load)
</script>

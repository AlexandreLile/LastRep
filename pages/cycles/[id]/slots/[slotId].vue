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

    <template v-else>
      <!-- Header -->
      <div class="bg-card rounded-xl p-6">
        <button
          class="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground mb-3 transition-colors"
          @click="navigateTo(`/cycles/${cycleId}`)"
        >
          <ChevronLeft class="h-4 w-4" /> {{ cycleName || 'Cycle' }}
        </button>
        <div class="flex items-start justify-between gap-3">
          <div>
            <h2 class="text-xl font-bold">{{ slotName }}</h2>
            <p class="text-sm text-muted-foreground mt-0.5">
              {{ sessions.length }} séance{{ sessions.length !== 1 ? 's' : '' }} réalisée{{ sessions.length !== 1 ? 's' : '' }}
            </p>
          </div>
          <Button @click="startSession" class="flex items-center gap-1.5 flex-shrink-0">
            <Play class="h-4 w-4" />
            Démarrer
          </Button>
        </div>
      </div>

      <!-- État vide -->
      <div v-if="!sessions.length" class="flex flex-col items-center justify-center py-16 bg-card rounded-xl text-muted-foreground">
        <Dumbbell class="w-12 h-12 mb-3 opacity-20" />
        <p class="text-sm">Aucune séance réalisée dans ce créneau</p>
      </div>

      <template v-else>
        <!-- Résumé progression globale -->
        <div v-if="sessions.length >= 2" class="grid grid-cols-2 gap-4">
          <div class="bg-card rounded-xl p-5 border border-border">
            <p class="text-xs text-muted-foreground mb-1">Volume (s1 → s{{ sessions.length }})</p>
            <p class="text-2xl font-bold text-foreground">{{ formatKg(lastSession.stats.volume) }}</p>
            <DiffBadge :pct="overallVolumePct" class="mt-1" />
          </div>
          <div class="bg-card rounded-xl p-5 border border-border">
            <p class="text-xs text-muted-foreground mb-1">Kg/rep (s1 → s{{ sessions.length }})</p>
            <p class="text-2xl font-bold text-foreground">
              {{ lastSession.stats.kg_per_rep != null ? lastSession.stats.kg_per_rep.toFixed(1) : '—' }}
            </p>
            <DiffBadge :pct="overallKgPerRepPct" class="mt-1" />
          </div>
        </div>

        <!-- Timeline des séances -->
        <div class="space-y-4">
          <h3 class="text-base font-semibold px-1">Historique des séances</h3>

          <div
            v-for="session in [...sessions].reverse()"
            :key="session.performed_session_id"
            class="bg-card rounded-xl p-5 cursor-pointer hover:shadow-md transition-all"
            @click="navigateTo(`/cycles/${cycleId}/seances/${session.performed_session_id}`)"
          >
            <!-- En-tête de la séance -->
            <div class="flex items-start justify-between gap-2 mb-4">
              <div>
                <div class="flex items-center gap-2 mb-0.5">
                  <span class="text-xs font-semibold text-primary bg-primary/10 px-2 py-0.5 rounded-full">
                    Séance {{ session.occurrence }}
                  </span>
                  <span v-if="session.ended_at" class="text-xs text-muted-foreground">
                    {{ durationLabel(session.started_at, session.ended_at) }}
                  </span>
                </div>
                <p class="text-sm font-medium">{{ formatDate(session.started_at) }}</p>
              </div>
              <ChevronRight class="h-4 w-4 text-muted-foreground flex-shrink-0 mt-1" />
            </div>

            <!-- Stats globales de la séance -->
            <div class="grid grid-cols-2 gap-3 mb-4">
              <div class="bg-muted/40 rounded-lg p-3 text-center">
                <p class="text-lg font-bold">{{ formatKg(session.stats.volume) }}</p>
                <p class="text-xs text-muted-foreground">Volume</p>
                <DiffBadge v-if="session.comparison" :pct="session.comparison.volume_diff_pct" class="mt-0.5 justify-center" />
              </div>
              <div class="bg-muted/40 rounded-lg p-3 text-center">
                <p class="text-lg font-bold">
                  {{ session.stats.kg_per_rep != null ? session.stats.kg_per_rep.toFixed(1) : '—' }}
                </p>
                <p class="text-xs text-muted-foreground">Kg/rep</p>
                <DiffBadge v-if="session.comparison" :pct="session.comparison.kg_per_rep_diff_pct" class="mt-0.5 justify-center" />
              </div>
            </div>

            <!-- Détail par exercice -->
            <div class="space-y-2">
              <div
                v-for="ex in session.stats.exercises"
                :key="ex.exercise_id"
                class="flex items-center justify-between text-sm"
              >
                <span class="text-muted-foreground truncate flex-1 min-w-0 pr-4">{{ ex.exercise?.name }}</span>
                <div class="flex items-center gap-3 flex-shrink-0">
                  <span class="text-xs text-muted-foreground">{{ formatKg(ex.volume) }} vol</span>
                  <span class="font-medium">{{ ex.kg_per_rep != null ? ex.kg_per_rep.toFixed(1) : '—' }} kg/rep</span>
                  <DiffBadge
                    v-if="session.comparison"
                    :pct="getExComparison(session, ex.exercise_id, 'kg_per_rep_diff_pct')"
                    class="text-xs"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, defineComponent, h } from 'vue'
import { useRoute } from 'vue-router'
import { AlertTriangle, ChevronLeft, ChevronRight, Play, Dumbbell, TrendingUp, TrendingDown, Minus } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { useCycleStats } from '~/composables/useCycleStats'
import { useCycle } from '~/composables/useCycle'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { getOfflineUser } from '~/utils/offlineTraining'

const route = useRoute()
const cycleId = route.params.id
const slotId = route.params.slotId

const { loading, error, fetchSlotProgression } = useCycleStats()
const { fetchCycle } = useCycle()

const sessions = ref([])
const slotName = ref('')
const cycleName = ref('')
const sessionTemplateId = ref(null)

const lastSession = computed(() => sessions.value[sessions.value.length - 1])
const firstSession = computed(() => sessions.value[0])

const overallVolumePct = computed(() => {
  if (sessions.value.length < 2) return null
  const first = firstSession.value.stats.volume
  const last = lastSession.value.stats.volume
  if (!first) return null
  return ((last - first) / first) * 100
})

const overallKgPerRepPct = computed(() => {
  if (sessions.value.length < 2) return null
  const first = firstSession.value.stats.kg_per_rep
  const last = lastSession.value.stats.kg_per_rep
  if (first == null || last == null || first === 0) return null
  return ((last - first) / first) * 100
})

const DiffBadge = defineComponent({
  props: { pct: { type: Number, default: null } },
  setup(props) {
    return () => {
      if (props.pct == null) return null
      const pos = props.pct > 0
      const zero = Math.abs(props.pct) < 0.1
      const color = zero ? 'text-muted-foreground' : pos ? 'text-green-500' : 'text-red-500'
      const icon = zero
        ? h(Minus, { class: 'h-3 w-3' })
        : pos ? h(TrendingUp, { class: 'h-3 w-3' })
        : h(TrendingDown, { class: 'h-3 w-3' })
      return h('span', { class: `flex items-center gap-0.5 ${color} text-xs font-medium` }, [
        icon, `${pos ? '+' : ''}${props.pct.toFixed(1)}%`
      ])
    }
  }
})

const getExComparison = (session, exerciseId, key) => {
  return session.comparison?.exercises?.find(e => e.exercise_id === exerciseId)?.[key] ?? null
}

const formatDate = (d) => {
  if (!d) return ''
  return new Date(d).toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' })
}

const formatKg = (v) => {
  if (!v) return '0'
  if (v >= 1000) return `${(v / 1000).toFixed(1)}t`
  return `${Math.round(v)}`
}

const durationLabel = (start, end) => {
  const mins = Math.round((new Date(end) - new Date(start)) / 60000)
  if (mins < 60) return `${mins} min`
  return `${Math.floor(mins / 60)}h${mins % 60 > 0 ? String(mins % 60).padStart(2, '0') : ''}`
}

const startSession = async () => {
  if (!sessionTemplateId.value) return
  const supabase = useSupabaseClient()
  const { prepareSession } = usePerformedSession(supabase)
  const user = await getOfflineUser(supabase)
  if (!user) return
  prepareSession(sessionTemplateId.value, user.id, slotId)
  navigateTo(`/seances/${sessionTemplateId.value}/start?slot=${slotId}&cycle=${cycleId}`)
}

const load = async () => {
  const [progressionResult, cycleResult] = await Promise.all([
    fetchSlotProgression(slotId),
    fetchCycle(cycleId)
  ])

  if (progressionResult.data) sessions.value = progressionResult.data

  if (cycleResult.data) {
    cycleName.value = cycleResult.data.name
    const slot = (cycleResult.data.slots || []).find(s => s.id === slotId)
    if (slot) {
      slotName.value = slot.name
      sessionTemplateId.value = slot.workout_session_id
    }
  }
}

onMounted(load)
</script>

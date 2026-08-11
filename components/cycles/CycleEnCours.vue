<template>
  <div v-if="cycle" class="bg-card rounded-xl p-6 border border-border">
    <!-- Header -->
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
          <RotateCcw class="w-5 h-5 text-primary" />
        </div>
        <div>
          <h3 class="text-sm font-medium text-muted-foreground">Cycle en cours</h3>
          <p class="text-base font-semibold text-foreground leading-tight">{{ cycle.name }}</p>
        </div>
      </div>
      <button
        class="text-xs text-muted-foreground hover:text-primary transition-colors"
        @click="navigateTo(`/cycles/${cycle.id}`)"
      >
        Voir le cycle →
      </button>
    </div>

    <!-- Slots -->
    <div class="space-y-2">
      <div
        v-for="slot in cycle.slots"
        :key="slot.id"
        class="flex items-center justify-between gap-3 py-2.5 px-3 bg-muted/40 rounded-lg"
      >
        <div class="min-w-0">
          <p class="text-sm font-medium truncate">{{ slot.workout_session?.title || slot.name }}</p>
          <p class="text-xs text-muted-foreground mt-0.5">
            <span v-if="lastSession(slot)">dernière : {{ formatDate(lastSession(slot).started_at) }}</span>
            <span v-else>Pas encore réalisée</span>
          </p>
        </div>
        <Button
          size="sm"
          :disabled="starting === slot.id"
          @click="startSlot(slot)"
          class="flex items-center gap-1.5 flex-shrink-0"
        >
          <div v-if="starting === slot.id" class="animate-spin rounded-full h-3 w-3 border-t-2 border-white"></div>
          <Play v-else class="h-3.5 w-3.5" />
          Démarrer
        </Button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RotateCcw, Play } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { useCycle } from '~/composables/useCycle'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { getOfflineUser } from '~/utils/offlineTraining'

const { fetchCycles } = useCycle()
const cycle = ref(null)
const starting = ref(null)

const lastSession = (slot) => {
  const sessions = slot.performed_sessions || []
  if (!sessions.length) return null
  return [...sessions].sort((a, b) => new Date(b.started_at) - new Date(a.started_at))[0]
}

const formatDate = (d) => {
  if (!d) return ''
  return new Date(d).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })
}

const startSlot = async (slot) => {
  if (!slot.workout_session_id) return
  starting.value = slot.id
  try {
    const supabase = useSupabaseClient()
    const { prepareSession } = usePerformedSession(supabase)
    const user = await getOfflineUser(supabase)
    if (!user) return
    prepareSession(slot.workout_session_id, user.id, slot.id)
    navigateTo(`/seances/${slot.workout_session_id}/start?slot=${slot.id}&cycle=${cycle.value.id}`)
  } finally {
    starting.value = null
  }
}

onMounted(async () => {
  const { data: cycles } = await fetchCycles()
  cycle.value = (cycles || []).find(c => !c.ended_at) || null
})
</script>

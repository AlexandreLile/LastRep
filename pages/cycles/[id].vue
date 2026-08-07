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

    <template v-else-if="cycle">
      <!-- Header -->
      <div class="bg-card rounded-xl p-6">
        <div class="flex items-start justify-between gap-3 mb-4">
          <div>
            <button
              class="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground mb-2 transition-colors"
              @click="navigateTo('/cycles')"
            >
              <ChevronLeft class="h-4 w-4" /> Cycles
            </button>
            <h2 class="text-2xl font-bold">{{ cycle.name }}</h2>
            <p class="text-sm text-muted-foreground mt-1">
              {{ formatDate(cycle.started_at) }}
              <span v-if="cycle.ended_at"> → {{ formatDate(cycle.ended_at) }}</span>
            </p>
          </div>
          <div class="flex items-center gap-2">
            <span
              class="text-xs px-2.5 py-1 rounded-full font-medium flex-shrink-0"
              :class="cycle.ended_at ? 'bg-muted text-muted-foreground' : 'bg-primary/15 text-primary'"
            >
              {{ cycle.ended_at ? 'Terminé' : 'En cours' }}
            </span>
            <Button variant="ghost" size="icon" @click="showDeleteDialog = true">
              <Trash2 class="h-4 w-4 text-muted-foreground" />
            </Button>
          </div>
        </div>

        <!-- Clôturer le cycle -->
        <div v-if="!cycle.ended_at" class="flex gap-2">
          <Button variant="outline" size="sm" @click="showEndDialog = true" class="flex items-center gap-1.5">
            <CheckCircle2 class="h-4 w-4" />
            Clôturer le cycle
          </Button>
        </div>
      </div>

      <!-- Mensurations -->
      <div v-if="cycle.measurement_start || cycle.measurement_end" class="bg-card rounded-xl p-6">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Ruler class="w-5 h-5 text-primary" />
          </div>
          <h3 class="text-lg font-semibold">Mensurations</h3>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="text-left text-muted-foreground border-b">
                <th class="pb-2 font-medium">Mesure</th>
                <th class="pb-2 font-medium text-right" v-if="cycle.measurement_start">Début</th>
                <th class="pb-2 font-medium text-right" v-if="cycle.measurement_end">Fin</th>
                <th class="pb-2 font-medium text-right" v-if="measurementDiff">Évolution</th>
              </tr>
            </thead>
            <tbody class="divide-y">
              <tr v-for="row in measurementRows" :key="row.key" class="py-2">
                <td class="py-2 text-muted-foreground">{{ row.label }}</td>
                <td class="py-2 text-right" v-if="cycle.measurement_start">
                  {{ formatMeasure(cycle.measurement_start[row.key], row.unit) }}
                </td>
                <td class="py-2 text-right" v-if="cycle.measurement_end">
                  {{ formatMeasure(cycle.measurement_end[row.key], row.unit) }}
                </td>
                <td class="py-2 text-right" v-if="measurementDiff">
                  <span
                    v-if="measurementDiff[row.key]"
                    :class="diffClass(measurementDiff[row.key].diff, row.key)"
                    class="font-medium"
                  >
                    {{ measurementDiff[row.key].diff > 0 ? '+' : '' }}{{ measurementDiff[row.key].diff.toFixed(1) }} {{ row.unit }}
                    <span class="text-xs opacity-70">({{ measurementDiff[row.key].diff_pct?.toFixed(1) }}%)</span>
                  </span>
                  <span v-else class="text-muted-foreground">—</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-if="!cycle.measurement_end && !cycle.ended_at" class="mt-3">
          <button
            class="text-sm text-primary hover:underline"
            @click="showEndMeasurements = true"
          >
            + Ajouter des mensurations de fin
          </button>
        </div>
      </div>

      <!-- Ajouter mensurations si aucune -->
      <div v-else class="bg-card rounded-xl p-5">
        <button
          class="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
          @click="showStartMeasurements = true"
        >
          <Ruler class="h-4 w-4" />
          Ajouter des mensurations de départ
        </button>
      </div>

      <!-- Créneaux -->
      <div class="space-y-4">
        <div class="flex items-center justify-between px-1">
          <h3 class="text-lg font-semibold">Créneaux</h3>
          <Button variant="ghost" size="sm" @click="showAddSlot = true" class="flex items-center gap-1.5 text-sm">
            <Plus class="h-4 w-4" /> Ajouter
          </Button>
        </div>

        <div v-if="!cycle.slots?.length" class="flex flex-col items-center justify-center py-10 bg-card rounded-xl text-muted-foreground">
          <LayoutGrid class="w-10 h-10 mb-2 opacity-30" />
          <p class="text-sm">Aucun créneau — ajoutez vos séances</p>
        </div>

        <div v-for="slot in cycle.slots" :key="slot.id" class="bg-card rounded-xl p-5">
          <div class="flex items-start justify-between gap-2 mb-3">
            <div>
              <h4 class="font-semibold">{{ slot.name }}</h4>
              <p v-if="slot.workout_session" class="text-xs text-muted-foreground mt-0.5">
                {{ slot.workout_session.title }}
              </p>
            </div>
            <div class="flex items-center gap-2">
              <span class="text-xs text-muted-foreground">
                {{ slot.performed_sessions?.length || 0 }} passage{{ slot.performed_sessions?.length !== 1 ? 's' : '' }}
              </span>
              <Button
                v-if="slot.workout_session_id"
                size="sm"
                @click="startSlot(slot)"
                class="flex items-center gap-1.5"
              >
                <Play class="h-3.5 w-3.5" />
                Démarrer
              </Button>
              <Button
                v-else
                size="sm"
                variant="outline"
                @click="linkSession(slot)"
              >
                Lier une séance
              </Button>
            </div>
          </div>

          <!-- Sessions réalisées pour ce créneau -->
          <div v-if="slot.performed_sessions?.length" class="space-y-1.5">
            <div
              v-for="(session, idx) in [...(slot.performed_sessions || [])].sort((a, b) => new Date(b.started_at) - new Date(a.started_at))"
              :key="session.id"
              class="flex items-center justify-between py-2 px-3 bg-muted/40 rounded-lg cursor-pointer hover:bg-muted/70 transition-colors"
              @click="navigateTo(`/cycles/${cycle.id}/seances/${session.id}`)"
            >
              <div class="flex items-center gap-2">
                <span class="text-xs font-medium text-muted-foreground w-5 text-center">
                  #{{ slot.performed_sessions.length - idx }}
                </span>
                <span class="text-sm">{{ formatDate(session.started_at) }}</span>
              </div>
              <div class="flex items-center gap-2">
                <span v-if="session.ended_at" class="text-xs text-muted-foreground">
                  {{ duration(session.started_at, session.ended_at) }}
                </span>
                <ChevronRight class="h-4 w-4 text-muted-foreground" />
              </div>
            </div>
          </div>
          <div v-else class="text-xs text-muted-foreground py-1">
            Pas encore réalisé
          </div>
        </div>
      </div>
    </template>

    <!-- Dialog clôturer -->
    <Dialog :open="showEndDialog" @update:open="showEndDialog = $event">
      <DialogContent class="max-w-md">
        <DialogHeader>
          <DialogTitle>Clôturer le cycle</DialogTitle>
          <DialogDescription>Définissez la date de fin. Vous pourrez ajouter des mensurations finales.</DialogDescription>
        </DialogHeader>
        <div class="space-y-4 py-2">
          <div class="space-y-1.5">
            <label class="text-sm font-medium">Date de fin</label>
            <Input v-model="endForm.ended_at" type="date" />
          </div>
          <!-- Mensurations de fin -->
          <div class="border rounded-xl overflow-hidden">
            <button
              type="button"
              class="w-full flex items-center justify-between p-4 text-sm font-medium hover:bg-muted/30 transition-colors"
              @click="showEndMeasurements = !showEndMeasurements"
            >
              <span class="flex items-center gap-2">
                <Ruler class="h-4 w-4 text-muted-foreground" />
                Mensurations de fin
                <span class="text-xs text-muted-foreground font-normal">(optionnel)</span>
              </span>
              <ChevronDown class="h-4 w-4 text-muted-foreground transition-transform" :class="{ 'rotate-180': showEndMeasurements }" />
            </button>
            <div v-if="showEndMeasurements" class="p-4 pt-0 space-y-3 border-t">
              <div class="grid grid-cols-2 gap-3">
                <div class="space-y-1" v-for="f in measurementRows" :key="f.key">
                  <label class="text-xs text-muted-foreground">{{ f.label }} ({{ f.unit }})</label>
                  <Input v-model.number="endForm.measurements[f.key]" type="number" step="0.1" :placeholder="f.placeholder" />
                </div>
              </div>
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="showEndDialog = false">Annuler</Button>
          <Button @click="handleEndCycle" :disabled="!endForm.ended_at || ending">
            {{ ending ? 'Enregistrement…' : 'Clôturer' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- Dialog ajouter créneau -->
    <Dialog :open="showAddSlot" @update:open="showAddSlot = $event">
      <DialogContent class="max-w-sm">
        <DialogHeader>
          <DialogTitle>Ajouter un créneau</DialogTitle>
        </DialogHeader>
        <div class="space-y-3 py-2">
          <div class="space-y-1.5">
            <label class="text-sm font-medium">Nom du créneau</label>
            <Input v-model="newSlotName" placeholder="ex: Push A, Jambes…" @keydown.enter="handleAddSlot" />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="showAddSlot = false">Annuler</Button>
          <Button @click="handleAddSlot" :disabled="!newSlotName.trim()">Ajouter</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- Dialog supprimer -->
    <AlertDialog :open="showDeleteDialog" @update:open="showDeleteDialog = $event">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Supprimer le cycle</AlertDialogTitle>
          <AlertDialogDescription>
            Cette action est irréversible. Le cycle et ses créneaux seront supprimés, mais les séances réalisées seront conservées.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Annuler</AlertDialogCancel>
          <AlertDialogAction class="bg-destructive text-destructive-foreground hover:bg-destructive/90" @click="handleDelete">
            Supprimer
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  AlertTriangle, ChevronLeft, ChevronRight, ChevronDown, Plus, Play,
  Trash2, CheckCircle2, Ruler, LayoutGrid
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter
} from '@/components/ui/dialog'
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle
} from '@/components/ui/alert-dialog'
import { useCycle } from '~/composables/useCycle'
import { useCycleStats } from '~/composables/useCycleStats'

const route = useRoute()
const router = useRouter()
const cycleId = route.params.id

const { loading, error, fetchCycle, updateCycle, deleteCycle, createSlot, saveMeasurement } = useCycle()
const { computeMeasurementDiff } = useCycleStats()

const cycle = ref(null)
const showDeleteDialog = ref(false)
const showEndDialog = ref(false)
const showAddSlot = ref(false)
const showStartMeasurements = ref(false)
const showEndMeasurements = ref(false)
const ending = ref(false)
const newSlotName = ref('')

const endForm = reactive({ ended_at: new Date().toISOString().split('T')[0], measurements: {} })

const measurementRows = [
  { key: 'weight_kg', label: 'Poids', unit: 'kg', placeholder: '75' },
  { key: 'arm_cm', label: 'Tour de bras', unit: 'cm', placeholder: '36' },
  { key: 'waist_cm', label: 'Tour de taille', unit: 'cm', placeholder: '80' },
  { key: 'chest_cm', label: 'Tour de poitrine', unit: 'cm', placeholder: '100' },
  { key: 'thigh_cm', label: 'Tour de cuisse', unit: 'cm', placeholder: '58' },
  { key: 'calf_cm', label: 'Tour de mollet', unit: 'cm', placeholder: '38' }
]

const measurementDiff = computed(() =>
  computeMeasurementDiff(cycle.value?.measurement_start, cycle.value?.measurement_end)
)

const load = async () => {
  const { data, error: err } = await fetchCycle(cycleId)
  if (data) cycle.value = data
}

const handleEndCycle = async () => {
  ending.value = true
  await updateCycle(cycleId, { ended_at: endForm.ended_at })
  const hasData = Object.values(endForm.measurements).some(v => v != null && v !== '')
  if (hasData) {
    await saveMeasurement(cycleId, 'end', endForm.measurements, endForm.ended_at)
  }
  await load()
  showEndDialog.value = false
  ending.value = false
}

const handleAddSlot = async () => {
  if (!newSlotName.value.trim()) return
  await createSlot(cycleId, { name: newSlotName.value.trim(), slot_order: cycle.value?.slots?.length || 0 })
  newSlotName.value = ''
  showAddSlot.value = false
  await load()
}

const handleDelete = async () => {
  await deleteCycle(cycleId)
  navigateTo('/cycles')
}

const startSlot = (slot) => {
  navigateTo(`/seances/${slot.workout_session_id}/start?slot=${slot.id}&cycle=${cycleId}`)
}

const linkSession = (slot) => {
  navigateTo(`/seances?linkSlot=${slot.id}&cycle=${cycleId}`)
}

const formatDate = (d) => {
  if (!d) return ''
  return new Date(d).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })
}

const formatMeasure = (val, unit) => {
  if (val == null) return '—'
  return `${parseFloat(val).toFixed(unit === 'kg' ? 1 : 0)} ${unit}`
}

const diffClass = (diff, key) => {
  if (key === 'waist_cm') return diff < 0 ? 'text-green-500' : diff > 0 ? 'text-red-500' : 'text-muted-foreground'
  return diff > 0 ? 'text-green-500' : diff < 0 ? 'text-red-500' : 'text-muted-foreground'
}

const duration = (start, end) => {
  const mins = Math.round((new Date(end) - new Date(start)) / 60000)
  if (mins < 60) return `${mins} min`
  return `${Math.floor(mins / 60)}h${mins % 60 > 0 ? String(mins % 60).padStart(2, '0') : ''}`
}

onMounted(load)
</script>

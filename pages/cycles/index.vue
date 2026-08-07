<template>
  <div class="relative">
    <!-- Header -->
    <div class="mb-8 bg-card rounded-xl p-6">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div class="flex items-center gap-4">
          <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
            <RotateCcw class="h-6 w-6 text-primary" />
          </div>
          <div>
            <h2 class="text-2xl font-bold text-foreground">Cycles</h2>
            <p class="text-sm text-muted-foreground">Organisez vos séances en cycles et suivez votre progression</p>
          </div>
        </div>
        <Button @click="showCreateDialog = true" class="w-full sm:w-auto flex items-center gap-2">
          <Plus class="h-4 w-4" />
          Nouveau cycle
        </Button>
      </div>
    </div>

    <!-- Chargement -->
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <!-- Erreur -->
    <div v-else-if="error" class="text-red-500 text-center py-8 bg-card rounded-xl p-6">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4" />
      {{ error }}
    </div>

    <div v-else class="space-y-4">
      <!-- État vide -->
      <div v-if="cycles.length === 0" class="flex flex-col items-center justify-center py-16 px-4 space-y-4 bg-card rounded-xl">
        <RotateCcw class="w-16 h-16 text-muted-foreground/30" />
        <p class="text-center text-muted-foreground">Aucun cycle pour l'instant</p>
        <Button @click="showCreateDialog = true" variant="outline" class="flex items-center gap-2">
          <Plus class="h-4 w-4" />
          Créer mon premier cycle
        </Button>
      </div>

      <!-- Liste des cycles -->
      <div
        v-for="cycle in cycles"
        :key="cycle.id"
        class="bg-card rounded-xl p-5 hover:shadow-md transition-all duration-200 cursor-pointer"
        @click="navigateTo(`/cycles/${cycle.id}`)"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1">
              <span
                class="text-xs px-2 py-0.5 rounded-full font-medium"
                :class="cycle.ended_at ? 'bg-muted text-muted-foreground' : 'bg-primary/15 text-primary'"
              >
                {{ cycle.ended_at ? 'Terminé' : 'En cours' }}
              </span>
            </div>
            <h3 class="text-base font-semibold truncate">{{ cycle.name }}</h3>
            <p class="text-sm text-muted-foreground mt-0.5">
              {{ formatDate(cycle.started_at) }}
              <span v-if="cycle.ended_at"> → {{ formatDate(cycle.ended_at) }}</span>
            </p>
          </div>
          <div class="flex flex-col items-end gap-1 flex-shrink-0 text-right">
            <span class="text-sm font-medium text-primary">
              {{ cycle.slots?.length || 0 }} créneau{{ cycle.slots?.length !== 1 ? 'x' : '' }}
            </span>
            <span class="text-xs text-muted-foreground">
              {{ totalSessions(cycle) }} séance{{ totalSessions(cycle) !== 1 ? 's' : '' }} réalisée{{ totalSessions(cycle) !== 1 ? 's' : '' }}
            </span>
          </div>
        </div>

        <!-- Aperçu des créneaux -->
        <div v-if="cycle.slots?.length" class="mt-3 flex flex-wrap gap-1.5">
          <span
            v-for="slot in cycle.slots.slice(0, 5)"
            :key="slot.id"
            class="text-xs bg-muted/70 text-muted-foreground px-2 py-0.5 rounded-full"
          >
            {{ slot.name }}
          </span>
          <span v-if="cycle.slots.length > 5" class="text-xs text-muted-foreground px-1 py-0.5">
            +{{ cycle.slots.length - 5 }}
          </span>
        </div>
      </div>
    </div>

    <!-- Dialog création -->
    <Dialog :open="showCreateDialog" @update:open="showCreateDialog = $event">
      <DialogContent class="max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Nouveau cycle</DialogTitle>
          <DialogDescription>Définissez vos créneaux de séances pour ce programme.</DialogDescription>
        </DialogHeader>

        <div class="space-y-5 py-2">
          <!-- Nom -->
          <div class="space-y-1.5">
            <label class="text-sm font-medium">Nom du cycle</label>
            <Input v-model="form.name" placeholder="ex: PPL Juillet, Full Body été…" />
          </div>

          <!-- Dates -->
          <div class="grid grid-cols-2 gap-3">
            <div class="space-y-1.5">
              <label class="text-sm font-medium">Début</label>
              <Input v-model="form.started_at" type="date" />
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-medium">Fin <span class="text-muted-foreground font-normal">(optionnel)</span></label>
              <Input v-model="form.ended_at" type="date" />
            </div>
          </div>

          <!-- Créneaux -->
          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <label class="text-sm font-medium">Créneaux</label>
              <Button type="button" variant="ghost" size="sm" @click="addSlot" class="h-7 text-xs gap-1">
                <Plus class="h-3 w-3" /> Ajouter
              </Button>
            </div>
            <div class="space-y-2">
              <div
                v-for="(slot, i) in form.slots"
                :key="i"
                class="flex items-center gap-2"
              >
                <div class="w-6 h-6 rounded-full bg-muted flex items-center justify-center text-xs text-muted-foreground flex-shrink-0">
                  {{ i + 1 }}
                </div>
                <Input v-model="slot.name" :placeholder="`ex: Push A, Jambes, Full Body ${i + 1}…`" class="flex-1" />
                <button
                  type="button"
                  @click="removeSlot(i)"
                  class="text-muted-foreground hover:text-destructive transition-colors p-1"
                >
                  <X class="h-4 w-4" />
                </button>
              </div>
            </div>
            <p v-if="form.slots.length === 0" class="text-xs text-muted-foreground">
              Vous pourrez ajouter des créneaux après la création du cycle.
            </p>
          </div>

          <!-- Mensurations de début (collapsible) -->
          <div class="border rounded-xl overflow-hidden">
            <button
              type="button"
              class="w-full flex items-center justify-between p-4 text-sm font-medium hover:bg-muted/30 transition-colors"
              @click="showMeasurements = !showMeasurements"
            >
              <span class="flex items-center gap-2">
                <Ruler class="h-4 w-4 text-muted-foreground" />
                Mensurations de départ
                <span class="text-xs text-muted-foreground font-normal">(optionnel)</span>
              </span>
              <ChevronDown class="h-4 w-4 text-muted-foreground transition-transform" :class="{ 'rotate-180': showMeasurements }" />
            </button>
            <div v-if="showMeasurements" class="p-4 pt-0 space-y-3 border-t">
              <div class="grid grid-cols-2 gap-3">
                <div class="space-y-1">
                  <label class="text-xs text-muted-foreground">Poids (kg)</label>
                  <Input v-model.number="form.measurements.weight_kg" type="number" step="0.1" placeholder="75.0" />
                </div>
                <div class="space-y-1">
                  <label class="text-xs text-muted-foreground">Tour de bras (cm)</label>
                  <Input v-model.number="form.measurements.arm_cm" type="number" step="0.5" placeholder="36" />
                </div>
                <div class="space-y-1">
                  <label class="text-xs text-muted-foreground">Tour de taille (cm)</label>
                  <Input v-model.number="form.measurements.waist_cm" type="number" step="0.5" placeholder="80" />
                </div>
                <div class="space-y-1">
                  <label class="text-xs text-muted-foreground">Tour de poitrine (cm)</label>
                  <Input v-model.number="form.measurements.chest_cm" type="number" step="0.5" placeholder="100" />
                </div>
                <div class="space-y-1">
                  <label class="text-xs text-muted-foreground">Tour de cuisse (cm)</label>
                  <Input v-model.number="form.measurements.thigh_cm" type="number" step="0.5" placeholder="58" />
                </div>
                <div class="space-y-1">
                  <label class="text-xs text-muted-foreground">Tour de mollet (cm)</label>
                  <Input v-model.number="form.measurements.calf_cm" type="number" step="0.5" placeholder="38" />
                </div>
              </div>
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="showCreateDialog = false">Annuler</Button>
          <Button @click="handleCreate" :disabled="!form.name || !form.started_at || creating">
            <span v-if="creating" class="flex items-center gap-2">
              <div class="animate-spin rounded-full h-3 w-3 border-t-2 border-white"></div>
              Création…
            </span>
            <span v-else>Créer le cycle</span>
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { Plus, RotateCcw, AlertTriangle, X, ChevronDown, Ruler } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter
} from '@/components/ui/dialog'
import { useCycle } from '~/composables/useCycle'

const { cycles, loading, error, fetchCycles, createCycle } = useCycle()

const showCreateDialog = ref(false)
const showMeasurements = ref(false)
const creating = ref(false)

const today = new Date().toISOString().split('T')[0]

const defaultForm = () => ({
  name: '',
  started_at: today,
  ended_at: '',
  slots: [],
  measurements: {}
})

const form = reactive(defaultForm())

const addSlot = () => form.slots.push({ name: '' })
const removeSlot = (i) => form.slots.splice(i, 1)

const handleCreate = async () => {
  if (!form.name || !form.started_at) return
  creating.value = true
  const { success, error: err } = await createCycle({
    name: form.name,
    started_at: form.started_at,
    ended_at: form.ended_at || null,
    slots: form.slots.filter(s => s.name.trim()),
    measurements: { start: form.measurements }
  })
  creating.value = false
  if (success) {
    showCreateDialog.value = false
    Object.assign(form, defaultForm())
    showMeasurements.value = false
  }
}

const totalSessions = (cycle) =>
  (cycle.slots || []).reduce((sum, s) => sum + (s.performed_sessions?.length || 0), 0)

const formatDate = (d) => {
  if (!d) return ''
  return new Date(d).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })
}

onMounted(fetchCycles)
</script>

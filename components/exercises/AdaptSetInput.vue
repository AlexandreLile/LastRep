<template>
  <div class="space-y-4">
    <!-- Type: weight_reps (défaut si measurement_type n'est pas défini) -->
    <div v-if="!exercise.measurement_type || exercise.measurement_type === 'weight_reps'" class="grid grid-cols-2 gap-4">
      <div class="space-y-2">
        <Label>Poids (kg)</Label>
        <Input
          v-model="setData.weight_kg"
          type="number"
          step="0.5"
          placeholder="0"
          :class="{ 'border-red-500 ring-red-500': fieldErrors.weight_kg }"
        />
      </div>
      <div class="space-y-2">
        <Label>Répétitions</Label>
        <Input
          v-model="setData.reps"
          type="number"
          placeholder="0"
          :class="{ 'border-red-500 ring-red-500': fieldErrors.reps }"
        />
      </div>
    </div>

    <!-- Type: reps (poids optionnel pour lestage) -->
    <div v-else-if="exercise.measurement_type === 'reps'" class="space-y-4">
      <div class="space-y-2">
        <Label>Répétitions</Label>
        <Input
          v-model="setData.reps"
          type="number"
          placeholder="0"
          :class="{ 'border-red-500 ring-red-500': fieldErrors.reps }"
        />
      </div>
      <div class="space-y-2">
        <Label>
          Poids (optionnel)
          <span class="text-xs text-muted-foreground block mt-1">
            Pour exercices lestés (gilet, ceinture, etc.)
          </span>
        </Label>
        <Input
          v-model="setData.weight_kg"
          type="number"
          step="0.5"
          placeholder="0"
          :class="{ 'border-red-500 ring-red-500': fieldErrors.weight_kg }"
        />
        <p v-if="setData.weight_kg && parseFloat(setData.weight_kg) > 0" class="text-xs text-primary mt-1">
          💡 Exercice lesté : +{{ setData.weight_kg }}kg
        </p>
      </div>
    </div>

    <!-- Type: time -->
    <div v-else-if="exercise.measurement_type === 'time'" class="space-y-4">
      <div class="space-y-2">
        <Label>Durée (secondes)</Label>
        <Input
          v-model="setData.duration_seconds"
          type="number"
          placeholder="0"
          :class="{ 'border-red-500 ring-red-500': fieldErrors.duration_seconds }"
        />
        <p class="text-xs text-muted-foreground">
          {{ formatDuration(setData.duration_seconds) }}
        </p>
      </div>
    </div>

    <!-- Type: time_reps -->
    <div v-else-if="exercise.measurement_type === 'time_reps'" class="grid grid-cols-2 gap-4">
      <div class="space-y-2">
        <Label>Durée (secondes)</Label>
        <Input
          v-model="setData.duration_seconds"
          type="number"
          placeholder="0"
          :class="{ 'border-red-500 ring-red-500': fieldErrors.duration_seconds }"
        />
      </div>
      <div class="space-y-2">
        <Label>Répétitions</Label>
        <Input
          v-model="setData.reps"
          type="number"
          placeholder="0"
          :class="{ 'border-red-500 ring-red-500': fieldErrors.reps }"
        />
      </div>
    </div>

    <!-- Type: time_distance -->
    <div v-else-if="exercise.measurement_type === 'time_distance'" class="grid grid-cols-2 gap-4">
      <div class="space-y-2">
        <Label>Durée (secondes)</Label>
        <Input
          v-model="setData.duration_seconds"
          type="number"
          placeholder="0"
          :class="{ 'border-red-500 ring-red-500': fieldErrors.duration_seconds }"
        />
      </div>
      <div class="space-y-2">
        <Label>Distance (mètres)</Label>
        <Input
          v-model="setData.distance_meters"
          type="number"
          step="0.01"
          placeholder="0"
          :class="{ 'border-red-500 ring-red-500': fieldErrors.distance_meters }"
        />
      </div>
    </div>

    <!-- Type: distance -->
    <div v-else-if="exercise.measurement_type === 'distance'" class="space-y-2">
      <Label>Distance (mètres)</Label>
      <Input
        v-model="setData.distance_meters"
        type="number"
        step="0.01"
        placeholder="0"
        :class="{ 'border-red-500 ring-red-500': fieldErrors.distance_meters }"
      />
    </div>

    <!-- Type: weight_only -->
    <div v-else-if="exercise.measurement_type === 'weight_only'" class="space-y-2">
      <Label>Poids (kg)</Label>
      <Input
        v-model="setData.weight_kg"
        type="number"
        step="0.5"
        placeholder="0"
        :class="{ 'border-red-500 ring-red-500': fieldErrors.weight_kg }"
      />
    </div>

    <!-- Champs communs -->
    <div class="grid grid-cols-2 gap-4">
      <div class="space-y-2">
        <Label>Repos (secondes)</Label>
        <Input
          v-model="setData.rest_seconds"
          type="number"
          placeholder="0"
        />
      </div>
      <div class="space-y-2">
        <div class="flex items-center gap-1.5">
          <Label>RPE (1-10)</Label>
          <Dialog v-model:open="showRpeInfo">
            <DialogTrigger asChild>
              <button
                type="button"
                class="text-muted-foreground hover:text-foreground transition-colors"
              >
                <Info class="h-4 w-4" />
              </button>
            </DialogTrigger>
            <DialogContent class="max-w-md">
              <DialogHeader>
                <DialogTitle>Qu'est-ce que le RPE ?</DialogTitle>
                <DialogDescription>
                  Rating of Perceived Exertion (Échelle de difficulté perçue)
                </DialogDescription>
              </DialogHeader>
              <div class="space-y-3">
                <p class="text-sm text-foreground">
                  Le RPE est une échelle de 1 à 10 qui mesure la difficulté ressentie pendant une série :
                </p>
                <div class="space-y-2 text-sm">
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-primary">1-3</span>
                    <span class="text-muted-foreground">Très facile</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-primary">4-6</span>
                    <span class="text-muted-foreground">Modéré</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-primary">7-8</span>
                    <span class="text-muted-foreground">Difficile (2-3 reps en réserve)</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-primary">9</span>
                    <span class="text-muted-foreground">Très difficile (1 rep en réserve)</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-primary">10</span>
                    <span class="text-muted-foreground">Maximum absolu (échec musculaire)</span>
                  </div>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
        <Input
          v-model="setData.rpe"
          type="number"
          min="1"
          max="10"
          placeholder="0"
        />
      </div>
    </div>

    <div class="space-y-2">
      <Label>Note (optionnel)</Label>
      <Textarea
        v-model="setData.note"
        rows="2"
        placeholder="Ajouter une note..."
      />
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Info } from 'lucide-vue-next'

const showRpeInfo = ref(false)

const props = defineProps({
  exercise: {
    type: Object,
    required: true
  },
  modelValue: {
    type: Object,
    default: () => ({
      weight_kg: null,
      reps: null,
      duration_seconds: null,
      distance_meters: null,
      rest_seconds: null,
      rpe: null,
      note: null
    })
  },
  fieldErrors: {
    type: Object,
    default: () => ({})
  }
})

const emit = defineEmits(['update:modelValue'])

const setData = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const formatDuration = (seconds) => {
  if (!seconds || seconds === 0) return ''
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  if (mins > 0) {
    return `${mins}min ${secs}s`
  }
  return `${secs}s`
}
</script>

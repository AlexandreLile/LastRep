<template>
  <div class="space-y-4">
    <!-- Type: weight_reps (défaut si measurement_type n'est pas défini) -->
    <div v-if="!exercise.measurement_type || exercise.measurement_type === 'weight_reps'" class="grid grid-cols-2 gap-4">
      <div class="space-y-2">
        <Label>Poids (kg) *</Label>
        <Input
          v-model="setData.weight_kg"
          type="number"
          step="0.5"
          placeholder="0"
          required
        />
      </div>
      <div class="space-y-2">
        <Label>Répétitions *</Label>
        <Input
          v-model="setData.reps"
          type="number"
          placeholder="0"
          required
        />
      </div>
    </div>

    <!-- Type: reps (poids optionnel pour lestage) -->
    <div v-else-if="exercise.measurement_type === 'reps'" class="space-y-4">
      <div class="space-y-2">
        <Label>Répétitions *</Label>
        <Input
          v-model="setData.reps"
          type="number"
          placeholder="0"
          required
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
        />
        <p v-if="setData.weight_kg && parseFloat(setData.weight_kg) > 0" class="text-xs text-primary mt-1">
          💡 Exercice lesté : +{{ setData.weight_kg }}kg
        </p>
      </div>
    </div>

    <!-- Type: time -->
    <div v-else-if="exercise.measurement_type === 'time'" class="space-y-4">
      <div class="space-y-2">
        <Label>Durée (secondes) *</Label>
        <Input
          v-model="setData.duration_seconds"
          type="number"
          placeholder="0"
          required
        />
        <p class="text-xs text-muted-foreground">
          {{ formatDuration(setData.duration_seconds) }}
        </p>
      </div>
      <div class="space-y-2">
        <Label>Nombre de séries (optionnel)</Label>
        <Input
          v-model="setData.reps"
          type="number"
          placeholder="1"
        />
      </div>
    </div>

    <!-- Type: time_reps -->
    <div v-else-if="exercise.measurement_type === 'time_reps'" class="grid grid-cols-2 gap-4">
      <div class="space-y-2">
        <Label>Durée (secondes) *</Label>
        <Input
          v-model="setData.duration_seconds"
          type="number"
          placeholder="0"
          required
        />
      </div>
      <div class="space-y-2">
        <Label>Répétitions *</Label>
        <Input
          v-model="setData.reps"
          type="number"
          placeholder="0"
          required
        />
      </div>
    </div>

    <!-- Type: time_distance -->
    <div v-else-if="exercise.measurement_type === 'time_distance'" class="grid grid-cols-2 gap-4">
      <div class="space-y-2">
        <Label>Durée (secondes) *</Label>
        <Input
          v-model="setData.duration_seconds"
          type="number"
          placeholder="0"
          required
        />
      </div>
      <div class="space-y-2">
        <Label>Distance (mètres) *</Label>
        <Input
          v-model="setData.distance_meters"
          type="number"
          step="0.01"
          placeholder="0"
          required
        />
      </div>
    </div>

    <!-- Type: distance -->
    <div v-else-if="exercise.measurement_type === 'distance'" class="space-y-2">
      <Label>Distance (mètres) *</Label>
      <Input
        v-model="setData.distance_meters"
        type="number"
        step="0.01"
        placeholder="0"
        required
      />
    </div>

    <!-- Type: weight_only -->
    <div v-else-if="exercise.measurement_type === 'weight_only'" class="space-y-2">
      <Label>Poids (kg) *</Label>
      <Input
        v-model="setData.weight_kg"
        type="number"
        step="0.5"
        placeholder="0"
        required
      />
    </div>

    <!-- Champs communs -->
    <div class="grid grid-cols-2 gap-4">
      <div class="space-y-2">
        <Label>Repos (secondes)</Label>
        <Input
          v-model="setData.rest_seconds"
          type="number"
          placeholder="60"
        />
      </div>
      <div class="space-y-2">
        <Label>RPE (1-10)</Label>
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
import { computed } from 'vue'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

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

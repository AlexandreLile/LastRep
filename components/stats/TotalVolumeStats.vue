<template>
  <div>
    <!-- Pour exercices en temps (isométrie) -->
    <template v-if="isTimeExercise">
      <h3 class="text-lg font-medium mb-2">Temps total effectué</h3>
      <p class="text-sm text-muted-foreground mb-4">Temps total effectué en tout</p>
      
      <div class="flex items-baseline space-x-2">
        <p class="text-2xl font-semibold">{{ formatDuration(totalTimeAll) }}</p>
      </div>
    </template>
    
    <!-- Pour exercices avec poids -->
    <template v-else-if="!isRepsOnly">
      <h3 class="text-lg font-medium mb-2">Volume total</h3>
      <p class="text-sm text-muted-foreground mb-4">Poids total soulevé lors de la dernière séance</p>
      
      <div class="flex items-baseline space-x-2">
        <p class="text-2xl font-semibold">{{ totalVolume }} kg</p>
        <span v-if="volumeDifference !== null"
          :class="[
            'flex items-center space-x-1 text-sm font-medium',
            volumeDifference > 0 ? 'text-green-500' : volumeDifference < 0 ? 'text-red-500' : 'text-muted-foreground'
          ]"
        >
          <svg v-if="volumeDifference > 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" /></svg>
          <svg v-if="volumeDifference < 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" /></svg>
          <span>{{ Math.abs(volumeDifference).toFixed(0) }} kg</span>
        </span>
        <span v-else class="text-muted-foreground text-sm">(pas de comparaison)</span>
      </div>
    </template>
    
    <!-- Pour exercices au poids du corps (reps) -->
    <template v-else>
      <h3 class="text-lg font-medium mb-2">Total de répétitions</h3>
      <p class="text-sm text-muted-foreground mb-4">Nombre total de répétitions lors de la dernière séance</p>
      
      <div class="flex items-baseline space-x-2">
        <p class="text-2xl font-semibold">{{ totalReps !== null ? totalReps + ' reps' : '0 reps' }}</p>
        <span v-if="repsDifference !== null"
          :class="[
            'flex items-center space-x-1 text-sm font-medium',
            repsDifference > 0 ? 'text-green-500' : repsDifference < 0 ? 'text-red-500' : 'text-muted-foreground'
          ]"
        >
          <svg v-if="repsDifference > 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" /></svg>
          <svg v-if="repsDifference < 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" /></svg>
          <span>{{ Math.abs(repsDifference) }} reps</span>
        </span>
        <span v-else class="text-muted-foreground text-sm">(pas de comparaison)</span>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  measurementType: {
    type: String,
    default: 'weight_reps'
  },
  lastSessionSets: {
    type: Array,
    default: () => []
  },
  prevSessionSets: {
    type: Array,
    default: () => []
  },
  allSets: {
    type: Array,
    default: () => []
  }
})

const lastSessionSets = computed(() => props.lastSessionSets)
const prevSessionSets = computed(() => props.prevSessionSets)
const allSets = computed(() => props.allSets)

const isRepsOnly = computed(() => props.measurementType === 'reps')
const isTimeExercise = computed(() => props.measurementType === 'time')

// Calculer le volume total (poids x répétitions) pour une séance
const calculateVolume = (sets) => {
  return sets.reduce((total, set) => {
    return total + ((set.weight_kg || 0) * (set.reps || 0))
  }, 0)
}

// Volume total de la dernière séance
const totalVolume = computed(() => {
  if (!lastSessionSets.value.length) return 0
  return Math.round(calculateVolume(lastSessionSets.value))
})

// Volume total de la séance précédente
const prevTotalVolume = computed(() => {
  if (!prevSessionSets.value.length) return null
  return Math.round(calculateVolume(prevSessionSets.value))
})

// Différence entre les deux séances
const volumeDifference = computed(() => {
  if (prevTotalVolume.value === null) return null
  return totalVolume.value - prevTotalVolume.value
})

// Pour exercices au poids du corps : total de répétitions
const calculateTotalReps = (sets) => {
  return sets.reduce((total, set) => {
    return total + (set.reps || 0)
  }, 0)
}

const totalReps = computed(() => {
  if (!lastSessionSets.value.length) return null
  return calculateTotalReps(lastSessionSets.value)
})

const prevTotalReps = computed(() => {
  if (!prevSessionSets.value.length) return null
  return calculateTotalReps(prevSessionSets.value)
})

const repsDifference = computed(() => {
  if (totalReps.value === null || prevTotalReps.value === null) return null
  return totalReps.value - prevTotalReps.value
})

// Pour exercices en temps : temps total
const calculateTotalTime = (sets) => {
  return sets.reduce((total, set) => {
    return total + (set.duration_seconds || 0)
  }, 0)
}

// Temps total de toutes les séances pour les exercices en temps
const totalTimeAll = computed(() => {
  if (!allSets.value || allSets.value.length === 0) return 0
  return calculateTotalTime(allSets.value)
})

// Fonction pour formater la durée
const formatDuration = (seconds) => {
  if (!seconds) return '0s'
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  if (mins > 0) {
    return `${mins}min ${secs}s`
  }
  return `${secs}s`
}

</script> 
<template>
  <div>
    <!-- Pour exercices en temps (isométrie) -->
    <template v-if="isTimeExercise">
      <h3 class="text-lg font-medium mb-2">Meilleur temps sur une série</h3>
      <p class="text-sm text-muted-foreground mb-4">Comparaison avec la dernière séance</p>
      
      <div class="flex items-baseline space-x-2">
        <p class="text-2xl font-semibold">
          {{ maxTime !== null ? formatDuration(maxTime) : '-' }}
        </p>
        <span v-if="timeDifference !== null"
          :class="[
            'flex items-center space-x-1 text-sm font-medium',
            timeDifference > 0 ? 'text-green-500' : timeDifference < 0 ? 'text-red-500' : 'text-muted-foreground'
          ]"
        >
          <svg v-if="timeDifference > 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" /></svg>
          <svg v-if="timeDifference < 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" /></svg>
          <span>{{ formatDuration(Math.abs(timeDifference)) }}</span>
        </span>
        <span v-else class="text-muted-foreground text-sm">(pas de comparaison)</span>
      </div>
    </template>
    
    <!-- Pour exercices avec poids -->
    <template v-else-if="!isRepsOnly">
      <h3 class="text-lg font-medium mb-2">RM estimé</h3>
      <p class="text-sm text-muted-foreground mb-4">Basé sur votre dernière séance</p>
      
      <div class="flex items-baseline space-x-2">
        <p class="text-2xl font-semibold">
          {{ lastSessionRM !== null ? lastSessionRM.toFixed(1) + ' kg' : '-' }}
        </p>
        <span v-if="rmDifference !== null"
          :class="[
            'flex items-center space-x-1 text-sm font-medium',
            rmDifference > 0 ? 'text-green-500' : rmDifference < 0 ? 'text-red-500' : 'text-muted-foreground'
          ]"
        >
          <svg v-if="rmDifference > 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" /></svg>
          <svg v-if="rmDifference < 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" /></svg>
          <span>{{ Math.abs(rmDifference).toFixed(1) }} kg</span>
        </span>
        <span v-else class="text-muted-foreground text-sm">(pas de comparaison)</span>
      </div>
    </template>
    
    <!-- Pour exercices au poids du corps (reps) -->
    <template v-else>
      <h3 class="text-lg font-medium mb-2">Max reps en une série</h3>
      <p class="text-sm text-muted-foreground mb-4">Comparaison avec la dernière séance</p>
      
      <div class="flex items-baseline space-x-2">
        <p class="text-2xl font-semibold">
          {{ maxReps !== null ? maxReps + ' reps' : '-' }}
        </p>
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
  }
})

const lastSessionSets = computed(() => props.lastSessionSets)
const prevSessionSets = computed(() => props.prevSessionSets)

const isRepsOnly = computed(() => props.measurementType === 'reps')
const isTimeExercise = computed(() => props.measurementType === 'time')

function calculateRM(weight, reps) {
  return weight * (1 + 0.0333 * reps)
}

// Calculer le meilleur RM pour un groupe de sets
const calculateBestRM = (sets) => {
  if (!sets.length) return null
  
  let bestRM = 0
  sets.forEach(set => {
    const rm = calculateRM(set.weight_kg || 0, set.reps)
    if (rm > bestRM) {
      bestRM = rm
    }
  })
  
  return bestRM
}

// RM de la dernière séance
const lastSessionRM = computed(() => {
  return calculateBestRM(lastSessionSets.value)
})

// RM de la séance précédente
const prevSessionRM = computed(() => {
  return calculateBestRM(prevSessionSets.value)
})

// Différence entre les deux séances
const rmDifference = computed(() => {
  if (lastSessionRM.value === null || prevSessionRM.value === null) return null
  return lastSessionRM.value - prevSessionRM.value
})

// Pour exercices au poids du corps : max reps
const maxReps = computed(() => {
  if (!lastSessionSets.value.length) return null
  return Math.max(...lastSessionSets.value.map(set => set.reps || 0))
})

const prevMaxReps = computed(() => {
  if (!prevSessionSets.value.length) return null
  return Math.max(...prevSessionSets.value.map(set => set.reps || 0))
})

const repsDifference = computed(() => {
  if (maxReps.value === null || prevMaxReps.value === null) return null
  return maxReps.value - prevMaxReps.value
})

// Pour exercices en temps : meilleur temps
const maxTime = computed(() => {
  if (!lastSessionSets.value.length) return null
  return Math.max(...lastSessionSets.value.map(set => set.duration_seconds || 0))
})

const prevMaxTime = computed(() => {
  if (!prevSessionSets.value.length) return null
  return Math.max(...prevSessionSets.value.map(set => set.duration_seconds || 0))
})

const timeDifference = computed(() => {
  if (maxTime.value === null || prevMaxTime.value === null) return null
  return maxTime.value - prevMaxTime.value
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
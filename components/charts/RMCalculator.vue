<template>
  <span v-if="loading" class="text-gray-400">...</span>
  <span v-else-if="error" class="text-red-500">Erreur</span>
  <span v-else-if="bestSet">{{ estimatedRM.toFixed(1) }} kg</span>
  <span v-else>-</span>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  sets: {
    type: Array,
    default: () => []
  }
})

const loading = ref(true)
const error = ref(null)
const bestSet = ref(null)
const estimatedRM = ref(0)

const calculateRM = (weight, reps) => {
  // Formule d'Epley : RM = Poids × (1 + 0.0333 × Répétitions)
  return weight * (1 + 0.0333 * reps)
}

const computeBestSet = (sets) => {
  loading.value = true
  try {
    bestSet.value = null
    estimatedRM.value = 0

    if (sets && sets.length > 0) {
      // Trouver la série avec le 1RM estimé le plus élevé
      let maxRM = 0
      let bestSetFound = null

      sets.forEach(set => {
        const rm = calculateRM(set.weight_kg, set.reps)
        if (rm > maxRM) {
          maxRM = rm
          bestSetFound = set
        }
      })

      if (bestSetFound) {
        bestSet.value = bestSetFound
        estimatedRM.value = maxRM
      }
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

watch(() => props.sets, computeBestSet, { immediate: true })
</script> 
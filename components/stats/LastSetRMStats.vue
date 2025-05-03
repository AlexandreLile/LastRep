<template>
  <div>
    <h3 class="text-lg font-medium mb-2">RM estimé</h3>
    <p class="text-sm text-muted-foreground mb-4">Basé sur votre dernière série</p>
    
    <div class="flex items-baseline space-x-2">
      <p class="text-2xl font-semibold">
        {{ lastRM !== null ? lastRM.toFixed(1) + ' kg' : '-' }}
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
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useSupabaseClient } from '#imports'

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const supabase = useSupabaseClient()
const lastSet = ref(null)
const prevSet = ref(null)

function calculateRM(weight, reps) {
  return weight * (1 + 0.0333 * reps)
}

const lastRM = computed(() => {
  if (!lastSet.value) return null
  return calculateRM(lastSet.value.weight_kg, lastSet.value.reps)
})

const prevRM = computed(() => {
  if (!prevSet.value) return null
  return calculateRM(prevSet.value.weight_kg, prevSet.value.reps)
})

const rmDifference = computed(() => {
  if (lastRM.value === null || prevRM.value === null) return null
  return lastRM.value - prevRM.value
})

const loadSets = async () => {
  try {
    const user = (await supabase.auth.getUser()).data.user
    if (!user) throw new Error('Utilisateur non authentifié')
    const { data: setsData, error } = await supabase
      .from('exerciseset')
      .select('id, weight_kg, reps, created_at')
      .eq('exercise_id', props.exerciseId)
      .eq('user_id', user.id)
      .order('created_at', { ascending: true })
      .limit(100)
    if (error) throw error
    if (!setsData.length) {
      lastSet.value = null
      prevSet.value = null
      return
    }
    lastSet.value = setsData[setsData.length - 1]
    prevSet.value = setsData.length > 1 ? setsData[setsData.length - 2] : null
  } catch (e) {
    lastSet.value = null
    prevSet.value = null
    console.error('Erreur chargement sets pour RM:', e)
  }
}

onMounted(loadSets)
watch(() => props.exerciseId, loadSets)
</script> 
<template>
  <div>
    <!-- Pour exercices avec poids -->
    <template v-if="!isRepsOnly">
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
import { ref, onMounted, watch, computed } from 'vue'
import { useSupabaseClient } from '#imports'

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const supabase = useSupabaseClient()
const lastSessionSets = ref([])
const prevSessionSets = ref([])
const exercise = ref(null)

// Récupérer le measurement_type de l'exercice
const isRepsOnly = computed(() => {
  return exercise.value?.measurement_type === 'reps'
})

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

const loadSets = async () => {
  try {
    const user = (await supabase.auth.getUser()).data.user
    if (!user) throw new Error('Utilisateur non authentifié')
    
    // Récupérer l'exercice pour connaître son measurement_type
    const { data: exerciseData, error: exerciseError } = await supabase
      .from('exercise')
      .select('measurement_type')
      .eq('id', props.exerciseId)
      .single()
    
    if (exerciseError) throw exerciseError
    exercise.value = exerciseData
    
    // 1. Récupérer toutes les performed sessions où cet exercice figure, avec leurs sets
    const { data: sessionsData, error } = await supabase
      .from('performedsession')
      .select(`
        id,
        ended_at,
        exerciseset:exerciseset!inner(
          id,
          exercise_id,
          weight_kg,
          reps,
          created_at
        )
      `)
      .eq('user_id', user.id)
      .not('ended_at', 'is', null)
      .order('ended_at', { ascending: false })
      .limit(10)
    
    if (error) throw error
    
    // 2. Filtrer les sessions qui contiennent au moins un set de cet exercice
    const filteredSessions = sessionsData
      .map(session => ({
        ...session,
        sets: session.exerciseset.filter(set => set.exercise_id === props.exerciseId)
      }))
      .filter(session => session.sets.length > 0)
    
    // 3. Prendre la plus récente et la précédente
    lastSessionSets.value = filteredSessions[0]?.sets || []
    prevSessionSets.value = filteredSessions[1]?.sets || []
  } catch (e) {
    console.error('Erreur chargement sets pour volume total:', e)
    lastSessionSets.value = []
    prevSessionSets.value = []
  }
}

onMounted(loadSets)
watch(() => props.exerciseId, loadSets)
</script> 
<template>
  <div>
    <!-- Pour exercices avec poids -->
    <template v-if="!isRepsOnly">
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
import { ref, computed, onMounted, watch } from 'vue'
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
const loading = ref(true)
const exercise = ref(null)

// Récupérer le measurement_type de l'exercice
const isRepsOnly = computed(() => {
  return exercise.value?.measurement_type === 'reps'
})

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

const loadSets = async () => {
  loading.value = true
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
    lastSessionSets.value = []
    prevSessionSets.value = []
    console.error('Erreur chargement sets pour RM:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadSets)
watch(() => props.exerciseId, loadSets)
</script> 
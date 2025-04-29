<template>
  <span v-if="loading" class="text-gray-400">...</span>
  <span v-else-if="error" class="text-red-500">Erreur</span>
  <span v-else-if="bestSet">{{ estimatedRM.toFixed(1) }} kg</span>
  <span v-else>-</span>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useSupabaseClient } from '#imports'

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const supabase = useSupabaseClient()
const loading = ref(true)
const error = ref(null)
const bestSet = ref(null)
const estimatedRM = ref(0)

const calculateRM = (weight, reps) => {
  // Formule d'Epley : RM = Poids × (1 + 0.0333 × Répétitions)
  return weight * (1 + 0.0333 * reps)
}

const loadBestSet = async () => {
  try {
    loading.value = true
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    // Récupérer toutes les séries de l'exercice
    const { data, error: fetchError } = await supabase
      .from('exerciseset')
      .select('weight_kg, reps')
      .eq('exercise_id', props.exerciseId)
      .eq('user_id', user.id)
      .order('weight_kg', { ascending: false })
      .limit(1)

    if (fetchError) throw fetchError

    if (data && data.length > 0) {
      bestSet.value = data[0]
      estimatedRM.value = calculateRM(bestSet.value.weight_kg, bestSet.value.reps)
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

onMounted(loadBestSet)
watch(() => props.exerciseId, loadBestSet)
</script> 
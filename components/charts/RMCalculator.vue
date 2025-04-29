<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Calcul de la RM</h3>
    
    <div v-if="loading" class="flex justify-center items-center h-32">
      <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-4">
      {{ error }}
    </div>

    <div v-else-if="bestSet" class="space-y-4">
      <div class="grid grid-cols-2 gap-4">
        <div class="bg-gray-50 dark:bg-gray-700 p-4 rounded-lg">
          <p class="text-sm text-gray-500 dark:text-gray-400">Meilleure série</p>
          <p class="text-lg font-semibold text-gray-900 dark:text-white">
            {{ bestSet.weight_kg }}kg × {{ bestSet.reps }} reps
          </p>
        </div>
        
        <div class="bg-primary-50 dark:bg-primary-900 p-4 rounded-lg">
          <p class="text-sm text-primary-600 dark:text-primary-400">RM estimée</p>
          <p class="text-lg font-semibold text-primary-900 dark:text-white">
            {{ estimatedRM.toFixed(1) }}kg
          </p>
        </div>
      </div>

      <div class="text-sm text-gray-500 dark:text-gray-400">
        <p>Calculée avec la formule d'Epley :</p>
        <p class="italic">RM = Poids × (1 + 0.0333 × Répétitions)</p>
      </div>
    </div>

    <div v-else class="text-center py-8 text-gray-500 dark:text-gray-400">
      Aucune série enregistrée pour cet exercice
    </div>
  </div>
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
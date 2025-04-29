<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else class="space-y-6">
      <!-- En-tête -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">{{ exercise.name }}</h1>
            <p class="text-gray-500 dark:text-gray-400 mt-2">
              Muscle principal : {{ exercise.primary_muscle }}
            </p>
          </div>
          <button 
            @click="navigateTo('/exercices')"
            class="px-4 py-2 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
          >
            Retour
          </button>
        </div>
      </div>

      <!-- Statistiques -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">Statistiques</h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="bg-gray-50 dark:bg-gray-700 p-4 rounded-lg">
            <p class="text-sm text-gray-500 dark:text-gray-400">Total des séries</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.total_sets }}</p>
          </div>
          
          <div class="bg-gray-50 dark:bg-gray-700 p-4 rounded-lg">
            <p class="text-sm text-gray-500 dark:text-gray-400">Poids maximum</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.max_weight }} kg</p>
          </div>
          
          <div class="bg-gray-50 dark:bg-gray-700 p-4 rounded-lg">
            <p class="text-sm text-gray-500 dark:text-gray-400">Répétitions maximum</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.max_reps }}</p>
          </div>
          
          <div class="bg-gray-50 dark:bg-gray-700 p-4 rounded-lg">
            <p class="text-sm text-gray-500 dark:text-gray-400">Poids moyen</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.avg_weight }} kg</p>
          </div>
        </div>
      </div>

      <!-- Graphiques -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <WeightRepsChart :exercise-id="route.params.id" />
        <WeightProgressionChart :exercise-id="route.params.id" />
      </div>

      <div class="mt-6">
        <RMCalculator :exercise-id="route.params.id" />
      </div>

      <!-- Historique des séries -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">Historique des séries</h2>
        
        <div v-if="sets.length > 0" class="space-y-4">
          <div 
            v-for="set in sets" 
            :key="set.id"
            class="border dark:border-gray-700 rounded-lg p-4"
          >
            <div class="grid grid-cols-3 gap-4">
              <div>
                <p class="text-sm text-gray-500 dark:text-gray-400">Poids</p>
                <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ set.weight_kg }} kg</p>
              </div>
              <div>
                <p class="text-sm text-gray-500 dark:text-gray-400">Répétitions</p>
                <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ set.reps }}</p>
              </div>
              <div>
                <p class="text-sm text-gray-500 dark:text-gray-400">Date</p>
                <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ formatDate(set.created_at) }}</p>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8 text-gray-500 dark:text-gray-400">
          Aucune série enregistrée pour cet exercice
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'
import WeightRepsChart from '~/components/charts/WeightRepsChart.vue'
import WeightProgressionChart from '~/components/charts/WeightProgressionChart.vue'
import RMCalculator from '~/components/charts/RMCalculator.vue'

const route = useRoute()
const supabase = useSupabaseClient()

const exercise = ref(null)
const sets = ref([])
const stats = ref({
  total_sets: 0,
  max_weight: 0,
  max_reps: 0,
  avg_weight: 0
})
const loading = ref(true)
const error = ref(null)

const loadExerciseData = async () => {
  try {
    loading.value = true
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    // Récupérer l'exercice
    const { data: exerciseData, error: exerciseError } = await supabase
      .from('exercise')
      .select('*')
      .eq('id', route.params.id)
      .single()

    if (exerciseError) throw exerciseError
    exercise.value = exerciseData

    // Récupérer les séries
    const { data: setsData, error: setsError } = await supabase
      .from('exerciseset')
      .select(`
        id,
        weight_kg,
        reps,
        created_at
      `)
      .eq('exercise_id', route.params.id)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })

    if (setsError) throw setsError
    sets.value = setsData

    // Calculer les statistiques
    if (setsData.length > 0) {
      stats.value = {
        total_sets: setsData.length,
        max_weight: Math.max(...setsData.map(s => s.weight_kg)),
        max_reps: Math.max(...setsData.map(s => s.reps)),
        avg_weight: setsData.reduce((acc, curr) => acc + curr.weight_kg, 0) / setsData.length
      }
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

onMounted(loadExerciseData)
</script> 
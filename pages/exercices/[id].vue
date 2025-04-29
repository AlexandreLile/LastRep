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
            <div class="flex justify-between items-start">
              <div class="grid grid-cols-3 gap-4 flex-1">
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
              <button 
                @click="openEditModal(set)"
                class="p-2 text-gray-500 hover:text-primary transition-colors"
              >
                <Pencil class="h-5 w-5" />
              </button>
            </div>
            <div v-if="set.note" class="mt-2 text-sm text-gray-600 dark:text-gray-300">
              {{ set.note }}
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8 text-gray-500 dark:text-gray-400">
          Aucune série enregistrée pour cet exercice
        </div>
      </div>
    </div>

    <!-- Modal d'édition -->
    <div v-if="editingSet" class="fixed inset-0 bg-black/50 flex items-center justify-center p-4">
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 w-full max-w-md">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Modifier la série</h3>
          <button @click="closeEditModal" class="text-gray-500 hover:text-gray-700 dark:hover:text-gray-300">
            <X class="h-5 w-5" />
          </button>
        </div>
        
        <form @submit.prevent="handleEditSet" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Poids (kg)</label>
              <input 
                v-model="editForm.weight_kg" 
                type="number" 
                step="0.5" 
                class="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                required
              >
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Répétitions</label>
              <input 
                v-model="editForm.reps" 
                type="number" 
                class="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                required
              >
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Temps de repos (s)</label>
              <input 
                v-model="editForm.rest_seconds" 
                type="number" 
                class="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                required
              >
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">RPE (1-10)</label>
              <input 
                v-model="editForm.rpe" 
                type="number" 
                min="1" 
                max="10" 
                class="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
              >
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Note</label>
            <textarea 
              v-model="editForm.note" 
              class="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
              rows="2"
            ></textarea>
          </div>
          <div class="flex justify-end space-x-2">
            <button 
              type="button" 
              @click="closeEditModal"
              class="px-4 py-2 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
            >
              Annuler
            </button>
            <button 
              type="submit" 
              class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors"
            >
              Enregistrer
            </button>
          </div>
        </form>
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
import { Pencil, X } from 'lucide-vue-next'

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
const editingSet = ref(null)
const editForm = ref({
  weight_kg: '',
  reps: '',
  rest_seconds: '',
  rpe: '',
  note: ''
})

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
        rest_seconds,
        rpe,
        note,
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

const openEditModal = (set) => {
  editingSet.value = set
  editForm.value = {
    weight_kg: set.weight_kg,
    reps: set.reps,
    rest_seconds: set.rest_seconds,
    rpe: set.rpe,
    note: set.note
  }
}

const closeEditModal = () => {
  editingSet.value = null
  editForm.value = {
    weight_kg: '',
    reps: '',
    rest_seconds: '',
    rpe: '',
    note: ''
  }
}

const handleEditSet = async () => {
  try {
    const { error: updateError } = await supabase
      .from('exerciseset')
      .update({
        weight_kg: editForm.value.weight_kg,
        reps: editForm.value.reps,
        rest_seconds: editForm.value.rest_seconds,
        rpe: editForm.value.rpe,
        note: editForm.value.note
      })
      .eq('id', editingSet.value.id)

    if (updateError) throw updateError

    // Recharger les données
    await loadExerciseData()
    closeEditModal()
  } catch (e) {
    error.value = e.message
  }
}

onMounted(loadExerciseData)
</script> 
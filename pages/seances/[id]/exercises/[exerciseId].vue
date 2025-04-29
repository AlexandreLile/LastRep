<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else class="space-y-6">
      <!-- En-tête de l'exercice -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">{{ exercise.exercise?.name }}</h1>
            <p class="text-gray-500 dark:text-gray-400 mt-2">
              Muscle principal : {{ exercise.exercise?.primary_muscle }}
            </p>
          </div>
          <button 
            @click="navigateTo(`/seances/${$route.params.id}/start`)" 
            class="bg-gray-500 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition-colors"
          >
            Retour
          </button>
        </div>
      </div>

      <!-- Formulaire d'ajout de série -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">Ajouter une série</h2>
        <form @submit.prevent="handleAddSet" class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Poids (kg)</label>
              <input 
                v-model="newSet.weight" 
                type="number" 
                step="0.5" 
                class="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                required
              >
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Répétitions</label>
              <input 
                v-model="newSet.reps" 
                type="number" 
                class="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                required
              >
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Temps de repos (secondes)</label>
              <input 
                v-model="newSet.restTime" 
                type="number" 
                class="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                required
              >
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">RPE (1-10)</label>
              <input 
                v-model="newSet.rpe" 
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
              v-model="newSet.note" 
              class="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
              rows="2"
            ></textarea>
          </div>
          <button 
            type="submit" 
            class="bg-primary text-white px-4 py-2 rounded-lg hover:bg-primary/90 transition-colors"
            :disabled="exerciseSetLoading"
          >
            {{ exerciseSetLoading ? 'Ajout en cours...' : 'Ajouter la série' }}
          </button>
        </form>
      </div>

      <!-- Liste des séries -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">Séries effectuées</h2>
        <div v-if="exerciseSets.length > 0" class="space-y-4">
          <div 
            v-for="set in exerciseSets" 
            :key="set.id" 
            class="border dark:border-gray-700 rounded-lg p-4"
          >
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Poids</span>
                <p class="font-medium">{{ set.weight_kg }} kg</p>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Répétitions</span>
                <p class="font-medium">{{ set.reps }}</p>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Repos</span>
                <p class="font-medium">{{ set.rest_seconds }}s</p>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">RPE</span>
                <p class="font-medium">{{ set.rpe || '-' }}</p>
              </div>
            </div>
            <p v-if="set.note" class="mt-2 text-sm text-gray-600 dark:text-gray-300">{{ set.note }}</p>
          </div>
        </div>
        <p v-else class="text-center text-gray-500 dark:text-gray-400 py-4">
          Aucune série effectuée pour le moment
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useWorkoutExercise } from '~/composables/useWorkoutExercise'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { useExerciseSet } from '~/composables/useExerciseSet'
import { useSupabaseClient } from '#imports'
import { useSupabaseUser } from '#imports'

const route = useRoute()
const supabase = useSupabaseClient()
const { getWorkoutExercise } = useWorkoutExercise()
const { getCurrentSession } = usePerformedSession(supabase)
const { exerciseSets, error: exerciseSetError, loading: exerciseSetLoading, addExerciseSet, getExerciseSets } = useExerciseSet()

const exercise = ref(null)
const loading = ref(true)
const error = ref(null)

const newSet = ref({
  weight: '',
  reps: '',
  restTime: '',
  rpe: '',
  note: ''
})

const handleAddSet = async () => {
  try {
    const { error: addError } = await addExerciseSet(exercise.value.exercise.id, newSet.value)
    if (addError) throw addError
    
    // Réinitialiser le formulaire
    newSet.value = {
      weight: '',
      reps: '',
      restTime: '',
      rpe: '',
      note: ''
    }
    
    // Recharger les séries
    await loadExerciseSets()
  } catch (e) {
    error.value = e.message
  }
}

const loadExerciseSets = async () => {
  try {
    await getExerciseSets(exercise.value.exercise.id)
  } catch (e) {
    error.value = e.message
  }
}

const loadExercise = async () => {
  try {
    loading.value = true
    // Vérifier si une session est en cours
    const currentSession = getCurrentSession()
    if (!currentSession) {
      navigateTo(`/seances/${route.params.id}/train`)
      return
    }

    const { data, error: exerciseError } = await getWorkoutExercise(route.params.exerciseId)
    if (exerciseError) throw exerciseError
    exercise.value = data

    // Charger les séries de l'exercice
    await loadExerciseSets()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

onMounted(loadExercise)
</script> 
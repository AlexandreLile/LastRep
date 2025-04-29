<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="session" class="space-y-6">
      <!-- En-tête de la séance -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">{{ session.title }}</h1>
            <p class="text-gray-500 dark:text-gray-400 mt-2">
              {{ formatDate(session.date) }}
            </p>
          </div>
          <div class="flex gap-4">
            <button 
              @click="startSession" 
              class="bg-green-500 text-white px-4 py-2 rounded-lg hover:bg-green-600 transition-colors"
            >
              Démarrer la séance
            </button>
            <button 
              @click="editSession" 
              class="bg-primary text-white px-4 py-2 rounded-lg hover:bg-primary/90 transition-colors"
            >
              Modifier
            </button>
            <button 
              @click="deleteSession" 
              class="bg-red-500 text-white px-4 py-2 rounded-lg hover:bg-red-600 transition-colors"
            >
              Supprimer
            </button>
          </div>
        </div>
        
        <div v-if="session.notes" class="mt-6">
          <h2 class="text-xl font-semibold text-gray-800 dark:text-gray-200 mb-2">Notes</h2>
          <p class="text-gray-600 dark:text-gray-300 whitespace-pre-line">{{ session.notes }}</p>
        </div>
      </div>

      <!-- Liste des exercices -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Exercices</h2>
        </div>

        <div v-if="exercises.length > 0" class="space-y-4">
          <div 
            v-for="exercise in exercises" 
            :key="exercise.id" 
            class="border dark:border-gray-700 rounded-lg p-4 hover:shadow-md transition-shadow"
          >
            <div>
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{{ exercise.Exercise?.name }}</h3>
              <p class="text-gray-500 dark:text-gray-400 mt-1">
                Muscle principal : {{ exercise.Exercise?.primary_muscle }}
              </p>
            </div>
          </div>
        </div>

        <div v-else class="text-center py-8 text-gray-500 dark:text-gray-400">
          Aucun exercice pour cette séance
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useWorkoutSessions } from '~/composables/useWorkoutSession'
import { useWorkoutExercise } from '~/composables/useWorkoutExercise'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { useSupabaseClient } from '#imports'
import { useSupabaseUser } from '#imports'

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient()
const { getWorkoutSession, deleteWorkoutSession } = useWorkoutSessions(useSupabaseUser())
const { workoutExercises: exercises, getWorkoutExercises } = useWorkoutExercise()
const { prepareSession, error: performedSessionError } = usePerformedSession(supabase)

const session = ref(null)
const loading = ref(true)
const error = ref(null)

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const loadSession = async () => {
  try {
    loading.value = true
    const { data, error: sessionError } = await getWorkoutSession(route.params.id)
    if (sessionError) throw sessionError
    session.value = data
    // Charger les exercices de la séance
    await getWorkoutExercises(route.params.id)
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

const editSession = () => {
  router.push(`/seances/${route.params.id}/edit`)
}

const deleteSession = async () => {
  if (confirm('Êtes-vous sûr de vouloir supprimer cette séance ?')) {
    try {
      const { error: deleteError } = await deleteWorkoutSession(route.params.id)
      if (deleteError) throw deleteError
      router.push('/seances')
    } catch (e) {
      error.value = e.message
    }
  }
}

const startSession = async () => {
  try {
    const userId = (await supabase.auth.getUser()).data.user.id
    prepareSession(route.params.id, userId)
    router.push(`/seances/${route.params.id}/start`)
  } catch (e) {
    error.value = e.message || performedSessionError.value
  }
}

onMounted(loadSession)
</script> 
<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="session" class="space-y-6">
      <!-- En-tête de la séance en cours -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">{{ session.title }}</h1>
            <p v-if="currentSession" class="text-gray-500 dark:text-gray-400 mt-2">
              Début : {{ formatDate(currentSession.started_at) }}
            </p>
          </div>
          <div class="flex gap-4">
            <Button 
              @click="handleEndSession" 
              class="bg-red-500 text-white px-4 py-2 rounded-lg hover:bg-red-600 transition-colors"
            >
              Terminer la séance
            </Button>
          </div>
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
            class="border dark:border-gray-700 rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
            @click="goToExercise(exercise.id)"
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
import { useWorkoutSessions } from '~/composables/useWorkoutSession'
import { useWorkoutExercise } from '~/composables/useWorkoutExercise'
import { usePerformedSession } from '~/composables/usePerformedSession'

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient()
const { getWorkoutSession } = useWorkoutSessions(useSupabaseUser())
const { workoutExercises: exercises, getWorkoutExercises } = useWorkoutExercise()
const { performedSession, error: performedSessionError, saveSession, getCurrentSession } = usePerformedSession(supabase)

const session = ref(null)
const currentSession = ref(null)
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

const handleEndSession = async () => {
  try {
    await saveSession()
    router.push(`/seances/${route.params.id}/train`)
  } catch (e) {
    error.value = e.message || performedSessionError.value
  }
}

const goToExercise = (exerciseId) => {
  navigateTo(`/seances/${route.params.id}/exercises/${exerciseId}`)
}

const loadSession = async () => {
  try {
    loading.value = true
    const { data, error: sessionError } = await getWorkoutSession(route.params.id)
    if (sessionError) throw sessionError
    session.value = data
    await getWorkoutExercises(route.params.id)
    
    // Vérifier si une session est en cours
    currentSession.value = getCurrentSession()
    if (!currentSession.value) {
      router.push(`/seances/${route.params.id}/train`)
      return
    }
  } catch (e) {
    error.value = e.message || performedSessionError.value
  } finally {
    loading.value = false
  }
}

onMounted(loadSession)
</script> 
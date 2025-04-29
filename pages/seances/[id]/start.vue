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
            <p v-if="performedSession" class="text-gray-500 dark:text-gray-400 mt-2">
              Début : {{ formatDate(performedSession.started_at) }}
            </p>
          </div>
          <div class="flex gap-4">
            <button 
              @click="endSession" 
              class="bg-red-500 text-white px-4 py-2 rounded-lg hover:bg-red-600 transition-colors"
            >
              Terminer la séance
            </button>
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


const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient()
const { getWorkoutSession } = useWorkoutSessions(useSupabaseUser())
const { workoutExercises: exercises, getWorkoutExercises } = useWorkoutExercise()

const session = ref(null)
const performedSession = ref(null)
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

const startPerformedSession = async () => {
  try {
    const { data, error: startError } = await supabase
      .from('performedsession')
      .insert([
        {
          workout_session_id: route.params.id,
          user_id: (await supabase.auth.getUser()).data.user.id,
          started_at: new Date()
        }
      ])
      .select()
      .single()

    if (startError) throw startError
    performedSession.value = data
  } catch (e) {
    error.value = e.message
  }
}

const endSession = async () => {
  try {
    const { error: updateError } = await supabase
      .from('performedsession')
      .update({ ended_at: new Date() })
      .eq('id', performedSession.value.id)

    if (updateError) throw updateError
    router.push(`/seances/${route.params.id}/train`)
  } catch (e) {
    error.value = e.message
  }
}

const goToExercise = (exerciseId) => {
  router.push(`/seances/${route.params.id}/start/${exerciseId}`)
}

const loadSession = async () => {
  try {
    loading.value = true
    const { data, error: sessionError } = await getWorkoutSession(route.params.id)
    if (sessionError) throw sessionError
    session.value = data
    await getWorkoutExercises(route.params.id)
    await startPerformedSession()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

onMounted(loadSession)
</script> 
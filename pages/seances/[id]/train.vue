<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="session">
      <!-- Header -->
      <div class="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="text-2xl font-semibold text-gray-900">{{ session.title }}</h2>
          <div v-if="session.notes" class="mt-2">
            <p class="text-muted-foreground">{{ session.notes }}</p>
          </div>
        </div>
        <div class="flex flex-wrap gap-4">
          <Button 
            @click="startSession" 
            :disabled="exercises.length === 0"
            class="relative overflow-hidden group"
            :class="[
              exercises.length === 0 
                ? 'bg-gray-400 cursor-not-allowed' 
                : 'bg-primary hover:bg-primary/90',
              'text-white px-6 py-3 rounded-lg transition-all duration-300'
            ]"
          >
            <span class="relative z-10">
              {{ exercises.length === 0 ? 'Ajoutez des exercices pour démarrer' : 'Démarrer la séance' }}
            </span>
            <div class="absolute inset-0 bg-gradient-to-r from-primary-light to-primary opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
          </Button>
          <Button 
            @click="editSession" 
            variant="outline"
            class="px-6 py-3 hover:bg-muted/50 transition-colors duration-300"
          >
            Modifier
          </Button>
        </div>
      </div>

      <!-- Main Content -->
      <div class="space-y-8">
        <!-- Exercises List -->
        <div class="bg-white rounded-xl p-8">
          <div class="space-y-6">
            <div>
              <h3 class="text-lg font-medium">Exercices</h3>
              <p class="text-sm text-muted-foreground">Liste des exercices de la séance</p>
            </div>

            <div v-if="exercises.length === 0" class="text-center py-8 text-muted-foreground">
              Aucun exercice pour cette séance
            </div>

            <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div 
                v-for="exercise in exercises" 
                :key="exercise.id"
                class="bg-white rounded-xl p-6 cursor-pointer relative overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg group"
                @click="router.push(`/exercices/${exercise.exercise_id}`)"
              >
                <!-- Effet de bordure néon -->
                <div class="absolute inset-0 rounded-xl bg-primary/20 blur-md transition-all duration-300 group-hover:bg-primary/30 group-hover:blur-lg"></div>
                <div class="absolute inset-0 rounded-xl bg-gradient-to-r from-primary/50 via-primary/30 to-primary/50 animate-[pulse_2s_ease-in-out_infinite] group-hover:from-primary/60 group-hover:via-primary/40 group-hover:to-primary/60"></div>
                <div class="absolute inset-0 rounded-xl bg-gradient-to-br from-primary/40 to-transparent animate-[glow_3s_ease-in-out_infinite] group-hover:from-primary/50 group-hover:to-transparent"></div>
                <div class="absolute inset-[1px] rounded-xl bg-white"></div>

                <!-- Contenu -->
                <div class="relative flex flex-col h-full">
                  <div class="flex flex-wrap gap-4 items-start mb-4">
                    <div class="flex items-center space-x-3 flex-1">
                      <div class="p-2 rounded-full bg-primary/20 transition-all duration-300 group-hover:bg-primary/30 group-hover:scale-110">
                        <Dumbbell class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12" />
                      </div>
                      <div>
                        <h3 class="text-lg font-medium text-gray-900 transition-colors duration-300 group-hover:text-primary">{{ exercise.exercise?.name }}</h3>
                        <span class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full transition-all duration-300 group-hover:bg-primary/10 group-hover:text-primary">
                          {{ exercise.exercise?.primary_muscle }}
                        </span>
                      </div>
                    </div>
                    <div class="flex items-center">
                      <div class="text-sm font-medium text-primary transition-all duration-300 group-hover:scale-105">
                        <div class="text-sm text-muted-foreground transition-colors duration-300 group-hover:text-gray-700">
                          1 RM estimé
                        </div>
                        <div class="text-right">
                          <RMCalculator :exercise-id="exercise.exercise_id" />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Stats -->
        <div class="bg-white rounded-xl">
          <SessionWeightChart :workout-session-id="route.params.id" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRoute, useRouter } from 'vue-router'
import { useWorkoutSessions } from '~/composables/useWorkoutSession'
import { useWorkoutExercise } from '~/composables/useWorkoutExercise'
import { usePerformedSession } from '~/composables/usePerformedSession'
import RMCalculator from '@/components/charts/RMCalculator.vue'
import SessionWeightChart from '@/components/charts/SessionWeightChart.vue'
import { Dumbbell } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient()
const { getWorkoutSession } = useWorkoutSessions(useSupabaseUser())
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

<style scoped>
@keyframes pulse {
  0%, 100% {
    opacity: 0.3;
  }
  50% {
    opacity: 0.7;
  }
}

@keyframes glow {
  0%, 100% {
    opacity: 0.2;
    transform: scale(1);
  }
  50% {
    opacity: 0.4;
    transform: scale(1.02);
  }
}
</style> 
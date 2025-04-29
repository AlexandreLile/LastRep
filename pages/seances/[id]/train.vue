<template>
  <div class="hero relative w-full rounded-2xl p-6">
    <div
      class="max-w-full py-10 sm:max-w-2xl lg:max-w-4xl md:items-start mx-auto flex flex-col justify-center items-start"
    >
      <div v-if="loading" class="flex justify-center items-center h-64">
        <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
      </div>

      <div v-else-if="error" class="text-red-500 text-center py-8">
        {{ error }}
      </div>

      <div v-else-if="session" class="w-full">
        <div class="flex flex-col items-start mb-8">
          <div class="mb-4">
            <h1 class="text-2xl sm:text-3xl md:text-4xl font-bold text-left">
              {{ session.title }}
            </h1>
            <div v-if="session.notes" class="mt-4">
              <p class="text-gray-600 dark:text-gray-300 whitespace-pre-line">{{ session.notes }}</p>
            </div>
          </div>
          <div class="flex gap-4">
            <Button 
              @click="startSession" 
              :disabled="exercises.length === 0"
              :class="[
                exercises.length === 0 
                  ? 'bg-gray-400 cursor-not-allowed' 
                  : '',
                'text-white px-4 py-2 rounded-lg transition-colors'
              ]"
            >
              {{ exercises.length === 0 ? 'Ajoutez des exercices pour démarrer' : 'Démarrer la séance' }}
            </Button>
            <Button 
              @click="editSession" 
              variant="outline"
            >
              Modifier
            </Button>
          </div>
        </div>

      

        <div class="w-full">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Exercices</h2>

          <Table>
          
            <TableHeader>
              <TableRow>
                <TableHead class="w-[50%]">
                  Exercice
                </TableHead>
                <TableHead class="w-[30%]">Muscle principal</TableHead>
                <TableHead class="w-[20%] text-right">RM</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <TableRow v-if="exercises.length === 0">
                <TableCell colspan="3" class="text-center py-8 text-gray-500 dark:text-gray-400">
                  Aucun exercice pour cette séance
                </TableCell>
              </TableRow>
              <TableRow v-for="exercise in exercises" :key="exercise.id">
                <TableCell class="font-medium">
                  <NuxtLink 
                    :to="`/exercices/${exercise.exercise_id}`"
                    class="text-primary hover:text-primary/80 transition-colors"
                  >
                    {{ exercise.exercise?.name }}
                  </NuxtLink>
                </TableCell>
                <TableCell>{{ exercise.exercise?.primary_muscle }}</TableCell>
                <TableCell class="text-right">
                  <RMCalculator :exercise-id="exercise.exercise_id" />
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
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
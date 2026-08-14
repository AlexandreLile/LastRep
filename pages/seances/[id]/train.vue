<template>
  <div class="relative">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8 bg-card rounded-xl p-6">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4 text-red-500" />
      {{ error }}
    </div>

    <div v-else-if="session">
      <!-- Header amélioré -->
      <div class="mb-8 bg-card rounded-xl p-6">
        <div class="flex flex-col sm:flex-row gap-6">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
              <Dumbbell class="h-6 w-6 text-primary" />
            </div>
            <div>
              <h2 class="text-2xl font-bold text-foreground">{{ session.title }}</h2>
              <div v-if="session.notes" class="mt-2 text-sm text-muted-foreground">
                {{ session.notes }}
              </div>
            </div>
          </div>
          <div class="flex flex-wrap gap-4 sm:ml-auto self-end">
            <Button 
              @click="startSession" 
              :disabled="exercises.length === 0"
              class="relative overflow-hidden group"
              :class="[
                exercises.length === 0 
                  ? 'bg-muted cursor-not-allowed' 
                  : 'bg-primary hover:bg-primary/90',
                'text-white px-6 py-3 rounded-lg transition-all duration-300'
              ]"
            >
              <span class="relative z-10 flex items-center">
                <Play class="mr-2 h-4 w-4" />
                {{ exercises.length === 0 ? 'Ajoutez des exercices pour démarrer' : 'Démarrer la séance' }}
              </span>
              <div class="absolute inset-0 bg-gradient-to-r from-primary-light to-primary opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            </Button>
            <Button 
              @click="editSession" 
              variant="outline"
              class="px-6 py-3 text-foreground hover:text-primary hover:bg-primary/10 border-border transition-colors duration-300 flex items-center font-medium"
            >
              <Pencil class="mr-2 h-4 w-4" />
              Modifier
            </Button>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="space-y-6">
        <!-- Exercises List -->
        <div class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <ListChecks class="w-5 h-5 text-primary" />
            </div>
            <div>
              <h3 class="text-lg font-semibold">Exercices</h3>
              <p class="text-sm text-muted-foreground">Liste des exercices de la séance</p>
            </div>
          </div>

          <div v-if="exercises.length === 0" class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-muted/70 rounded-lg">
            <FolderPlus class="w-16 h-16 text-muted-foreground/30" />
            <p class="text-base text-muted-foreground text-center">
              Aucun exercice pour cette séance
            </p>
            <Button 
              @click="editSession" 
              variant="outline"
              class="mt-2"
            >
              Ajouter des exercices
            </Button>
          </div>

          <div v-else class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
            <button
              v-for="exercise in exercises"
              :key="exercise.id"
              type="button"
              class="group relative flex flex-col text-left rounded-xl overflow-hidden border bg-background transition-all duration-150 hover:border-primary/40 active:scale-[0.98]"
              @click="router.push(`/exercices/${exercise.exercise_id}`)"
            >
              <!-- Image / fallback -->
              <div class="relative aspect-square w-full bg-gradient-to-br from-primary/15 to-muted overflow-hidden">
                <img
                  v-if="exercise.exercise?.image_url"
                  :src="exercise.exercise.image_url"
                  :alt="exercise.exercise?.name"
                  class="h-full w-full object-cover"
                  loading="lazy"
                />
                <div v-else class="h-full w-full flex items-center justify-center">
                  <Dumbbell class="h-8 w-8 text-primary/40" />
                </div>
              </div>

              <!-- Nom + muscle principal -->
              <div class="p-2.5 flex-1 flex flex-col gap-1">
                <p class="font-medium text-sm text-foreground leading-snug line-clamp-2 transition-colors duration-300 group-hover:text-primary">{{ exercise.exercise?.name }}</p>
                <span
                  v-if="exercise.exercise?.primary_muscle"
                  class="text-[11px] px-1.5 py-0.5 rounded-full bg-primary/10 text-primary self-start"
                >
                  {{ exercise.exercise?.primary_muscle }}
                </span>
              </div>
            </button>
          </div>
        </div>

        <!-- Stats -->
        <div class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <BarChart class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold">Progression du volume</h3>
          </div>
          <SessionWeightChart :workout-session-id="route.params.id" />
        </div>

        <!-- Répartition des muscles -->
        <div class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <PieChart class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold">Répartition des muscles</h3>
          </div>
          <MuscleDistributionChart :workout-session-id="route.params.id" />
        </div>
        
        <!-- Section de motivation -->
        <div v-if="exercises.length > 0" class="bg-primary rounded-xl p-6 text-white hover:shadow-lg transition-all duration-300">
          <div class="flex flex-col items-center text-center py-4">
            <h3 class="text-xl md:text-2xl font-bold mb-2">Prêt à vous dépasser ?</h3>
            <p class="text-white/90 max-w-2xl mx-auto mb-4">Commencez votre séance maintenant et suivez vos performances en temps réel.</p>
            <div class="text-4xl mb-4">💪</div>
            <Button 
              @click="startSession" 
              variant="outline"
              class="bg-card text-primary hover:bg-card/90 border-white"
            >
              <Play class="mr-2 h-4 w-4" />
              Démarrer la séance
            </Button>
          </div>
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
import { getOfflineUser, getCachedUser } from '~/utils/offlineTraining'
import SessionWeightChart from '@/components/charts/SessionWeightChart.vue'
import MuscleDistributionChart from '@/components/charts/MuscleDistributionChart.vue'
import { 
  Dumbbell,
  Play,
  Pencil,
  ListChecks,
  BarChart,
  PieChart,
  FolderPlus,
  AlertTriangle
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient()
const { getWorkoutSession } = useWorkoutSessions(useSupabaseUser())
const { workoutExercises: exercises, getWorkoutExercises } = useWorkoutExercise()
const { prepareSession, error: performedSessionError, setupOfflineSync } = usePerformedSession(supabase)

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
    const user = await getOfflineUser(supabase)
    const slotId = route.query.slot || null

    if (!user) {
      const cachedUser = getCachedUser()
      if (cachedUser) {
        prepareSession(route.params.id, cachedUser.id, slotId)
        router.push(`/seances/${route.params.id}/start${slotId ? `?slot=${slotId}&cycle=${route.query.cycle || ''}` : ''}`)
        return
      }
      throw new Error('Impossible de démarrer la séance sans connexion utilisateur')
    }

    prepareSession(route.params.id, user.id, slotId)
    router.push(`/seances/${route.params.id}/start${slotId ? `?slot=${slotId}&cycle=${route.query.cycle || ''}` : ''}`)
  } catch (e) {
    error.value = e.message || performedSessionError.value
  }
}

onMounted(() => {
  setupOfflineSync()
  loadSession()
})
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
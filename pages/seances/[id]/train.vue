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
      <!-- Hero -->
      <div class="mb-8 relative overflow-hidden rounded-2xl border border-primary/15 bg-card">
        <div class="hero-glow absolute inset-0" aria-hidden="true"></div>

        <div class="relative z-10 p-6 sm:p-8">
          <div class="flex items-start gap-4">
            <div class="w-14 h-14 flex-shrink-0 bg-primary/15 rounded-full flex items-center justify-center ring-1 ring-primary/30">
              <Dumbbell class="h-7 w-7 text-primary" />
            </div>
            <div class="min-w-0">
              <h2 class="text-2xl sm:text-3xl font-bold text-foreground">{{ session.title }}</h2>
              <div v-if="session.notes" class="mt-1 text-sm text-muted-foreground">
                {{ session.notes }}
              </div>
            </div>
          </div>

          <!-- Badges motivation -->
          <div v-if="!motivation.loading" class="mt-4 flex flex-wrap gap-2">
            <div
              v-if="motivation.lastSessionPrCount > 0"
              class="inline-flex items-center gap-1.5 rounded-full border border-record/30 bg-record/10 px-3 py-1.5 text-xs font-medium text-record"
            >
              <Trophy class="h-3.5 w-3.5 flex-shrink-0" />
              🏆 {{ motivation.lastSessionPrCount }} record{{ motivation.lastSessionPrCount > 1 ? 's' : '' }} battu{{ motivation.lastSessionPrCount > 1 ? 's' : '' }}
            </div>
            <div
              v-if="motivation.recordsInPlay > 0"
              class="inline-flex items-center gap-1.5 rounded-full border border-record/30 bg-record/10 px-3 py-1.5 text-xs font-medium text-record"
            >
              <Trophy class="h-3.5 w-3.5 flex-shrink-0" />
              {{ motivation.recordsInPlay }} record{{ motivation.recordsInPlay > 1 ? 's' : '' }} personnel{{ motivation.recordsInPlay > 1 ? 's' : '' }} en jeu
            </div>
            <div
              v-if="motivation.isFirstTime"
              class="inline-flex items-center gap-1.5 rounded-full border border-primary/30 bg-primary/10 px-3 py-1.5 text-xs font-medium text-primary"
            >
              <Sparkles class="h-3.5 w-3.5 flex-shrink-0" />
              Première fois sur cette séance — pose ta première référence
            </div>
          </div>

          <div class="mt-6 flex flex-wrap gap-3">
            <div class="relative inline-block">
              <div v-if="exercises.length > 0" class="cta-glow absolute -inset-2 rounded-xl bg-primary" aria-hidden="true"></div>
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
            </div>
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
              v-for="(exercise, index) in exercises"
              :key="exercise.id"
              type="button"
              :style="{ animationDelay: `${index * 40}ms` }"
              class="exercise-card group relative flex flex-col text-left rounded-xl overflow-hidden border bg-background transition-all duration-150 hover:border-primary/40 active:scale-[0.98]"
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
import { loadSessionMotivation } from '~/composables/useSessionMotivation'
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
  AlertTriangle,
  Trophy,
  Sparkles
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

const motivation = ref({
  loading: true,
  isFirstTime: false,
  lastSessionPrCount: 0,
  recordsInPlay: 0
})

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// Charge les données motivationnelles (dernière fois + records en jeu).
// Best-effort : ne bloque jamais l'affichage de la séance si ça échoue.
const loadMotivationData = async () => {
  const normalizedExercises = exercises.value.map((ex) => ({
    exercise_id: ex.exercise_id,
    measurement_type: ex.exercise?.measurement_type
  }))
  const result = await loadSessionMotivation(supabase, {
    sessionId: route.params.id,
    exercises: normalizedExercises
  })
  motivation.value = { loading: false, ...result }
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
  loadMotivationData()
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
.hero-glow {
  overflow: hidden;
  pointer-events: none;
}

.hero-glow::before,
.hero-glow::after {
  content: '';
  position: absolute;
  border-radius: 9999px;
  filter: blur(70px);
}

.hero-glow::before {
  width: 280px;
  height: 280px;
  top: -110px;
  left: -60px;
  background: var(--primary);
  opacity: 0.25;
}

.hero-glow::after {
  width: 240px;
  height: 240px;
  bottom: -100px;
  right: -50px;
  background: var(--record);
  opacity: 0.18;
}

.cta-glow {
  filter: blur(16px);
  animation: glow 2.4s ease-in-out infinite;
}

.exercise-card {
  animation: fadeInUp 0.4s ease both;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes glow {
  0%, 100% {
    opacity: 0.2;
    transform: scale(1);
  }
  50% {
    opacity: 0.45;
    transform: scale(1.05);
  }
}

@media (prefers-reduced-motion: reduce) {
  .cta-glow,
  .exercise-card {
    animation: none;
  }
}
</style>

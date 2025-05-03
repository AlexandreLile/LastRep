<template>
  <div>
    <div v-if="showCelebration" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div class="relative bg-white rounded-xl p-8 max-w-md w-full mx-4 text-center">
        <div class="absolute inset-0 rounded-xl bg-primary/20 blur-md"></div>
        <div class="absolute inset-0 rounded-xl bg-gradient-to-r from-primary/50 via-primary/30 to-primary/50 animate-[pulse_2s_ease-in-out_infinite]"></div>
        <div class="relative">
          <div class="text-4xl mb-4">🎉</div>
          <h3 class="text-2xl font-bold text-gray-900 mb-2">Félicitations !</h3>
          <p class="text-muted-foreground mb-6">Vous avez terminé votre séance avec succès !</p>
          <Button @click="showCelebration = false" class="w-full">
            Continuer
          </Button>
        </div>
      </div>
    </div>

    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="session" class="space-y-8">
      <!-- En-tête -->
      <div class="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="text-2xl font-semibold text-gray-900">{{ session.title }}</h2>
          <div v-if="currentSession" class="mt-2">
            <span class="text-sm text-muted-foreground">
              Début : {{ formatDate(currentSession.started_at) }}
            </span>
          </div>
        </div>
        <div class="flex gap-4">
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button 
                variant="outline"
              >
                Annuler
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Etes vous sûr de vouloir annuler cette séance ?</AlertDialogTitle>
                <AlertDialogDescription>
                  Toutes les données non enregistrées seront perdues.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Non, continuer</AlertDialogCancel>
                <AlertDialogAction @click="handleCancelSession">Oui, annuler</AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button 
                variant="destructive"
              >
                Terminer la séance
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Etes vous sûr de vouloir terminer cette séance ?</AlertDialogTitle>
                <AlertDialogDescription>
                  La séance sera enregistrée et vous ne pourrez plus y ajouter de données.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Non, continuer</AlertDialogCancel>
                <AlertDialogAction @click="handleEndSession">Oui, terminer</AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </div>
      </div>

      <!-- Liste des exercices -->
      <div class="bg-white rounded-xl p-8">
        <div class="space-y-6">
          <div>
            <h3 class="text-lg font-medium">Exercices</h3>
            <p class="text-sm text-muted-foreground">Sélectionnez un exercice pour commencer</p>
          </div>

          <div v-if="exercises.length > 0" class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div 
              v-for="exercise in exercises" 
              :key="exercise.id" 
              class="relative bg-white rounded-xl p-4 cursor-pointer group overflow-hidden transition-all duration-300 hover:scale-[1.02]"
              @click="goToExercise(exercise.id)"
            >
              <!-- Effet de bordure néon -->
              <div class="absolute inset-0 rounded-xl bg-primary/20 blur-md transition-all duration-300 group-hover:bg-primary/30 group-hover:blur-lg"></div>
              <div class="absolute inset-0 rounded-xl bg-gradient-to-r from-primary/50 via-primary/30 to-primary/50 animate-[pulse_2s_ease-in-out_infinite] group-hover:from-primary/60 group-hover:via-primary/40 group-hover:to-primary/60"></div>
              <div class="absolute inset-0 rounded-xl bg-gradient-to-br from-primary/40 to-transparent animate-[glow_3s_ease-in-out_infinite] group-hover:from-primary/50 group-hover:to-transparent"></div>
              <div class="absolute inset-[1px] rounded-xl bg-white"></div>

              <div class="relative flex items-center gap-3">
                <div class="p-2 rounded-full bg-primary/20 transition-all duration-300 group-hover:bg-primary/30 group-hover:scale-110">
                  <Dumbbell class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12" />
                </div>
                <div>
                  <h4 class="text-base font-medium text-gray-900 transition-colors duration-300 group-hover:text-primary">{{ exercise.exercise?.name }}</h4>
                  <span class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full transition-all duration-300 group-hover:bg-primary/10 group-hover:text-primary">
                    {{ exercise.exercise?.primary_muscle }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-8 text-muted-foreground">
            Aucun exercice pour cette séance
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useWorkoutSessions } from '~/composables/useWorkoutSession'
import { useWorkoutExercise } from '~/composables/useWorkoutExercise'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { Button } from '@/components/ui/button'
import { Dumbbell } from 'lucide-vue-next'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog'

definePageMeta({
  layout: 'start-session'
})

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
const showCelebration = ref(false)

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
    const sessionData = await saveSession()
    
    if (sessionData) {
      // La mise à jour des exerciseSet est maintenant gérée dans saveSession
      showCelebration.value = true
      setTimeout(() => {
        router.push(`/seances/${route.params.id}/train`)
      }, 3000)
    }
  } catch (e) {
    error.value = e.message || performedSessionError.value
  }
}

const handleCancelSession = async () => {
  try {
    const currentSession = getCurrentSession()
    if (currentSession) {
      // Supprimer toutes les séries de la session
      const { error: deleteError } = await supabase
        .from('exerciseset')
        .delete()
        .gte('created_at', currentSession.started_at)
        .lte('created_at', currentSession.ended_at || new Date().toISOString())

      if (deleteError) throw deleteError
    }
    
    // Supprimer la session du localStorage
    if (process.client) {
      localStorage.removeItem('currentSession')
    }
    
    // Rediriger vers la page d'entraînement
    router.push(`/seances/${route.params.id}/train`)
  } catch (e) {
    error.value = e.message || 'Erreur lors de l\'annulation de la séance'
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
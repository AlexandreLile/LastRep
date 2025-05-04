<template>
  <div class="relative min-h-screen ">
    <!-- Éléments de fond pour l'ambiance "entraînement" -->
    <div class="absolute inset-0 overflow-hidden pointer-events-none">
     
      <div class="absolute top-1/2 left-1/3 w-6 h-20 bg-primary/20 rounded-full rotate-45 animate-pulse"></div>
      <div class="absolute top-1/3 right-1/3 w-4 h-16 bg-primary/15 rounded-full -rotate-12 animate-pulse"></div>
    </div>
    
    <!-- Élément décoratif - "Training Mode" -->
    <div class="absolute top-0 right-0 bg-primary/90 text-white py-1 px-4 rounded-bl-lg font-bold shadow-lg flex items-center">
      <Timer class="w-4 h-4 mr-2 animate-pulse" />
      <span>MODE ENTRAÎNEMENT</span>
    </div>

    <!-- Padding supplémentaire pour le contenu sous le badge MODE ENTRAINEMENT -->
    <div class="pt-16 sm:pt-0"></div>

    <!-- Animation de célébration -->
    <div v-if="showCelebration" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div class="bg-white rounded-xl p-8 max-w-md w-full mx-4 text-center">
        <div class="confetti-explosion">
          <div v-for="n in 20" :key="n" class="confetti"></div>
        </div>
        <div class="text-5xl mb-4">🏆</div>
        <h3 class="text-2xl font-bold text-gray-900 mb-2">Félicitations !</h3>
        <p class="text-muted-foreground mb-6">Vous avez terminé votre séance avec succès !</p>
        <Button @click="showCelebration = false" class="w-full">
          Continuer
        </Button>
      </div>
    </div>

    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="session" class="space-y-8">
      <!-- En-tête amélioré -->
      <div class="bg-white rounded-xl p-4 sm:p-6">
        <div class="flex flex-col gap-4 sm:gap-6">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between">
            <div class="flex items-start gap-4">
              <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
                <Dumbbell class="h-6 w-6 text-primary" />
              </div>
              <div>
                <h2 class="text-2xl font-bold text-gray-900">{{ session.title }}</h2>
                <div v-if="currentSession" class="flex items-center mt-2">
                  <Calendar class="w-4 h-4 text-muted-foreground mr-1.5" />
                  <span class="text-sm text-muted-foreground">
                    Début : {{ formatDate(currentSession.started_at) }}
                  </span>
                </div>
              </div>
            </div>
            
            <!-- Chronomètre -->
            <div class="flex flex-col items-center bg-gray-50/70 rounded-lg p-3 mt-4 sm:mt-0">
              <div class="text-xs text-muted-foreground mb-1">DURÉE DE LA SÉANCE</div>
              <div class="text-xl font-mono font-semibold tracking-wide">{{ formatElapsedTime }}</div>
            </div>
          </div>
          
          <!-- Boutons d'action -->
          <div class="flex flex-col sm:flex-row gap-2 sm:gap-4 w-full">
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button 
                  variant="outline"
                  class="flex items-center gap-2 w-full sm:w-auto"
                >
                  <X class="w-4 h-4" />
                  Annuler
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Êtes-vous sûr de vouloir annuler cette séance ?</AlertDialogTitle>
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
                  class="flex items-center gap-2 w-full sm:w-auto"
                >
                  <CheckCircle class="w-4 h-4" />
                  Terminer la séance
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Êtes-vous sûr de vouloir terminer cette séance ?</AlertDialogTitle>
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
      </div>

      <!-- Liste des exercices -->
      <div class="bg-white rounded-xl p-6">
        <div class="flex items-center gap-3 mb-6">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <ListChecks class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Exercices</h3>
            <p class="text-sm text-muted-foreground">Sélectionnez un exercice pour commencer</p>
          </div>
        </div>

        <div v-if="exercises.length > 0" class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div 
            v-for="(exercise, index) in exercises" 
            :key="exercise.id" 
            class="bg-white rounded-xl p-4 group transition-all duration-300 hover:scale-[1.02] border border-gray-100 hover:border-primary/20 relative"
            :style="{animationDelay: `${index * 0.1}s`}"
            :class="{'animate-fade-in': true}"
          >
            <!-- Contenu principal -->
            <div class="flex flex-col space-y-3">
              <!-- Partie supérieure: nom et icône principale -->
              <div class="flex items-start gap-3">
                <div class="p-2 rounded-full bg-primary/20 transition-all duration-300 group-hover:bg-primary/30 group-hover:scale-110 relative">
                  <Dumbbell class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12" />
                  <!-- Indicateur visuel de statut -->
                  <div v-if="exercise.completionStatus" class="absolute -top-1 -right-1 w-4 h-4 bg-green-500 rounded-full border-2 border-white"></div>
                </div>
                <div class="flex-grow">
                  <h4 class="text-base font-medium text-gray-900 transition-colors duration-300 group-hover:text-primary">{{ exercise.exercise?.name }}</h4>
                </div>
              </div>
              
              <!-- Partie inférieure: Muscle, statut et actions -->
              <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <span class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full transition-all duration-300 group-hover:bg-primary/10 group-hover:text-primary">
                  {{ exercise.exercise?.primary_muscle }}
                </span>
                
                <div class="flex items-center gap-2 justify-between sm:justify-end">
                  <span 
                    class="text-xs px-2 py-0.5 rounded-full"
                    :class="{
                      'bg-green-50 text-green-600': exercise.completionStatus,
                      'bg-gray-50 text-gray-500': !exercise.completionStatus
                    }"
                  >
                    {{ exercise.completionStatus ? 'Complété' : 'À faire' }}
                  </span>
                  
                  <!-- Actions de contrôle pour l'exercice -->
                  <div class="flex items-center space-x-2">
                    <button 
                      @click.stop="toggleExerciseStatus(exercise.exercise_id)"
                      class="w-8 h-8 rounded-full flex items-center justify-center transition-colors duration-200"
                      :class="{
                        'bg-green-100 hover:bg-green-200': exercise.completionStatus,
                        'bg-gray-100 hover:bg-gray-200': !exercise.completionStatus
                      }"
                    >
                      <Check v-if="exercise.completionStatus" class="w-4 h-4 text-green-600" />
                      <CircleSlash v-else class="w-4 h-4 text-gray-400" />
                    </button>
                    
                    <button 
                      @click.stop="goToExercise(exercise.id)"
                      class="w-8 h-8 bg-primary/10 hover:bg-primary/20 rounded-full flex items-center justify-center transition-colors duration-200"
                    >
                      <ArrowRight class="w-4 h-4 text-primary" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Surface cliquable pour toute la carte -->
            <div 
              class="absolute inset-0 cursor-pointer" 
              @click="goToExercise(exercise.id)"
            ></div>
          </div>
        </div>

        <div v-else class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-gray-50/70 rounded-lg">
          <Dumbbell class="w-16 h-16 text-muted-foreground/30" />
          <p class="text-base text-muted-foreground text-center">
            Aucun exercice pour cette séance
          </p>
        </div>
      </div>

      <!-- Carte progrès de la séance -->
      <div class="bg-white rounded-xl p-6">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <BarChart3 class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Progression</h3>
            <p class="text-sm text-muted-foreground">Suivi de votre séance actuelle</p>
          </div>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="bg-gray-50/70 rounded-xl p-4 flex flex-col items-center">
            <div class="text-sm text-muted-foreground mb-1">Exercices</div>
            <div class="text-3xl font-bold text-primary">{{ exercises.length }}</div>
            <div class="text-xs text-muted-foreground">total</div>
          </div>
          
          <div class="bg-gray-50/70 rounded-xl p-4 flex flex-col items-center">
            <div class="text-sm text-muted-foreground mb-1">Complétés</div>
            <div class="text-3xl font-bold text-primary">{{ completedExercisesCount }}</div>
            <div class="text-xs text-muted-foreground">exercices</div>
          </div>
          
          <div class="bg-gray-50/70 rounded-xl p-4 flex flex-col items-center">
            <div class="text-sm text-muted-foreground mb-1">Séries</div>
            <div class="text-3xl font-bold text-primary">{{ totalSets }}</div>
            <div class="text-xs text-muted-foreground">total</div>
          </div>
        </div>
        
        <div class="mt-4">
          <div class="flex justify-between mb-2">
            <span class="text-sm font-medium">Progression</span>
            <span class="text-sm font-medium">{{ Math.round((completedExercisesCount / Math.max(exercises.length, 1)) * 100) }}%</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2.5">
            <div class="bg-primary h-2.5 rounded-full" :style="{ width: `${Math.round((completedExercisesCount / Math.max(exercises.length, 1)) * 100)}%` }"></div>
          </div>
        </div>
      </div>
      
      <!-- Section de motivation -->
      <div class="bg-primary rounded-xl p-6 text-white">
        <div class="flex flex-col items-center text-center py-4">
          <h3 class="text-xl md:text-2xl font-bold mb-2">Restez motivé !</h3>
          <p class="text-white/90 max-w-2xl mx-auto mb-4">Chaque série vous rapproche de vos objectifs. Continuez à repousser vos limites !</p>
          <div class="text-4xl mb-2">💪</div>
          <p class="text-sm text-white/80 italic">"La douleur que vous ressentirez aujourd'hui sera la force que vous ressentirez demain."</p>
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
import { 
  Dumbbell, 
  Calendar,
  CheckCircle,
  X,
  Check,
  CircleSlash,
  BarChart3,
  Timer,
  ListChecks,
  ArrowRight
} from 'lucide-vue-next'
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
const { workoutExercises: exercisesRaw, getWorkoutExercises } = useWorkoutExercise()
const { performedSession, error: performedSessionError, saveSession, getCurrentSession } = usePerformedSession(supabase)

const session = ref(null)
const currentSession = ref(null)
const loading = ref(true)
const error = ref(null)
const showCelebration = ref(false)
const isLeavingPage = ref(false)
const completedExercisesCount = ref(0)
const totalSets = ref(0)
const elapsedTime = ref(0)
let timer = null

// Tracker les exercices qui ont au moins une série complétée
const exercisesWithSets = ref(new Set())

// Récupérer les exercices avec leur statut de complétion
const exercises = computed(() => {
  return exercisesRaw.value.map(ex => ({
    ...ex,
    completionStatus: exercisesWithSets.value.has(ex.exercise_id)
  }))
})

// Format du temps écoulé
const formatElapsedTime = computed(() => {
  const hours = Math.floor(elapsedTime.value / 3600)
  const minutes = Math.floor((elapsedTime.value % 3600) / 60)
  const seconds = elapsedTime.value % 60
  
  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
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

const startTimer = () => {
  if (currentSession.value && currentSession.value.started_at) {
    const startTime = new Date(currentSession.value.started_at).getTime()
    
    // Calcul initial
    const now = new Date().getTime()
    elapsedTime.value = Math.floor((now - startTime) / 1000)
    
    // Mise à jour du timer
    timer = setInterval(() => {
      elapsedTime.value += 1
    }, 1000)
  }
}

const stopTimer = () => {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
}

const updateSessionStats = async () => {
  try {
    // Requête pour récupérer tous les sets de la session actuelle
    const { data: setsData, error: setsError } = await supabase
      .from('exerciseset')
      .select('exercise_id, id')
      .gte('created_at', currentSession.value.started_at)
      .lte('created_at', new Date().toISOString())
    
    if (setsError) throw setsError
    
    // Mise à jour du nombre total de séries
    totalSets.value = setsData.length
    
    // Mise à jour des exercices complétés
    exercisesWithSets.value = new Set(setsData.map(set => set.exercise_id))
    completedExercisesCount.value = exercisesWithSets.value.size
  } catch (e) {
    console.error('Erreur de récupération des statistiques:', e)
  }
}

const handleEndSession = async () => {
  try {
    const sessionData = await saveSession()
    
    if (sessionData) {
      stopTimer()
      showCelebration.value = true
      setTimeout(() => {
        isLeavingPage.value = true
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
    
    stopTimer()
    
    // Rediriger vers la page d'entraînement
    isLeavingPage.value = true
    router.push(`/seances/${route.params.id}/train`)
  } catch (e) {
    error.value = e.message || 'Erreur lors de l\'annulation de la séance'
  }
}

const goToExercise = (exerciseId) => {
  isLeavingPage.value = true
  router.push(`/seances/${route.params.id}/exercises/${exerciseId}`)
}

// Permettre de marquer manuellement un exercice comme complété/à faire
const toggleExerciseStatus = async (exerciseId) => {
  try {
    if (exercisesWithSets.value.has(exerciseId)) {
      // Déjà complété - Retirer de la liste des exercices complétés
      exercisesWithSets.value.delete(exerciseId)
    } else {
      // Pas encore complété - Ajouter à la liste des exercices complétés
      exercisesWithSets.value.add(exerciseId)
    }
    
    // Mettre à jour le compteur d'exercices complétés
    completedExercisesCount.value = exercisesWithSets.value.size
    
    // Si l'utilisateur marque un exercice comme complété sans avoir de séries,
    // créer une série factice pour indiquer que l'exercice est complété
    // (ou supprimer les séries existantes si on le marque comme "à faire")
    if (exercisesWithSets.value.has(exerciseId)) {
      // Vérifier si l'exercice a déjà des séries
      const { data: existingSets, error: checkError } = await supabase
        .from('exerciseset')
        .select('id')
        .eq('exercise_id', exerciseId)
        .gte('created_at', currentSession.value.started_at)
        .lte('created_at', new Date().toISOString())
        .limit(1)
      
      if (checkError) throw checkError
        
      // Si pas de séries existantes, créer une série factice
      if (existingSets.length === 0) {
        const { error: insertError } = await supabase
          .from('exerciseset')
          .insert({
            exercise_id: exerciseId,
            weight_kg: 0,
            reps: 0,
            rest_seconds: 0,
            user_id: (await supabase.auth.getUser()).data.user.id,
            created_at: new Date().toISOString(),
            manually_marked: true // Indiquer que c'est manuellement marqué
          })
          
        if (insertError) throw insertError
      }
    } else {
      // Supprimer toutes les séries marquées manuellement pour cet exercice
      const { error: deleteError } = await supabase
        .from('exerciseset')
        .delete()
        .eq('exercise_id', exerciseId)
        .eq('manually_marked', true)
        .gte('created_at', currentSession.value.started_at)
        .lte('created_at', new Date().toISOString())
        
      if (deleteError) throw deleteError
      
      // Revérifier s'il reste des séries non-marquées manuellement
      const { data: remainingSets, error: checkError } = await supabase
        .from('exerciseset')
        .select('id')
        .eq('exercise_id', exerciseId)
        .gte('created_at', currentSession.value.started_at)
        .lte('created_at', new Date().toISOString())
        .limit(1)
        
      if (checkError) throw checkError
      
      // S'il reste des séries non-marquées, remettre l'exercice dans la liste des complétés
      if (remainingSets.length > 0) {
        exercisesWithSets.value.add(exerciseId)
        completedExercisesCount.value = exercisesWithSets.value.size
      }
    }
    
    // Mettre à jour les statistiques de la session
    await updateSessionStats()
  } catch (e) {
    console.error('Erreur lors du changement de statut de l\'exercice:', e)
  }
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
      isLeavingPage.value = true
      router.push(`/seances/${route.params.id}/train`)
      return
    }
    
    // Charger les stats de la session
    await updateSessionStats()
    
    // Démarrer le timer
    startTimer()
    
    // Actualiser les statistiques périodiquement
    setInterval(updateSessionStats, 30000) // Toutes les 30 secondes
  } catch (e) {
    error.value = e.message || performedSessionError.value
  } finally {
    loading.value = false
  }
}

// Fonction pour empêcher la navigation sans confirmation
const beforeUnloadHandler = (e) => {
  if (currentSession.value && !isLeavingPage.value) {
    const message = 'Vous avez une séance en cours. Êtes-vous sûr de vouloir quitter cette page ? Toutes les données non enregistrées seront perdues.'
    e.returnValue = message
    return message
  }
}

// Intercepteur de navigation pour les routes Vue
const routeLeaveGuard = (to, from, next) => {
  // Autoriser les navigations vers les exercices de la même séance
  if (to.path.includes(`/seances/${route.params.id}/exercises/`)) {
    isLeavingPage.value = true
    next()
    return
  }
  
  // Demander confirmation uniquement si on quitte la séance en cours
  if (currentSession.value && !isLeavingPage.value) {
    if (window.confirm('Vous avez une séance en cours. Êtes-vous sûr de vouloir quitter cette page ? Toutes les données non enregistrées seront perdues.')) {
      isLeavingPage.value = true
      next()
    } else {
      next(false)
    }
  } else {
    next()
  }
}

onMounted(() => {
  loadSession()
  
  // Ajouter l'écouteur d'événement pour la fermeture du navigateur/onglet
  if (process.client) {
    window.addEventListener('beforeunload', beforeUnloadHandler)
    
    // Configurer le garde de route
    const unbindRoute = router.beforeEach(routeLeaveGuard)
    
    // Stocker la fonction pour désactiver l'écouteur
    onBeforeUnmount(() => {
      window.removeEventListener('beforeunload', beforeUnloadHandler)
      // Supprimer le garde de route
      unbindRoute()
      // Arrêter le timer
      stopTimer()
    })
  }
})
</script>

<style scoped>


.animate-fade-in {
  animation: fadeIn 0.5s ease-out forwards;
  opacity: 0;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}



/* Animation de confetti */
.confetti-explosion {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  z-index: 1;
}

.confetti {
  position: absolute;
  width: 8px;
  height: 16px;
  background-color: var(--primary);
  opacity: 0;
  animation: confetti-fall 3s ease-in-out forwards;
}

.confetti:nth-child(even) {
  background-color: #ffcc00;
}

.confetti:nth-child(3n) {
  background-color: #ff6b6b;
}

.confetti:nth-child(4n) {
  background-color: #4ecdc4;
}

@keyframes confetti-fall {
  0% {
    opacity: 1;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    opacity: 0;
    top: -20%;
    left: var(--random-x, 50%);
    transform: translate(-50%, 0) rotate(var(--random-rotate, 180deg));
  }
}
</style> 
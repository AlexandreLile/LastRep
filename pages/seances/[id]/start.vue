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

    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="session" class="space-y-8">
      <!-- En-tête amélioré -->
      <div class="bg-card rounded-xl p-4 sm:p-6">
        <div class="flex flex-col gap-4 sm:gap-6">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between">
            <div class="flex items-start gap-4">
              <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
                <Dumbbell class="h-6 w-6 text-primary" />
              </div>
              <div>
                <h2 class="text-2xl font-bold text-foreground">{{ session.title }}</h2>
                <div v-if="currentSession" class="flex items-center mt-2">
                  <Calendar class="w-4 h-4 text-muted-foreground mr-1.5" />
                  <span class="text-sm text-muted-foreground">
                    Début : {{ formatDate(currentSession.started_at) }}
                  </span>
                </div>
              </div>
            </div>
            
            <!-- Chronomètre -->
            <div class="flex flex-col items-center bg-muted/70 rounded-lg p-3 mt-4 sm:mt-0">
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
                  variant="default"
                  class="flex items-center gap-2 w-full sm:w-auto bg-primary hover:bg-primary/90"
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
      <div class="bg-card rounded-xl p-6">
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
            class="bg-card rounded-xl p-4 group transition-all duration-300 hover:scale-[1.02] border border-border100 hover:border-primary/20 relative"
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
                  <h4 class="text-base font-medium text-foreground transition-colors duration-300 group-hover:text-primary">{{ exercise.exercise?.name }}</h4>
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
                      'bg-muted text-muted-foreground': !exercise.completionStatus
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
                        'bg-muted hover:bg-muted/80': !exercise.completionStatus
                      }"
                    >
                      <Check v-if="exercise.completionStatus" class="w-4 h-4 text-green-600" />
                      <CircleSlash v-else class="w-4 h-4 text-muted-foreground" />
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

        <div v-else class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-muted/70 rounded-lg">
          <Dumbbell class="w-16 h-16 text-muted-foreground/30" />
          <p class="text-base text-muted-foreground text-center">
            Aucun exercice pour cette séance
          </p>
        </div>
      </div>

      <!-- Carte progrès de la séance -->
      <div class="bg-card rounded-xl p-6">
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
          <div class="bg-muted/70 rounded-xl p-4 flex flex-col items-center">
            <div class="text-sm text-muted-foreground mb-1">Exercices</div>
            <div class="text-3xl font-bold text-primary">{{ exercises.length }}</div>
            <div class="text-xs text-muted-foreground">total</div>
          </div>
          
          <div class="bg-muted/70 rounded-xl p-4 flex flex-col items-center">
            <div class="text-sm text-muted-foreground mb-1">Complétés</div>
            <div class="text-3xl font-bold text-primary">{{ completedExercisesCount }}</div>
            <div class="text-xs text-muted-foreground">exercices</div>
          </div>
          
          <div class="bg-muted/70 rounded-xl p-4 flex flex-col items-center">
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
          <div class="w-full bg-muted rounded-full h-2.5">
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
import { 
  addSessionSet, 
  cachePersonalBest, 
  clearSessionSets, 
  getSessionSets, 
  saveSessionSets, 
  getOfflineUser 
} from '~/utils/offlineTraining'
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
const { performedSession, error: performedSessionError, saveSession, getCurrentSession, setupOfflineSync } = usePerformedSession(supabase)

const session = ref(null)
const currentSession = ref(null)
const loading = ref(true)
const error = ref(null)
const isLeavingPage = ref(false)
const completedExercisesCount = ref(0)
const totalSets = ref(0)
const elapsedTime = ref(0)
const isSavingSession = ref(false)
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

const computeBestSet = (sets, measurementType) => {
  if (!sets.length) return null
  const normalizedType = measurementType || 'weight_reps'

  if (normalizedType === 'time') {
    const bestTimeSet = sets.reduce((best, candidate) => {
      if (!best) return candidate
      return (candidate.duration_seconds || 0) > (best.duration_seconds || 0) ? candidate : best
    }, null)

    const setsByDate = {}
    sets.forEach((set) => {
      const date = new Date(set.created_at).toLocaleDateString('fr-FR')
      setsByDate[date] = (setsByDate[date] || 0) + 1
    })

    const maxSetsInSession = Math.max(...Object.values(setsByDate))
    const dateWithMaxSets = Object.keys(setsByDate).find(
      (date) => setsByDate[date] === maxSetsInSession
    )

    return {
      ...bestTimeSet,
      maxTime: bestTimeSet.duration_seconds || 0,
      maxSetsInSession,
      dateWithMaxSets,
      isTimeExercise: true
    }
  }

  if (normalizedType === 'reps') {
    const bestRepsSet = sets.reduce((best, candidate) => {
      if (!best) return candidate
      return (candidate.reps || 0) > (best.reps || 0) ? candidate : best
    }, null)

    const repsByDate = {}
    sets.forEach((set) => {
      const date = new Date(set.created_at).toLocaleDateString('fr-FR')
      repsByDate[date] = (repsByDate[date] || 0) + (set.reps || 0)
    })

    const maxTotalRepsInSession = Math.max(...Object.values(repsByDate))
    const dateWithMaxReps = Object.keys(repsByDate).find(
      (date) => repsByDate[date] === maxTotalRepsInSession
    )

    return {
      ...bestRepsSet,
      maxReps: bestRepsSet.reps || 0,
      maxTotalRepsInSession,
      dateWithMaxReps,
      isRepsExercise: true
    }
  }

  if (normalizedType === 'weight_only') {
    return sets.reduce((best, candidate) => {
      if (!best) return candidate
      return (candidate.weight_kg || 0) > (best.weight_kg || 0) ? candidate : best
    }, null)
  }

  return sets.reduce((best, candidate) => {
    if (!best) return candidate
    if ((candidate.weight_kg || 0) > (best.weight_kg || 0)) return candidate
    if ((candidate.weight_kg || 0) === (best.weight_kg || 0) && (candidate.reps || 0) > (best.reps || 0)) {
      return candidate
    }
    return best
  }, null)
}

const preloadPersonalBests = async () => {
  try {
    // Ne pas bloquer si offline - les caches existants seront utilisés
    if (!navigator.onLine) return
    
    const exerciseList = exercisesRaw.value || []
    const exerciseIds = exerciseList.map(ex => ex.exercise_id).filter(Boolean)
    if (!exerciseIds.length) return

    const user = await getOfflineUser(supabase)
    if (!user) return

    const { data: setsData, error: setsError } = await supabase
      .from('exerciseset')
      .select('id, exercise_id, weight_kg, reps, duration_seconds, distance_meters, created_at')
      .eq('user_id', user.id)
      .in('exercise_id', exerciseIds)

    if (setsError) return // Silencieux si erreur

    const setsByExercise = new Map()
    ;(setsData || []).forEach((set) => {
      if (!setsByExercise.has(set.exercise_id)) {
        setsByExercise.set(set.exercise_id, [])
      }
      setsByExercise.get(set.exercise_id).push(set)
    })

    exerciseList.forEach((exercise) => {
      const sets = setsByExercise.get(exercise.exercise_id) || []
      if (!sets.length) return
      const measurementType = exercise.exercise?.measurement_type || 'weight_reps'
      const bestSet = computeBestSet(sets, measurementType)
      if (bestSet) {
        cachePersonalBest(exercise.exercise_id, bestSet)
      }
    })
  } catch (e) {
    // Silencieux - les records seront chargés plus tard si besoin
  }
}

// Stats calculées depuis localStorage uniquement (pattern local-first)
const updateSessionStats = () => {
  if (!currentSession.value) return
  
  const localSets = getSessionSets(currentSession.value.workout_session_id)
  totalSets.value = localSets.length
  exercisesWithSets.value = new Set(localSets.map(set => set.exercise_id))
  completedExercisesCount.value = exercisesWithSets.value.size
}

const handleEndSession = async () => {
  try {
    if (isSavingSession.value) return
    isSavingSession.value = true
    
    const result = await saveSession()
    
    if (result) {
      // Nettoyage géré par saveSession() sauf pour le mode offline
      // où les sets doivent rester pour la sync ultérieure
      stopTimer()
      isLeavingPage.value = true
      router.push({ path: '/', query: { celebrate: '1' } })
    }
  } catch (e) {
    error.value = e.message || performedSessionError.value
  } finally {
    isSavingSession.value = false
  }
}

// Annuler la session (local-first: rien n'a été envoyé en DB, juste nettoyer localStorage)
const handleCancelSession = () => {
  const session = getCurrentSession()
  if (session) {
    // Nettoyer les sets locaux
    clearSessionSets(session.workout_session_id)
  }
  
  // Supprimer la session du localStorage
  if (process.client) {
    localStorage.removeItem('currentSession')
  }
  
  stopTimer()
  
  // Rediriger vers la page d'entraînement
  isLeavingPage.value = true
  router.push(`/seances/${route.params.id}/train`)
}

const goToExercise = (exerciseId) => {
  isLeavingPage.value = true
  router.push(`/seances/${route.params.id}/exercises/${exerciseId}`)
}

// Permettre de marquer manuellement un exercice comme complété/à faire (local-first)
const toggleExerciseStatus = (exerciseId) => {
  const sessionId = currentSession.value?.workout_session_id
  if (!sessionId) return
  
  if (exercisesWithSets.value.has(exerciseId)) {
    // Déjà complété - Retirer
    exercisesWithSets.value.delete(exerciseId)
    
    // Supprimer les sets marqués manuellement pour cet exercice
    const offlineSets = getSessionSets(sessionId)
    const updated = offlineSets.filter(
      (set) => !(set.exercise_id === exerciseId && set.manually_marked)
    )
    saveSessionSets(sessionId, updated)
  } else {
    // Pas encore complété - Ajouter
    exercisesWithSets.value.add(exerciseId)
    
    // Créer une série factice si pas de vraie série
    const offlineSets = getSessionSets(sessionId)
    const hasRealSet = offlineSets.some(
      (set) => set.exercise_id === exerciseId && !set.manually_marked
    )
    if (!hasRealSet) {
      const manualSet = {
        id: `local-${Date.now()}-${Math.random().toString(16).slice(2)}`,
        exercise_id: exerciseId,
        weight_kg: 0,
        reps: 0,
        rest_seconds: 0,
        manually_marked: true,
        created_at: new Date().toISOString(),
        user_id: currentSession.value.user_id
      }
      addSessionSet(sessionId, manualSet)
    }
  }
  
  // Mettre à jour le compteur
  completedExercisesCount.value = exercisesWithSets.value.size
  updateSessionStats()
}

let statsInterval = null
let unbindRoute = null

const loadSession = async () => {
  try {
    loading.value = true
    const { data, error: sessionError } = await getWorkoutSession(route.params.id)
    if (sessionError) throw sessionError
    session.value = data
    await getWorkoutExercises(route.params.id)
    await preloadPersonalBests()
    
    // Vérifier si une session est en cours
    currentSession.value = getCurrentSession()
    if (!currentSession.value) {
      isLeavingPage.value = true
      router.push(`/seances/${route.params.id}/train`)
      return
    }
    
    // Charger les stats de la session
    updateSessionStats()
    
    // Démarrer le timer
    startTimer()
    
    // Actualiser les statistiques périodiquement (avec nettoyage)
    statsInterval = setInterval(updateSessionStats, 10000) // Toutes les 10 secondes
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
  setupOfflineSync()
  loadSession()
  
  // Ajouter l'écouteur d'événement pour la fermeture du navigateur/onglet
  if (process.client) {
    window.addEventListener('beforeunload', beforeUnloadHandler)
    
    // Configurer le garde de route
    unbindRoute = router.beforeEach(routeLeaveGuard)
  }
})

// Nettoyage au démontage (doit être au niveau racine du setup)
onBeforeUnmount(() => {
  if (process.client) {
    window.removeEventListener('beforeunload', beforeUnloadHandler)
  }
  // Supprimer le garde de route
  if (unbindRoute) {
    unbindRoute()
  }
  // Arrêter le timer
  stopTimer()
  // Arrêter le refresh des stats
  if (statsInterval) {
    clearInterval(statsInterval)
    statsInterval = null
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
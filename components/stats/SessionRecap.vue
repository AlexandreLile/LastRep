<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-12">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4 text-red-500" />
      <p class="text-sm font-medium">{{ error }}</p>
    </div>

    <div v-else-if="!sessionData" class="flex flex-col items-center justify-center py-16 px-4 space-y-4 bg-gradient-to-br from-muted/30 to-muted/50 rounded-xl">
      <Trophy class="w-16 h-16 text-muted-foreground/40" />
      <p class="text-sm text-muted-foreground text-center font-medium">
        Aucune séance récente trouvée
      </p>
    </div>

    <div v-else class="space-y-6">
      <!-- Header avec titre de la séance -->
      <div class="space-y-3">
        <div class="flex items-center justify-between">
          <h3 class="text-xl font-bold text-foreground">{{ sessionData.sessionTitle }}</h3>
          <div class="flex items-center gap-2 text-sm text-muted-foreground">
            <Calendar class="w-4 h-4" />
            <span>{{ formatDate(sessionData.endedAt) }}</span>
          </div>
        </div>
        <div class="flex items-center gap-4 text-sm text-muted-foreground">
          <div class="flex items-center gap-1.5">
            <Clock class="w-4 h-4" />
            <span>{{ formatDuration(sessionData.startedAt, sessionData.endedAt) }}</span>
          </div>
          <span>•</span>
          <div class="flex items-center gap-1.5">
            <Dumbbell class="w-4 h-4" />
            <span>{{ sessionData.exerciseCount }} exercice{{ sessionData.exerciseCount > 1 ? 's' : '' }}</span>
          </div>
        </div>
      </div>

      <!-- Statistiques principales -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- PR battus -->
        <div class="bg-gradient-to-br from-yellow-500/10 to-yellow-600/5 rounded-lg p-5 border border-yellow-500/20">
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 rounded-full bg-yellow-500/20 flex items-center justify-center">
              <Trophy class="w-5 h-5 text-yellow-600" />
            </div>
            <div>
              <p class="text-xs text-muted-foreground">Records battus</p>
              <p class="text-2xl font-bold text-yellow-600">{{ prCount }}</p>
            </div>
          </div>
        </div>

        <!-- Volume total (uniquement exercices avec poids) -->
        <div v-if="hasWeightExercises" class="bg-gradient-to-br from-primary/10 to-primary/5 rounded-lg p-5 border border-primary/20">
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
              <Weight class="w-5 h-5 text-primary" />
            </div>
            <div>
              <p class="text-xs text-muted-foreground">Volume total</p>
              <p class="text-2xl font-bold text-primary">{{ formatWeight(totalVolume) }} kg</p>
              <p class="text-[10px] text-muted-foreground mt-0.5">(exercices avec poids uniquement)</p>
            </div>
          </div>
          <div v-if="volumeEvolution !== null" class="mt-2">
            <div :class="[
              'flex items-center gap-1 text-xs font-medium',
              volumeEvolution > 0 ? 'text-green-500' : volumeEvolution < 0 ? 'text-red-500' : 'text-muted-foreground'
            ]">
              <ArrowUp v-if="volumeEvolution > 0" class="w-3 h-3" />
              <ArrowDown v-if="volumeEvolution < 0" class="w-3 h-3" />
              <span>{{ volumeEvolution > 0 ? '+' : '' }}{{ formatWeight(Math.abs(volumeEvolution)) }} kg</span>
              <span class="text-muted-foreground">vs dernière fois</span>
            </div>
          </div>
        </div>
        
        <!-- Total répétitions (exercices au poids du corps) -->
        <div v-if="hasRepsOnlyExercises" class="bg-gradient-to-br from-primary/10 to-primary/5 rounded-lg p-5 border border-primary/20">
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
              <Repeat class="w-5 h-5 text-primary" />
            </div>
            <div>
              <p class="text-xs text-muted-foreground">Total répétitions</p>
              <p class="text-2xl font-bold text-primary">{{ totalReps }} reps</p>
              <p class="text-[10px] text-muted-foreground mt-0.5">(exercices au poids du corps)</p>
            </div>
          </div>
          <div v-if="repsEvolution !== null" class="mt-2">
            <div :class="[
              'flex items-center gap-1 text-xs font-medium',
              repsEvolution > 0 ? 'text-green-500' : repsEvolution < 0 ? 'text-red-500' : 'text-muted-foreground'
            ]">
              <ArrowUp v-if="repsEvolution > 0" class="w-3 h-3" />
              <ArrowDown v-if="repsEvolution < 0" class="w-3 h-3" />
              <span>{{ repsEvolution > 0 ? '+' : '' }}{{ Math.abs(repsEvolution) }} reps</span>
              <span class="text-muted-foreground">vs dernière fois</span>
            </div>
          </div>
        </div>

        <!-- Séries totales -->
        <div class="bg-gradient-to-br from-primary/10 to-primary/5 rounded-lg p-5 border border-primary/20">
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
              <List class="w-5 h-5 text-primary" />
            </div>
            <div>
              <p class="text-xs text-muted-foreground">Séries totales</p>
              <p class="text-2xl font-bold text-primary">{{ totalSets }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Meilleures séries par exercice -->
      <div v-if="bestSets.length > 0" class="space-y-4">
        <h4 class="text-lg font-semibold text-foreground flex items-center gap-2">
          <Star class="w-5 h-5 text-primary" />
          Meilleures séries
        </h4>
        <div class="space-y-3">
          <div
            v-for="(bestSet, index) in bestSets"
            :key="bestSet.exerciseId"
            class="bg-gradient-to-r from-muted/50 to-muted/30 rounded-lg p-4 border border-border/50 hover:border-primary/30 transition-all duration-200"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-2">
                  <span class="font-semibold text-base text-foreground">{{ bestSet.exerciseName }}</span>
                  <span
                    v-if="bestSet.isPR"
                    class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-yellow-500/20 text-yellow-600 border border-yellow-500/30"
                  >
                    <Trophy class="w-3 h-3 mr-1" />
                    PR
                  </span>
                </div>
                <div class="flex items-center gap-4 text-sm flex-wrap">
                  <!-- Afficher selon le type d'exercice -->
                  <template v-if="bestSet.measurementType === 'weight_reps' || bestSet.measurementType === 'weight_only'">
                    <div class="flex items-center gap-1.5">
                      <Weight class="w-4 h-4 text-muted-foreground" />
                      <span class="font-medium text-foreground">{{ formatWeight(bestSet.weight) }} kg</span>
                    </div>
                    <span v-if="bestSet.measurementType === 'weight_reps'" class="text-muted-foreground">×</span>
                    <div v-if="bestSet.measurementType === 'weight_reps'" class="flex items-center gap-1.5">
                      <Repeat class="w-4 h-4 text-muted-foreground" />
                      <span class="font-medium text-foreground">{{ bestSet.reps }} rep{{ bestSet.reps > 1 ? 's' : '' }}</span>
                    </div>
                    <span class="text-muted-foreground">=</span>
                    <span class="font-bold text-primary">{{ formatWeight(bestSet.rm || bestSet.value) }} kg</span>
                    <span class="text-xs text-muted-foreground">(1RM estimé)</span>
                  </template>
                  
                  <template v-else-if="bestSet.measurementType === 'reps'">
                    <div class="flex items-center gap-1.5">
                      <Repeat class="w-4 h-4 text-muted-foreground" />
                      <span class="font-medium text-foreground">{{ bestSet.reps }} rep{{ bestSet.reps > 1 ? 's' : '' }}</span>
                    </div>
                    <span v-if="bestSet.weight > 0" class="text-muted-foreground">({{ formatWeight(bestSet.weight) }} kg)</span>
                    <span class="text-muted-foreground">=</span>
                    <span class="font-bold text-primary">{{ formatSetValue(bestSet.value, bestSet.measurementType) }}</span>
                  </template>
                  
                  <template v-else-if="bestSet.measurementType === 'time' || bestSet.measurementType === 'time_reps'">
                    <div class="flex items-center gap-1.5">
                      <Clock class="w-4 h-4 text-muted-foreground" />
                      <span class="font-medium text-foreground">{{ Math.floor((bestSet.duration_seconds || 0) / 60) }}min {{ (bestSet.duration_seconds || 0) % 60 }}s</span>
                    </div>
                    <span v-if="bestSet.measurementType === 'time_reps' && bestSet.reps > 0" class="text-muted-foreground">× {{ bestSet.reps }} reps</span>
                    <span class="text-muted-foreground">=</span>
                    <span class="font-bold text-primary">{{ formatSetValue(bestSet.value, bestSet.measurementType) }}</span>
                  </template>
                  
                  <template v-else-if="bestSet.measurementType === 'distance' || bestSet.measurementType === 'time_distance'">
                    <div class="flex items-center gap-1.5">
                      <span class="font-medium text-foreground">{{ formatSetValue(bestSet.distance_meters || 0, 'distance') }}</span>
                    </div>
                    <span v-if="bestSet.measurementType === 'time_distance' && bestSet.duration_seconds" class="text-muted-foreground">en {{ Math.floor((bestSet.duration_seconds || 0) / 60) }}min</span>
                  </template>
                </div>
                <!-- Comparaison avec la dernière fois -->
                <div v-if="bestSet.previousBest" class="mt-2 pt-2 border-t border-border/30">
                  <div class="flex items-center gap-2 text-xs text-muted-foreground flex-wrap">
                    <span>Dernière fois :</span>
                    <template v-if="bestSet.measurementType === 'weight_reps' || bestSet.measurementType === 'weight_only'">
                      <span class="font-medium">{{ formatWeight(bestSet.previousBest.rm || bestSet.previousBest.value) }} kg</span>
                      <span class="text-xs">(1RM estimé)</span>
                      <span
                        :class="[
                          'font-medium',
                          (bestSet.rm || bestSet.value) > (bestSet.previousBest.rm || bestSet.previousBest.value) ? 'text-green-500' : 'text-muted-foreground'
                        ]"
                      >
                        ({{ (bestSet.rm || bestSet.value) > (bestSet.previousBest.rm || bestSet.previousBest.value) ? '+' : '' }}{{ formatWeight(Math.abs((bestSet.rm || bestSet.value) - (bestSet.previousBest.rm || bestSet.previousBest.value))) }} kg)
                      </span>
                    </template>
                    <template v-else>
                      <span class="font-medium">{{ formatSetValue(bestSet.previousBest.value, bestSet.previousBest.measurementType || bestSet.measurementType) }}</span>
                      <span
                        :class="[
                          'font-medium',
                          bestSet.value > bestSet.previousBest.value ? 'text-green-500' : 'text-muted-foreground'
                        ]"
                      >
                        ({{ bestSet.value > bestSet.previousBest.value ? '+' : '' }}{{ formatSetValue(Math.abs(bestSet.value - bestSet.previousBest.value), bestSet.measurementType) }})
                      </span>
                    </template>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Évolutions par exercice -->
      <div v-if="evolutions.length > 0" class="space-y-4">
        <h4 class="text-lg font-semibold text-foreground flex items-center gap-2">
          <TrendingUp class="w-5 h-5 text-primary" />
          Évolutions
        </h4>
        <div class="space-y-3">
          <div
            v-for="evolution in evolutions"
            :key="evolution.exerciseId"
            class="bg-gradient-to-r from-muted/50 to-muted/30 rounded-lg p-4 border border-border/50"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="flex-1">
                <div class="font-semibold text-base text-foreground mb-2">{{ evolution.exerciseName }}</div>
                <div class="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p class="text-xs text-muted-foreground mb-1">Cette séance</p>
                    <p class="font-medium text-foreground">
                      {{ formatSetValue(evolution.current.value, evolution.measurementType) }}
                      <span class="text-muted-foreground text-xs">({{ evolution.current.sets }} séries)</span>
                    </p>
                  </div>
                  <div>
                    <p class="text-xs text-muted-foreground mb-1">Dernière fois</p>
                    <p class="font-medium text-muted-foreground">
                      {{ formatSetValue(evolution.previous.value, evolution.measurementType) }}
                      <span class="text-muted-foreground text-xs">({{ evolution.previous.sets }} séries)</span>
                    </p>
                  </div>
                </div>
                <div class="mt-2 pt-2 border-t border-border/30">
                  <div
                    :class="[
                      'flex items-center gap-2 text-xs font-medium',
                      evolution.difference > 0 ? 'text-green-500' : evolution.difference < 0 ? 'text-red-500' : 'text-muted-foreground'
                    ]"
                  >
                    <ArrowUp v-if="evolution.difference > 0" class="w-3 h-3" />
                    <ArrowDown v-if="evolution.difference < 0" class="w-3 h-3" />
                    <span>{{ evolution.difference > 0 ? '+' : '' }}{{ formatSetValue(Math.abs(evolution.difference), evolution.measurementType) }}</span>
                    <span v-if="evolution.previous.value > 0" class="text-muted-foreground">({{ ((evolution.difference / evolution.previous.value) * 100).toFixed(1) }}%)</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useSupabaseClient } from '#imports'
import {
  Trophy,
  Weight,
  Calendar,
  Clock,
  Dumbbell,
  AlertTriangle,
  Star,
  TrendingUp,
  ArrowUp,
  ArrowDown,
  List,
  Repeat
} from 'lucide-vue-next'

const supabase = useSupabaseClient()
const loading = ref(true)
const error = ref(null)
const sessionData = ref(null)
const prCount = ref(0)
const totalVolume = ref(0)
const totalReps = ref(0) // Total de répétitions pour exercices sans poids
const totalSets = ref(0)
const volumeEvolution = ref(null)
const repsEvolution = ref(null) // Évolution des répétitions
const bestSets = ref([])
const evolutions = ref([])
const hasWeightExercises = ref(false)
const hasRepsOnlyExercises = ref(false)

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

const formatDuration = (start, end) => {
  const startDate = new Date(start)
  const endDate = new Date(end)
  const durationMs = endDate - startDate
  const minutes = Math.floor(durationMs / (1000 * 60))
  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60

  if (hours > 0) {
    return `${hours}h${remainingMinutes > 0 ? ` ${remainingMinutes}min` : ''}`
  }
  return `${minutes}min`
}

const formatWeight = (weight) => {
  return weight.toLocaleString('fr-FR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })
}

// Fonction pour calculer le 1RM estimé (formule Brzycki/Epley)
const calculateRM = (weight, reps) => {
  if (!weight || weight === 0 || !reps || reps === 0) return 0
  return weight * (1 + 0.0333 * reps)
}

// Fonction helper pour calculer la valeur d'une série selon le type d'exercice
const calculateSetValue = (set, measurementType) => {
  switch (measurementType) {
    case 'weight_reps':
    case 'weight_only':
      // Volume = poids × reps (ou poids seul si pas de reps)
      return (set.weight_kg || 0) * (set.reps || 1)
    
    case 'reps':
      // Total de répétitions (ou poids × reps si lesté)
      if (set.weight_kg && set.weight_kg > 0) {
        return (set.weight_kg || 0) * (set.reps || 0)
      }
      return set.reps || 0
    
    case 'time':
      // Temps total en secondes (ou temps × reps si séries)
      return (set.duration_seconds || 0) * (set.reps || 1)
    
    case 'time_reps':
      // Temps × répétitions
      return (set.duration_seconds || 0) * (set.reps || 0)
    
    case 'distance':
      // Distance en mètres
      return set.distance_meters || 0
    
    case 'time_distance':
      // Distance (priorité) ou temps si pas de distance
      return set.distance_meters || (set.duration_seconds || 0)
    
    default:
      // Par défaut : poids × reps
      return (set.weight_kg || 0) * (set.reps || 0)
  }
}

// Fonction helper pour formater la valeur selon le type d'exercice
const formatSetValue = (value, measurementType) => {
  switch (measurementType) {
    case 'time':
    case 'time_reps':
      // Afficher en minutes:secondes ou secondes
      const minutes = Math.floor(value / 60)
      const seconds = value % 60
      if (minutes > 0) {
        return `${minutes}min ${seconds}s`
      }
      return `${seconds}s`
    
    case 'distance':
    case 'time_distance':
      // Afficher en km ou mètres
      if (value >= 1000) {
        return `${(value / 1000).toFixed(2)} km`
      }
      return `${value.toFixed(0)} m`
    
    case 'reps':
      // Afficher le nombre de reps
      return `${value.toFixed(0)} reps`
    
    default:
      // Par défaut : poids en kg
      return `${formatWeight(value)} kg`
  }
}

// Fonction helper pour obtenir le label de la métrique selon le type
const getMetricLabel = (measurementType) => {
  switch (measurementType) {
    case 'time':
    case 'time_reps':
      return 'Temps total'
    case 'distance':
    case 'time_distance':
      return 'Distance totale'
    case 'reps':
      return 'Répétitions totales'
    default:
      return 'Volume total'
  }
}

const loadSessionRecap = async () => {
  try {
    loading.value = true
    error.value = null

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      error.value = 'Utilisateur non authentifié'
      return
    }

    // 1. Récupérer la dernière séance effectuée avec le measurement_type des exercices
    const { data: lastSession, error: sessionError } = await supabase
      .from('performedsession')
      .select(`
        id,
        started_at,
        ended_at,
        workout_session_id,
        workoutsession (
          title,
          workoutexercise (
            id,
            exercise_id,
            exercise:exercise_id (
              id,
              name,
              measurement_type
            )
          )
        )
      `)
      .eq('user_id', user.id)
      .order('ended_at', { ascending: false })
      .not('ended_at', 'is', null)
      .limit(1)
      .single()

    if (sessionError) {
      if (sessionError.code === 'PGRST116') {
        // Aucune séance trouvée
        return
      }
      throw sessionError
    }

    if (!lastSession || !lastSession.ended_at) {
      return
    }

    const exerciseIds = lastSession.workoutsession.workoutexercise.map(ex => ex.exercise_id)
    const exerciseMap = {}
    const exerciseTypeMap = {} // Pour stocker le measurement_type de chaque exercice
    
    lastSession.workoutsession.workoutexercise.forEach(ex => {
      exerciseMap[ex.exercise_id] = ex.exercise.name
      exerciseTypeMap[ex.exercise_id] = ex.exercise?.measurement_type || 'weight_reps'
    })

    // 2. Récupérer toutes les séries de cette séance avec toutes les colonnes nécessaires
    const { data: currentSets, error: setsError } = await supabase
      .from('exerciseset')
      .select(`
        id,
        exercise_id,
        weight_kg,
        reps,
        duration_seconds,
        distance_meters,
        created_at
      `)
      .eq('performed_session_id', lastSession.id)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })

    if (setsError) throw setsError

    if (!currentSets || currentSets.length === 0) {
      return
    }

    // Calculer le volume total et le nombre de séries
    // Séparer les exercices avec poids et ceux sans poids
    totalSets.value = currentSets.length
    
    // Calculer le volume total uniquement pour les exercices avec poids (weight_reps)
    const weightRepsSets = currentSets.filter(set => {
      const exerciseType = exerciseTypeMap[set.exercise_id] || 'weight_reps'
      return exerciseType === 'weight_reps' || exerciseType === 'weight_only'
    })
    
    totalVolume.value = weightRepsSets.reduce((total, set) => {
      return total + calculateSetValue(set, exerciseTypeMap[set.exercise_id] || 'weight_reps')
    }, 0)
    
    hasWeightExercises.value = weightRepsSets.length > 0
    
    // Calculer le total de répétitions pour les exercices sans poids (reps)
    const repsOnlySets = currentSets.filter(set => {
      const exerciseType = exerciseTypeMap[set.exercise_id] || 'weight_reps'
      return exerciseType === 'reps'
    })
    
    totalReps.value = repsOnlySets.reduce((total, set) => {
      return total + (set.reps || 0)
    }, 0)
    
    hasRepsOnlyExercises.value = repsOnlySets.length > 0

    // 3. Récupérer toutes les séances précédentes pour comparer
    const { data: previousSessions, error: prevSessionsError } = await supabase
      .from('performedsession')
      .select(`
        id,
        started_at,
        ended_at,
        workout_session_id
      `)
      .eq('user_id', user.id)
      .lt('ended_at', lastSession.ended_at)
      .not('ended_at', 'is', null)
      .order('ended_at', { ascending: false })
      .limit(50) // Limiter pour les performances

    if (prevSessionsError) throw prevSessionsError

    // 4. Récupérer toutes les séries précédentes de l'utilisateur pour chaque exercice
    // Uniquement les séries qui appartiennent à des séances terminées
    const { data: allPreviousSets, error: allPrevSetsError } = await supabase
      .from('exerciseset')
      .select(`
        id,
        exercise_id,
        weight_kg,
        reps,
        duration_seconds,
        distance_meters,
        created_at,
        performed_session_id
      `)
      .in('exercise_id', exerciseIds)
      .eq('user_id', user.id)
      .not('performed_session_id', 'is', null)
      .neq('performed_session_id', lastSession.id)
      .order('created_at', { ascending: false })

    if (allPrevSetsError) throw allPrevSetsError

    // 5. Trouver la dernière séance du même type (même workout_session_id)
    const lastSameSession = previousSessions?.find(s => s.workout_session_id === lastSession.workout_session_id)

    // Calculer le volume de la dernière même séance (uniquement pour exercices avec poids)
    let previousSessionVolume = 0
    let previousSessionReps = 0
    
    if (lastSameSession) {
      const previousSets = allPreviousSets?.filter(set => {
        const setDate = new Date(set.created_at)
        return setDate >= new Date(lastSameSession.started_at) && setDate <= new Date(lastSameSession.ended_at)
      }) || []

      // Filtrer uniquement les exercices avec poids pour la comparaison de volume
      const previousWeightRepsSets = previousSets.filter(set => {
        const exerciseType = exerciseTypeMap[set.exercise_id] || 'weight_reps'
        return exerciseType === 'weight_reps' || exerciseType === 'weight_only'
      })

      previousSessionVolume = previousWeightRepsSets.reduce((total, set) => {
        return total + calculateSetValue(set, exerciseTypeMap[set.exercise_id] || 'weight_reps')
      }, 0)
      
      // Calculer le total de répétitions pour les exercices sans poids
      const previousRepsOnlySets = previousSets.filter(set => {
        const exerciseType = exerciseTypeMap[set.exercise_id] || 'weight_reps'
        return exerciseType === 'reps'
      })
      
      previousSessionReps = previousRepsOnlySets.reduce((total, set) => {
        return total + (set.reps || 0)
      }, 0)
    }

    volumeEvolution.value = totalVolume.value - previousSessionVolume
    repsEvolution.value = totalReps.value - previousSessionReps

    // 6. Calculer les meilleures séries par exercice (PR)
    const bestSetsMap = {}
    const prs = []

    exerciseIds.forEach(exerciseId => {
      const exerciseSets = currentSets.filter(set => set.exercise_id === exerciseId)
      if (exerciseSets.length === 0) return

      const exerciseType = exerciseTypeMap[exerciseId] || 'weight_reps'
      
      // Trouver la meilleure série selon le type d'exercice
      let bestSet = null
      let bestValue = 0
      let bestRM = 0 // Pour les exercices avec poids, on utilise le 1RM estimé

      exerciseSets.forEach(set => {
        let value = calculateSetValue(set, exerciseType)
        let rm = 0
        
        // Pour les exercices avec poids, calculer le 1RM estimé
        if (exerciseType === 'weight_reps' || exerciseType === 'weight_only') {
          rm = calculateRM(set.weight_kg || 0, set.reps || 0)
          if (rm > bestRM) {
            bestRM = rm
            bestValue = value
            bestSet = set
          }
        } else {
          // Pour les autres types (reps, time, etc.), utiliser la valeur brute
          if (value > bestValue) {
            bestValue = value
            bestSet = set
          }
        }
      })

      if (bestSet) {
        // Comparer avec toutes les séries précédentes de cet exercice
        const previousSetsForExercise = allPreviousSets?.filter(set => set.exercise_id === exerciseId) || []
        let isPR = true
        let previousBest = null
        let previousBestRM = 0

        previousSetsForExercise.forEach(prevSet => {
          if (exerciseType === 'weight_reps' || exerciseType === 'weight_only') {
            // Pour les exercices avec poids, comparer les 1RM estimés
            const prevRM = calculateRM(prevSet.weight_kg || 0, prevSet.reps || 0)
            if (prevRM >= bestRM) {
              isPR = false
            }
            if (prevRM > previousBestRM) {
              previousBestRM = prevRM
              const prevValue = calculateSetValue(prevSet, exerciseType)
              previousBest = {
                weight: prevSet.weight_kg || 0,
                reps: prevSet.reps || 0,
                duration_seconds: prevSet.duration_seconds || 0,
                distance_meters: prevSet.distance_meters || 0,
                value: prevValue,
                rm: prevRM,
                measurementType: exerciseType
              }
            }
          } else {
            // Pour les autres types, comparer les valeurs brutes
            const prevValue = calculateSetValue(prevSet, exerciseType)
            if (prevValue >= bestValue) {
              isPR = false
            }
            if (!previousBest || prevValue > previousBest.value) {
              previousBest = {
                weight: prevSet.weight_kg || 0,
                reps: prevSet.reps || 0,
                duration_seconds: prevSet.duration_seconds || 0,
                distance_meters: prevSet.distance_meters || 0,
                value: prevValue,
                measurementType: exerciseType
              }
            }
          }
        })

        bestSetsMap[exerciseId] = {
          exerciseId,
          exerciseName: exerciseMap[exerciseId],
          weight: bestSet.weight_kg || 0,
          reps: bestSet.reps || 0,
          duration_seconds: bestSet.duration_seconds || 0,
          distance_meters: bestSet.distance_meters || 0,
          value: bestValue,
          rm: bestRM, // Ajouter le 1RM estimé pour les exercices avec poids
          measurementType: exerciseType,
          isPR,
          previousBest
        }

        if (isPR) {
          prs.push(exerciseId)
        }
      }
    })

    prCount.value = prs.length
    bestSets.value = Object.values(bestSetsMap).sort((a, b) => b.value - a.value)

    // 7. Calculer les évolutions par exercice (comparaison avec la dernière même séance)
    const evolutionsMap = {}

    if (lastSameSession) {
      exerciseIds.forEach(exerciseId => {
        const exerciseType = exerciseTypeMap[exerciseId] || 'weight_reps'
        const currentExerciseSets = currentSets.filter(set => set.exercise_id === exerciseId)
        const previousExerciseSets = allPreviousSets?.filter(set => {
          if (set.exercise_id !== exerciseId) return false
          const setDate = new Date(set.created_at)
          return setDate >= new Date(lastSameSession.started_at) && setDate <= new Date(lastSameSession.ended_at)
        }) || []

        if (currentExerciseSets.length > 0 && previousExerciseSets.length > 0) {
          const currentValue = currentExerciseSets.reduce((total, set) => {
            return total + calculateSetValue(set, exerciseType)
          }, 0)

          const previousValue = previousExerciseSets.reduce((total, set) => {
            return total + calculateSetValue(set, exerciseType)
          }, 0)

          if (currentValue !== previousValue) {
            evolutionsMap[exerciseId] = {
              exerciseId,
              exerciseName: exerciseMap[exerciseId],
              measurementType: exerciseType,
              current: {
                value: currentValue,
                sets: currentExerciseSets.length
              },
              previous: {
                value: previousValue,
                sets: previousExerciseSets.length
              },
              difference: currentValue - previousValue
            }
          }
        }
      })
    }

    evolutions.value = Object.values(evolutionsMap).sort((a, b) => Math.abs(b.difference) - Math.abs(a.difference))

    // Stocker les données de la séance
    sessionData.value = {
      sessionTitle: lastSession.workoutsession.title,
      startedAt: lastSession.started_at,
      endedAt: lastSession.ended_at,
      exerciseCount: exerciseIds.length
    }
  } catch (e) {
    console.error('Erreur lors du chargement du récapitulatif:', e)
    error.value = e.message || 'Erreur lors du chargement des données'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadSessionRecap()
})
</script>

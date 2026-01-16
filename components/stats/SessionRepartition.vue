<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary"></div>
    </div>
    
    <div v-else-if="error" class="text-red-500 text-center py-12">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4 text-red-500" />
      <p class="text-sm font-medium">{{ error }}</p>
    </div>

    <div v-else-if="!hasData" class="flex flex-col items-center justify-center py-16 px-4 space-y-4 bg-gradient-to-br from-muted/30 to-muted/50 rounded-xl">
      <Dumbbell class="w-16 h-16 text-muted-foreground/40" />
      <p class="text-sm text-muted-foreground text-center font-medium">
        Aucune séance avec exercices trouvée
      </p>
    </div>

    <div v-else class="space-y-8">
      <!-- Liste des muscles avec détails -->
      <div class="space-y-4 max-h-[500px] overflow-y-auto pr-2">
        <div
          v-for="(score, muscle) in muscleDistribution"
          :key="muscle"
          class="bg-gradient-to-r from-muted/50 to-muted/30 rounded-lg p-5 transition-all duration-200 hover:shadow-md"
        >
          <div class="flex items-start justify-between gap-4">
            <div class="flex-1">
              <div class="flex items-center gap-3 mb-3">
                <div
                  class="w-4 h-4 rounded-full flex-shrink-0"
                  :style="{ backgroundColor: getMuscleColor(muscle) }"
                ></div>
                <span class="font-semibold text-base text-foreground">{{ muscle }}</span>
              </div>
              <div class="flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
                <div v-if="muscleDetails[muscle]?.primary > 0" class="flex items-center gap-2">
                  <span class="w-2 h-2 rounded-full bg-primary"></span>
                  <span>{{ muscleDetails[muscle].primary }} principal{{ muscleDetails[muscle].primary > 1 ? 'aux' : '' }}</span>
                </div>
                <div v-if="muscleDetails[muscle]?.secondary > 0" class="flex items-center gap-2">
                  <span class="w-2 h-2 rounded-full bg-primary/50"></span>
                  <span>{{ muscleDetails[muscle].secondary }} secondaire{{ muscleDetails[muscle].secondary > 1 ? 's' : '' }}</span>
                </div>
              </div>
            </div>
            <div class="text-right flex-shrink-0">
              <div class="text-2xl font-bold text-primary">{{ score.toFixed(1) }}</div>
              <div class="text-xs text-muted-foreground mt-0.5">points</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Note explicative améliorée -->
      <div class="bg-gradient-to-r from-primary/10 via-primary/5 to-primary/10 rounded-lg p-5">
        <div class="flex items-start gap-4">
          <div class="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center flex-shrink-0">
            <span class="text-primary">💡</span>
          </div>
          <div class="flex-1 space-y-3">
            <p class="text-sm font-medium text-foreground">À quoi correspondent les points ?</p>
            <div class="space-y-2 text-xs text-muted-foreground leading-relaxed">
              <p>
                Les <strong class="text-foreground">points</strong> représentent un score pondéré qui mesure l'importance de chaque muscle dans toutes vos séances.
              </p>
              <ul class="list-disc list-inside space-y-1.5 ml-2">
                <li><strong class="text-foreground">Muscle principal</strong> = <strong class="text-primary">1.0 point</strong></li>
                <li><strong class="text-foreground">Muscle secondaire</strong> = <strong class="text-primary">0.5 point</strong></li>
              </ul>
              <p class="pt-1 text-[11px] italic">
                Plus le score est élevé, plus le muscle est sollicité dans l'ensemble de vos séances.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useSupabaseClient } from '#imports'
import { ref, onMounted, computed } from 'vue'
import { Dumbbell, AlertTriangle } from 'lucide-vue-next'

const supabase = useSupabaseClient()
const muscleDistribution = ref({})
const muscleDetails = ref({}) // Détails principal/secondaire pour chaque muscle
const loading = ref(true)
const error = ref(null)

// Palette de couleurs moderne et variée
const colorPalette = [
  '#FE751C', // Orange principal
  '#3B82F6', // Bleu
  '#10B981', // Vert
  '#8B5CF6', // Violet
  '#F59E0B', // Ambre
  '#EF4444', // Rouge
  '#06B6D4', // Cyan
  '#EC4899', // Rose
  '#84CC16', // Vert lime
  '#F97316', // Orange foncé
  '#6366F1', // Indigo
  '#14B8A6', // Teal
  '#A855F7', // Violet foncé
  '#22C55E', // Vert émeraude
  '#F43F5E', // Rose foncé
  '#0EA5E9', // Sky blue
]

// Générer des couleurs pour les muscles
const generateColors = (count) => {
  const colors = []
  for (let i = 0; i < count; i++) {
    colors.push(colorPalette[i % colorPalette.length])
  }
  return colors
}

// Obtenir la couleur d'un muscle spécifique
const getMuscleColor = (muscleName) => {
  const muscles = Object.keys(muscleDistribution.value)
  const index = muscles.indexOf(muscleName)
  if (index !== -1) {
    return colorPalette[index % colorPalette.length]
  }
  return '#FE751C'
}

const hasData = computed(() => {
  return Object.keys(muscleDistribution.value).length > 0
})

const loadMuscleData = async () => {
  try {
    loading.value = true
    error.value = null

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      loading.value = false
      return
    }

    // Récupérer toutes les séances de l'utilisateur
    const { data: workouts, error: workoutsError } = await supabase
      .from('workoutsession')
      .select('id')
      .eq('user_id', user.id)

    if (workoutsError) throw workoutsError

    if (!workouts || workouts.length === 0) {
      muscleDistribution.value = {}
      return
    }

    // Récupérer tous les exercices de toutes les séances avec leurs muscles associés
    // Essayer d'abord avec la nouvelle structure (muscles multiples)
    let query = supabase
      .from('workoutexercise')
      .select(`
        exercise_id,
        exercise:exercise_id (
          id,
          name,
          primary_muscle,
          exercise_muscle (
            is_primary,
            muscle:muscle_id (
              id,
              name
            )
          )
        )
      `)
      .in('session_id', workouts.map(w => w.id))

    let { data: workoutExercises, error: exercisesError } = await query

    // Si erreur liée à la table exercise_muscle qui n'existe pas, essayer sans
    if (exercisesError && (exercisesError.message?.includes('exercise_muscle') || exercisesError.code === '42P01')) {
      console.warn('Table exercise_muscle non trouvée, utilisation de la structure simple')
      query = supabase
        .from('workoutexercise')
        .select(`
          exercise_id,
          exercise:exercise_id (
            id,
            name,
            primary_muscle
          )
        `)
        .in('session_id', workouts.map(w => w.id))

      const result = await query
      workoutExercises = result.data
      exercisesError = result.error
    }

    if (exercisesError) throw exercisesError

    if (!workoutExercises || workoutExercises.length === 0) {
      muscleDistribution.value = {}
      return
    }

    // Calculer la distribution des muscles avec pondération précise
    // Muscle principal = 1.0 point, Muscle secondaire = 0.5 point
    const distribution = {}
    const localMuscleDetails = {}

    workoutExercises.forEach(workoutExercise => {
      const exercise = workoutExercise.exercise
      
      if (!exercise) return

      // PRIORITÉ : Utiliser les muscles détaillés de exercise_muscle si disponibles
      const exerciseMuscles = exercise.exercise_muscle || exercise.exercise_muscles
      
      if (exerciseMuscles && Array.isArray(exerciseMuscles) && exerciseMuscles.length > 0) {
        // Filtrer les entrées valides avec un muscle
        const validMuscles = exerciseMuscles.filter(em => em.muscle && em.muscle.name)
        
        if (validMuscles.length > 0) {
          // Utiliser les muscles détaillés
          validMuscles.forEach(em => {
            const muscleName = em.muscle.name
            const isPrimary = em.is_primary === true
            
            // Initialiser les détails si nécessaire
            if (!localMuscleDetails[muscleName]) {
              localMuscleDetails[muscleName] = { primary: 0, secondary: 0 }
            }
            
            // Pondération : principal = 1.0, secondaire = 0.5
            const weight = isPrimary ? 1.0 : 0.5
            distribution[muscleName] = (distribution[muscleName] || 0) + weight
            
            // Compter aussi séparément pour l'affichage
            if (isPrimary) {
              localMuscleDetails[muscleName].primary += 1
            } else {
              localMuscleDetails[muscleName].secondary += 1
            }
          })
          return // Ne pas utiliser primary_muscle si on a des muscles détaillés
        }
      }
      
      // FALLBACK : Utiliser primary_muscle seulement si aucun muscle détaillé n'est disponible
      // Mais on préfère ignorer les muscles génériques
      const genericMuscles = ['Jambes', 'Pectoraux', 'Épaules', 'Dorsaux', 'Biceps', 'Triceps', 'Abdominaux', 'Cardio', 'Autre']
      if (exercise.primary_muscle && !genericMuscles.includes(exercise.primary_muscle)) {
        const muscleName = exercise.primary_muscle
        distribution[muscleName] = (distribution[muscleName] || 0) + 1.0
        
        if (!localMuscleDetails[muscleName]) {
          localMuscleDetails[muscleName] = { primary: 0, secondary: 0 }
        }
        localMuscleDetails[muscleName].primary += 1
      }
    })

    // Trier par score pondéré (décroissant)
    const sortedDistribution = {}
    const sortedDetails = {}
    Object.entries(distribution)
      .sort(([, a], [, b]) => b - a)
      .forEach(([muscle, score]) => {
        sortedDistribution[muscle] = score
        sortedDetails[muscle] = localMuscleDetails[muscle] || { primary: 0, secondary: 0 }
      })

    muscleDistribution.value = sortedDistribution
    muscleDetails.value = sortedDetails
  } catch (e) {
    console.error('Erreur lors du chargement de la répartition des muscles:', e)
    error.value = e.message || 'Erreur lors du chargement des données'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadMuscleData()
})
</script>

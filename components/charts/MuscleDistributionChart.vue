<template>
  <div class="bg-card rounded-xl p-6 shadow-sm hover:shadow-md transition-shadow duration-300">
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
        Aucun exercice dans cette séance
      </p>
    </div>

    <div v-else class="space-y-6">
      <!-- Graphique principal -->
      <div class="relative">
        <div class="h-80 md:h-96">
          <Pie
            v-if="chartData"
            :data="chartData"
            :options="chartOptions"
          />
        </div>
      </div>

      <!-- Liste des muscles avec détails -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-3 max-h-64 overflow-y-auto pr-2">
        <div
          v-for="(score, muscle) in muscleDistribution"
          :key="muscle"
          class="bg-gradient-to-r from-muted/50 to-muted/30 rounded-lg p-3 border border-border/50 hover:border-primary/30 transition-all duration-200 hover:shadow-sm"
        >
          <div class="flex items-center justify-between mb-2">
            <div class="flex items-center gap-2">
              <div
                class="w-3 h-3 rounded-full"
                :style="{ backgroundColor: getMuscleColor(muscle) }"
              ></div>
              <span class="font-semibold text-sm text-foreground">{{ muscle }}</span>
            </div>
            <div class="text-right">
              <span class="text-lg font-bold text-primary">{{ score.toFixed(1) }}</span>
              <span class="text-xs text-muted-foreground ml-1">pts</span>
            </div>
          </div>
          <div class="flex items-center gap-3 text-xs">
            <div v-if="muscleDetails[muscle]?.primary > 0" class="flex items-center gap-1">
              <span class="w-2 h-2 rounded-full bg-primary"></span>
              <span class="text-muted-foreground">{{ muscleDetails[muscle].primary }} principal{{ muscleDetails[muscle].primary > 1 ? 'aux' : '' }}</span>
            </div>
            <div v-if="muscleDetails[muscle]?.secondary > 0" class="flex items-center gap-1">
              <span class="w-2 h-2 rounded-full bg-primary/50"></span>
              <span class="text-muted-foreground">{{ muscleDetails[muscle].secondary }} secondaire{{ muscleDetails[muscle].secondary > 1 ? 's' : '' }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Note explicative améliorée -->
      <div class="bg-gradient-to-r from-primary/10 via-primary/5 to-primary/10 rounded-lg p-4 border border-primary/20">
        <div class="flex items-start gap-3">
          <div class="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center flex-shrink-0 mt-0.5">
            <span class="text-primary text-sm">💡</span>
          </div>
          <div class="flex-1">
            <p class="text-sm font-medium text-foreground mb-2">À quoi correspondent les points ?</p>
            <div class="space-y-2 text-xs text-muted-foreground leading-relaxed">
              <p>
                Les <strong class="text-foreground">points</strong> représentent un score pondéré qui mesure l'importance de chaque muscle dans votre séance :
              </p>
              <ul class="list-disc list-inside space-y-1 ml-2">
                <li><strong class="text-foreground">Muscle principal</strong> dans un exercice = <strong class="text-primary">1.0 point</strong></li>
                <li><strong class="text-foreground">Muscle secondaire</strong> dans un exercice = <strong class="text-primary">0.5 point</strong></li>
              </ul>
              <p class="pt-1">
                <strong class="text-foreground">Exemple :</strong> Si "Quadriceps" est principal dans 2 exercices et secondaire dans 1 exercice, 
                son score sera : <strong class="text-primary">2 × 1.0 + 1 × 0.5 = 2.5 points</strong>
              </p>
              <p class="text-[10px] pt-1 italic">
                Plus le score est élevé, plus le muscle est sollicité dans votre séance.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Pie } from 'vue-chartjs'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
import { ref, onMounted, computed } from 'vue'
import { useSupabaseClient } from '#imports'
import { Dumbbell, AlertTriangle } from 'lucide-vue-next'

ChartJS.register(ArcElement, Tooltip, Legend)

const props = defineProps({
  workoutSessionId: {
    type: String,
    required: true
  }
})

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

const chartData = computed(() => {
  const muscles = Object.keys(muscleDistribution.value)
  const counts = Object.values(muscleDistribution.value)
  const colors = generateColors(muscles.length)
  
  return {
    labels: muscles,
    datasets: [{
      label: 'Score pondéré',
      data: counts,
      backgroundColor: colors.map((c, i) => {
        // Ajouter de la transparence avec un gradient
        return c
      }),
      borderColor: '#ffffff',
      borderWidth: 3,
      hoverOffset: 8,
      hoverBorderWidth: 4
    }]
  }
})

const chartOptions = computed(() => {
  return {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      tooltip: {
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        padding: 12,
        titleFont: {
          size: 14,
          weight: 'bold'
        },
        bodyFont: {
          size: 12
        },
        borderColor: 'rgba(255, 255, 255, 0.1)',
        borderWidth: 1,
        cornerRadius: 8,
        displayColors: true,
        callbacks: {
          title: function(context) {
            return context[0].label || ''
          },
          label: function(context) {
            const muscleName = context.label || ''
            const score = context.parsed || 0
            const total = Object.values(muscleDistribution.value).reduce((a, b) => a + b, 0)
            const percentage = ((score / total) * 100).toFixed(1)
            
            // Récupérer les détails du muscle
            const details = muscleDetails.value[muscleName] || { primary: 0, secondary: 0 }
            const primaryCount = details.primary || 0
            const secondaryCount = details.secondary || 0
            
            const lines = [
              `Score: ${score.toFixed(1)} point${score > 1 ? 's' : ''} (${percentage}%)`
            ]
            
            if (primaryCount > 0 || secondaryCount > 0) {
              const parts = []
              if (primaryCount > 0) {
                parts.push(`${primaryCount} principal${primaryCount > 1 ? 'aux' : ''}`)
              }
              if (secondaryCount > 0) {
                parts.push(`${secondaryCount} secondaire${secondaryCount > 1 ? 's' : ''}`)
              }
              lines.push(parts.join(' + '))
            }
            
            return lines
          }
        }
      },
      legend: {
        display: false // On utilise notre propre liste détaillée
      }
    },
    animation: {
      animateRotate: true,
      animateScale: true,
      duration: 1000,
      easing: 'easeOutQuart'
    }
  }
})

const loadMuscleDistribution = async () => {
  try {
    loading.value = true
    error.value = null

    // Récupérer tous les exercices de la séance avec leurs muscles associés
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
      .eq('session_id', props.workoutSessionId)

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
        .eq('session_id', props.workoutSessionId)

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
    const muscleDetails = {} // Pour stocker les détails (principal/secondaire)

    workoutExercises.forEach(workoutExercise => {
      const exercise = workoutExercise.exercise
      
      if (!exercise) return

      // PRIORITÉ : Utiliser les muscles détaillés de exercise_muscle si disponibles
      // Vérifier exercise_muscle (nom de la table) ou exercise_muscles (alias)
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
            if (!muscleDetails[muscleName]) {
              muscleDetails[muscleName] = { primary: 0, secondary: 0 }
            }
            
            // Pondération : principal = 1.0, secondaire = 0.5
            const weight = isPrimary ? 1.0 : 0.5
            distribution[muscleName] = (distribution[muscleName] || 0) + weight
            
            // Compter aussi séparément pour l'affichage
            if (isPrimary) {
              muscleDetails[muscleName].primary += 1
            } else {
              muscleDetails[muscleName].secondary += 1
            }
          })
          return // Ne pas utiliser primary_muscle si on a des muscles détaillés
        }
      }
      
      // FALLBACK : Utiliser primary_muscle seulement si aucun muscle détaillé n'est disponible
      // Mais on préfère ignorer les muscles génériques comme "Jambes", "Pectoraux", "Épaules"
      const genericMuscles = ['Jambes', 'Pectoraux', 'Épaules', 'Dorsaux', 'Biceps', 'Triceps', 'Abdominaux', 'Cardio', 'Autre']
      if (exercise.primary_muscle && !genericMuscles.includes(exercise.primary_muscle)) {
        const muscleName = exercise.primary_muscle
        distribution[muscleName] = (distribution[muscleName] || 0) + 1.0
        
        if (!muscleDetails[muscleName]) {
          muscleDetails[muscleName] = { primary: 0, secondary: 0 }
        }
        muscleDetails[muscleName].primary += 1
      }
    })

    // Trier par score pondéré (décroissant)
    const sortedDistribution = {}
    const sortedDetails = {}
    Object.entries(distribution)
      .sort(([, a], [, b]) => b - a)
      .forEach(([muscle, score]) => {
        sortedDistribution[muscle] = score
        sortedDetails[muscle] = muscleDetails[muscle] || { primary: 0, secondary: 0 }
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
  loadMuscleDistribution()
})
</script>

<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg p-6">
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Progression du volume</h3>
    <div class="h-64">
      <Bar
        v-if="chartData"
        :data="chartData"
        :options="{
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: false
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              title: {
                display: true,
                text: 'Volume (kg)'
              }
            },
            x: {
              title: {
                display: true,
                text: 'Date'
              }
            }
          }
        }"
      />
    </div>
  </div>
</template>

<script setup>
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js'
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const props = defineProps({
  sessionId: {
    type: String,
    required: true
  }
})

const supabase = useSupabaseClient()
const chartData = ref({
  labels: [],
  datasets: [{
    label: 'Volume total',
    data: [],
    backgroundColor: 'oklch(51.1% 0.262 276.966)',
    borderColor: 'oklch(51.1% 0.262 276.966)',
    borderWidth: 1
  }]
})

const loadSessionWeightData = async () => {
  try {
    // Récupérer d'abord les exercices de la séance
    const { data: sessionExercises, error: exercisesError } = await supabase
      .from('workoutexercise')
      .select(`
        id,
        exercise_id
      `)
      .eq('session_id', props.sessionId)

    if (exercisesError) throw exercisesError
    if (!sessionExercises?.length) return

    // Récupérer les sets pour ces exercices
    const { data: sets, error: setsError } = await supabase
      .from('exerciseset')
      .select(`
        weight_kg,
        reps,
        created_at
      `)
      .in('exercise_id', sessionExercises.map(ex => ex.exercise_id))
      .eq('user_id', (await supabase.auth.getUser()).data.user.id)
      .order('created_at', { ascending: true })

    if (setsError) throw setsError

    // Grouper les sets par date
    const setsByDate = sets.reduce((acc, set) => {
      const date = new Date(set.created_at).toLocaleDateString('fr-FR', {
        day: 'numeric',
        month: 'short'
      })
      
      if (!acc[date]) {
        acc[date] = 0
      }
      acc[date] += set.weight_kg * set.reps
      return acc
    }, {})

    // Convertir en format pour le graphique et trier par date
    const dates = Object.keys(setsByDate).sort((a, b) => {
      const dateA = new Date(a.split(' ').reverse().join(' '))
      const dateB = new Date(b.split(' ').reverse().join(' '))
      return dateA - dateB
    })

    // Mettre à jour les données du graphique
    chartData.value = {
      labels: dates,
      datasets: [{
        label: 'Volume total',
        data: dates.map(date => setsByDate[date]),
        backgroundColor: 'oklch(51.1% 0.262 276.966)',
        borderColor: 'oklch(51.1% 0.262 276.966)',
        borderWidth: 1
      }]
    }
  } catch (error) {
    console.error('Erreur lors du chargement des données:', error)
  }
}

onMounted(() => {
  loadSessionWeightData()
})
</script> 
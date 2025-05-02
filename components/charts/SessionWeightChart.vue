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
  workoutSessionId: {
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
    // 1. Récupérer toutes les séances effectuées pour ce workout_session_id
    const { data: sessions, error: sessionsError } = await supabase
      .from('performedsession')
      .select('id, started_at')
      .eq('workout_session_id', props.workoutSessionId)
      .eq('user_id', (await supabase.auth.getUser()).data.user.id)
      .order('started_at', { ascending: true })

    if (sessionsError) throw sessionsError
    if (!sessions?.length) return

    // 2. Pour chaque séance, récupérer tous les sets associés et calculer le volume
    const volumes = []
    const labels = []

    for (const session of sessions) {
      const { data: sets, error: setsError } = await supabase
        .from('exerciseset')
        .select('weight_kg, reps')
        .eq('performed_session_id', session.id)
        .eq('user_id', (await supabase.auth.getUser()).data.user.id)

      if (setsError) throw setsError

      const volume = sets.reduce((sum, set) => sum + set.weight_kg * set.reps, 0)
      volumes.push(volume)
      labels.push(new Date(session.started_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' }))
    }

    // 3. Mettre à jour les données du graphique
    chartData.value = {
      labels,
      datasets: [{
        label: 'Volume total',
        data: volumes,
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
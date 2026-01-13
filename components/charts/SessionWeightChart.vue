<template>
  <div class="bg-card rounded-lg">
    <div class="h-64">
      <Line
        v-if="chartData"
        :data="chartData"
        :options="chartOptions"
      />
    </div>
  </div>
</template>

<script setup>
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from 'chart.js'
import { ref, onMounted, computed } from 'vue'
import { useSupabaseClient } from '#imports'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend)

const props = defineProps({
  workoutSessionId: {
    type: String,
    required: true
  }
})

const supabase = useSupabaseClient()
const volumes = ref([])
const labels = ref([])

const chartData = computed(() => ({
  labels: labels.value,
  datasets: [{
    label: 'Volume total',
    data: volumes.value,
    borderColor: '#FE751C',
    backgroundColor: '#FE751C',
    tension: 0.4,
    pointRadius: 5,
    pointHoverRadius: 7,
    fill: false
  }]
}))

const chartOptions = computed(() => {
  const minVolume = volumes.value.length ? Math.min(...volumes.value) : 0
  const maxVolume = volumes.value.length ? Math.max(...volumes.value) : 100
  
  return {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      tooltip: {
        callbacks: {
          label: function(context) {
            return `Volume: ${context.parsed.y} kg`;
          }
        }
      },
      legend: {
        display: false
      }
    },
    scales: {
      y: {
        min: Math.max(0, minVolume - (maxVolume * 0.1)),
        max: maxVolume + (maxVolume * 0.1),
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
        },
        ticks: {
          maxRotation: 45,
          minRotation: 45
        }
      }
    }
  }
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
    const tempVolumes = []
    const tempLabels = []

    for (const session of sessions) {
      const { data: sets, error: setsError } = await supabase
        .from('exerciseset')
        .select('weight_kg, reps')
        .eq('performed_session_id', session.id)
        .eq('user_id', (await supabase.auth.getUser()).data.user.id)

      if (setsError) throw setsError

      const volume = sets.reduce((sum, set) => sum + set.weight_kg * set.reps, 0)
      tempVolumes.push(volume)
      tempLabels.push(new Date(session.started_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' }))
    }

    // 3. Mettre à jour les données du graphique
    volumes.value = tempVolumes
    labels.value = tempLabels
  } catch (error) {
    console.error('Erreur lors du chargement des données:', error)
  }
}

onMounted(() => {
  loadSessionWeightData()
})
</script> 
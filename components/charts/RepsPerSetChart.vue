<template>
  <div>
    <div class="h-64 overflow-x-auto chart-scroll-container">
      <div :style="{ minWidth: chartMinWidth }" class="h-full">
        <Bar
          v-if="chartData"
          :data="chartData"
          :options="chartOptions"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useSupabaseClient } from '#imports'
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const chartData = ref(null)
const chartOptions = ref(null)
const allData = ref([])
const chartMinWidth = ref('100%')

const loadData = async () => {
  try {
    const supabase = useSupabaseClient()
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) return

    const { data, error } = await supabase
      .from('exerciseset')
      .select('reps, created_at')
      .eq('exercise_id', props.exerciseId)
      .eq('user_id', user.id)
      .not('reps', 'is', null)
      .order('created_at', { ascending: true })

    if (error) throw error
    
    allData.value = data
    updateChart()
  } catch (e) {
    console.error('Erreur lors du chargement des données:', e)
  }
}

// Fonction pour mettre à jour le graphique
const updateChart = () => {
  const data = allData.value
  if (!data.length) {
    chartData.value = null
    return
  }

  // Créer un label pour chaque série (numérotation séquentielle globale)
  const labels = []
  const reps = []
  
  // Numéroter toutes les séries de manière séquentielle dans l'ordre chronologique
  data.forEach((set, index) => {
    const date = new Date(set.created_at).toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'short'
    })
    
    // Label: date + numéro de série global (S1, S2, S3, etc.)
    labels.push(`${date} S${index + 1}`)
    reps.push(set.reps)
  })

  // Calculer la largeur minimale du graphique (60px par barre)
  // Activer le scroll horizontal à partir de 20 barres
  const minWidthPerBar = 60
  const minBarsForScroll = 20
  if (labels.length >= minBarsForScroll) {
    const calculatedWidth = labels.length * minWidthPerBar
    chartMinWidth.value = `${calculatedWidth}px`
  } else {
    chartMinWidth.value = '100%'
  }

  const minReps = Math.min(...reps)
  const maxReps = Math.max(...reps)

  chartData.value = {
    labels: labels,
    datasets: [{
      label: 'Répétitions par série',
      data: reps,
      backgroundColor: '#FE751C',
      borderColor: '#FE751C',
      borderWidth: 1
    }]
  }
  
  chartOptions.value = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false
      },
      tooltip: {
        callbacks: {
          label: function(context) {
            return `Répétitions: ${context.parsed.y} reps`
          }
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        min: Math.max(0, minReps - 2),
        max: maxReps + 2,
        title: {
          display: true,
          text: 'Répétitions'
        }
      },
      x: {
        title: {
          display: true,
          text: 'Séries'
        },
        ticks: {
          maxRotation: 45,
          minRotation: 45,
          maxTicksLimit: 30,
          autoSkip: true,
          autoSkipPadding: 10
        }
      }
    }
  }
}

onMounted(loadData)
watch(() => props.exerciseId, loadData)
</script>

<style scoped>
.chart-scroll-container {
  scrollbar-width: thin;
  scrollbar-color: rgba(254, 117, 28, 0.3) transparent;
}

.chart-scroll-container::-webkit-scrollbar {
  height: 8px;
}

.chart-scroll-container::-webkit-scrollbar-track {
  background: transparent;
}

.chart-scroll-container::-webkit-scrollbar-thumb {
  background-color: rgba(254, 117, 28, 0.3);
  border-radius: 4px;
}

.chart-scroll-container::-webkit-scrollbar-thumb:hover {
  background-color: rgba(254, 117, 28, 0.5);
}
</style>

<template>
  <div>
    <div class="h-64 overflow-x-auto chart-scroll-container">
      <div :style="{ minWidth: chartMinWidth }" class="h-full">
        <Line
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
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend)

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const chartData = ref(null)
const chartOptions = ref(null)
const MAX_DATA_POINTS = 30
const allData = ref([])
const chartMinWidth = ref('100%')

// Fonction pour regrouper les données par période
const groupDataByPeriod = (data, period = 'week') => {
  data.sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
  
  const groups = {}
  
  data.forEach(item => {
    const date = new Date(item.created_at)
    let key
    
    if (period === 'week') {
      const day = date.getDay() || 7
      const firstDayOfWeek = new Date(date)
      firstDayOfWeek.setDate(date.getDate() - day + 1)
      key = firstDayOfWeek.toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: 'numeric' }) + ' (sem)'
    } else if (period === 'month') {
      key = date.toLocaleDateString('fr-FR', { year: 'numeric', month: 'long' })
    } else {
      key = date.toLocaleDateString('fr-FR')
    }
    
    // Pour les répétitions, on prend le total ou le maximum selon le contexte
    // Ici on prend le total de répétitions par période
    if (!groups[key]) {
      groups[key] = { total: 0, max: 0, count: 0 }
    }
    groups[key].total += item.reps || 0
    groups[key].max = Math.max(groups[key].max, item.reps || 0)
    groups[key].count += 1
  })
  
  // Retourner le total de répétitions par période
  return { 
    dates: Object.keys(groups), 
    reps: Object.values(groups).map(g => g.total)
  }
}

// Fonction pour mettre à jour le graphique
const updateChart = () => {
  const data = allData.value
  if (!data.length) {
    chartData.value = null
    return
  }
  
  let dates, reps
  
  // Regrouper par date et calculer le total de répétitions pour chaque jour
  const dailyReps = data.reduce((acc, item) => {
    const date = new Date(item.created_at).toLocaleDateString('fr-FR')
    if (!acc[date]) {
      acc[date] = { total: 0, max: 0 }
    }
    acc[date].total += item.reps || 0
    acc[date].max = Math.max(acc[date].max, item.reps || 0)
    return acc
  }, {})

  dates = Object.keys(dailyReps)
  reps = Object.values(dailyReps).map(d => d.total) // Total de répétitions par jour
  
  // Calculer la largeur minimale
  const minWidthPerPoint = 50
  const minPointsForScroll = 20
  if (dates.length >= minPointsForScroll) {
    chartMinWidth.value = `${dates.length * minWidthPerPoint}px`
  } else {
    chartMinWidth.value = '100%'
  }
  
  // Si trop de données, regrouper
  if (dates.length > MAX_DATA_POINTS) {
    const grouped = groupDataByPeriod(data, 'week')
    dates = grouped.dates
    reps = grouped.reps
    
    if (dates.length >= minPointsForScroll) {
      chartMinWidth.value = `${dates.length * minWidthPerPoint}px`
    } else {
      chartMinWidth.value = '100%'
    }
    
    if (dates.length > MAX_DATA_POINTS) {
      const groupedByMonth = groupDataByPeriod(data, 'month')
      dates = groupedByMonth.dates
      reps = groupedByMonth.reps
      
      if (dates.length >= minPointsForScroll) {
        chartMinWidth.value = `${dates.length * minWidthPerPoint}px`
      } else {
        chartMinWidth.value = '100%'
      }
    }
  }
  
  const minReps = Math.min(...reps)
  const maxReps = Math.max(...reps)
  
  chartData.value = {
    labels: dates,
    datasets: [{
      label: 'Répétitions totales',
      data: reps,
      borderColor: '#FE751C',
      backgroundColor: '#FE751C',
      tension: 0.4,
      pointRadius: 5,
      pointHoverRadius: 7
    }]
  }

  chartOptions.value = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      tooltip: {
        callbacks: {
          label: function(context) {
            return `Répétitions totales: ${context.parsed.y} reps`
          }
        }
      },
      legend: {
        display: false
      }
    },
    scales: {
      y: {
        min: Math.max(0, minReps - 5),
        max: maxReps + 5,
        title: {
          display: true,
          text: 'Répétitions'
        }
      },
      x: {
        title: {
          display: true,
          text: 'Date'
        },
        ticks: {
          maxRotation: 45,
          minRotation: 45,
          maxTicksLimit: 15,
          autoSkip: true,
          autoSkipPadding: 10
        }
      }
    }
  }
}

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

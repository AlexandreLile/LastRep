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
    
    // Pour le temps, on prend le total de secondes par période
    if (!groups[key]) {
      groups[key] = 0
    }
    // Si time_reps, multiplier par reps, sinon juste le temps
    const timeValue = (item.duration_seconds || 0) * (item.reps || 1)
    groups[key] += timeValue
  })
  
  return { 
    dates: Object.keys(groups), 
    times: Object.values(groups)
  }
}

// Fonction pour formater le temps en minutes:secondes
const formatTime = (seconds) => {
  const minutes = Math.floor(seconds / 60)
  const secs = seconds % 60
  if (minutes > 0) {
    return `${minutes}min ${secs}s`
  }
  return `${secs}s`
}

// Fonction pour mettre à jour le graphique
const updateChart = () => {
  const data = allData.value
  if (!data.length) {
    chartData.value = null
    return
  }
  
  let dates, times
  
  // Regrouper par date et calculer le total de temps pour chaque jour
  const dailyTimes = data.reduce((acc, item) => {
    const date = new Date(item.created_at).toLocaleDateString('fr-FR')
    if (!acc[date]) {
      acc[date] = 0
    }
    // Si time_reps, multiplier par reps, sinon juste le temps
    const timeValue = (item.duration_seconds || 0) * (item.reps || 1)
    acc[date] += timeValue
    return acc
  }, {})

  dates = Object.keys(dailyTimes)
  times = Object.values(dailyTimes) // Total de secondes par jour
  
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
    times = grouped.times
    
    if (dates.length >= minPointsForScroll) {
      chartMinWidth.value = `${dates.length * minWidthPerPoint}px`
    } else {
      chartMinWidth.value = '100%'
    }
    
    if (dates.length > MAX_DATA_POINTS) {
      const groupedByMonth = groupDataByPeriod(data, 'month')
      dates = groupedByMonth.dates
      times = groupedByMonth.times
      
      if (dates.length >= minPointsForScroll) {
        chartMinWidth.value = `${dates.length * minWidthPerPoint}px`
      } else {
        chartMinWidth.value = '100%'
      }
    }
  }
  
  const minTime = Math.min(...times)
  const maxTime = Math.max(...times)
  
  chartData.value = {
    labels: dates,
    datasets: [{
      label: 'Temps total',
      data: times,
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
            const seconds = context.parsed.y
            return `Temps total: ${formatTime(seconds)}`
          }
        }
      },
      legend: {
        display: false
      }
    },
    scales: {
      y: {
        min: Math.max(0, minTime - 10),
        max: maxTime + 10,
        title: {
          display: true,
          text: 'Temps (secondes)'
        },
        ticks: {
          callback: function(value) {
            return formatTime(value)
          }
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
      .select('duration_seconds, reps, created_at')
      .eq('exercise_id', props.exerciseId)
      .eq('user_id', user.id)
      .not('duration_seconds', 'is', null)
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

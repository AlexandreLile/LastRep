<template>
  <div>
    <ChartPeriodFilter v-model="selectedPeriod" />
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
import { ref, watch } from 'vue'
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from 'chart.js'
import ChartPeriodFilter from './ChartPeriodFilter.vue'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend)

const props = defineProps({
  sets: {
    type: Array,
    default: () => []
  }
})

const selectedPeriod = ref('week')

const chartData = ref(null)
const chartOptions = ref(null)
const MAX_DATA_POINTS = 30
const MAX_DISPLAY_POINTS = 50 // Maximum avec regroupement
const allData = ref([])

// Fonction pour regrouper les données par période
const groupDataByPeriod = (data, period = 'day') => {
  data.sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
  
  const groups = {}
  
  data.forEach(item => {
    const date = new Date(item.created_at)
    let key
    let periodDate // Date réelle pour le tri

    if (period === 'day') {
      const dayDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())
      periodDate = dayDate
      key = dayDate.toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: 'numeric' })
    } else if (period === 'week') {
      const day = date.getDay() || 7
      const firstDayOfWeek = new Date(date)
      firstDayOfWeek.setDate(date.getDate() - day + 1)
      firstDayOfWeek.setHours(0, 0, 0, 0) // Normaliser à minuit
      periodDate = firstDayOfWeek
      key = firstDayOfWeek.toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: 'numeric' }) + ' (sem)'
    } else if (period === 'month') {
      const firstDayOfMonth = new Date(date.getFullYear(), date.getMonth(), 1)
      periodDate = firstDayOfMonth
      key = date.toLocaleDateString('fr-FR', { year: 'numeric', month: 'long' })
    }
    
    // Pour le temps, on prend le total de secondes par période
    if (!groups[key]) {
      groups[key] = { time: 0, periodDate: periodDate }
    }
    // Si time_reps, multiplier par reps, sinon juste le temps
    const timeValue = (item.duration_seconds || 0) * (item.reps || 1)
    groups[key].time += timeValue
  })
  
  // Trier par date de période (chronologique)
  const sortedEntries = Object.entries(groups).sort((a, b) => 
    a[1].periodDate - b[1].periodDate
  )
  
  return { 
    dates: sortedEntries.map(([key]) => key), 
    times: sortedEntries.map(([, value]) => value.time)
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

  // Regrouper selon la période sélectionnée
  const grouped = groupDataByPeriod(data, selectedPeriod.value)
  dates = grouped.dates
  times = grouped.times

  // Pour la vue "jour", limiter aux 12 dernières séances
  if (selectedPeriod.value === 'day' && dates.length > 12) {
    dates = dates.slice(-12)
    times = times.slice(-12)
  }
  
  const minTime = Math.min(...times)
  const maxTime = Math.max(...times)
  
  // Calculer la taille des points selon le nombre de données
  const pointRadius = dates.length > 20 ? 3 : 5
  const pointHoverRadius = dates.length > 20 ? 5 : 7
  
  chartData.value = {
    labels: dates,
    datasets: [{
      label: 'Temps total',
      data: times,
      borderColor: '#FE751C',
      backgroundColor: '#FE751C',
      tension: 0.4,
      pointRadius: pointRadius,
      pointHoverRadius: pointHoverRadius
    }]
  }
  
  // Calculer le nombre optimal de ticks à afficher
  const optimalTicks = Math.min(dates.length, 15)

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
          maxRotation: dates.length > 15 ? 90 : 45,
          minRotation: dates.length > 15 ? 90 : 0,
          maxTicksLimit: optimalTicks,
          autoSkip: true,
          autoSkipPadding: 5,
          font: {
            size: dates.length > 20 ? 10 : 12
          }
        }
      }
    }
  }
}

watch(() => props.sets, (newSets) => {
  allData.value = (newSets || []).filter(s => s.duration_seconds != null)
  updateChart()
}, { immediate: true })
watch(selectedPeriod, () => {
  if (allData.value.length) {
    updateChart()
  }
})
</script>

<style scoped>
/* Styles supprimés - plus de scroll horizontal */
</style>

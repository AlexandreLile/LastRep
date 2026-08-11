<template>
  <div>
    <ChartPeriodFilter v-model="selectedPeriod" />
    <div class="h-64">
      <Bar
        v-if="chartData"
        :data="chartData"
        :options="chartOptions"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js'
import ChartPeriodFilter from './ChartPeriodFilter.vue'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const props = defineProps({
  sets: {
    type: Array,
    default: () => []
  }
})

const selectedPeriod = ref('week')

const chartData = ref(null)
const chartOptions = ref(null)
const allData = ref([])
const MAX_DISPLAY_POINTS = 30 // Nombre maximum de points à afficher sans regroupement

// Fonction pour formater le temps en minutes:secondes
const formatTime = (seconds) => {
  const minutes = Math.floor(seconds / 60)
  const secs = seconds % 60
  if (minutes > 0) {
    return `${minutes}min ${secs}s`
  }
  return `${secs}s`
}

// Fonction pour regrouper les séances par période (jour, semaine ou mois)
const groupSessionsByPeriod = (data, period) => {
  const sessions = {}
  
  // D'abord, grouper par séance (jour) et prendre le meilleur temps
  data.forEach(set => {
    const date = new Date(set.created_at)
    const dayKey = date.toLocaleDateString('fr-FR', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
    
    if (!sessions[dayKey]) {
      sessions[dayKey] = {
        date: date,
        maxTime: 0,
        totalSets: 0,
        allTimes: []
      }
    }
    
    const timeValue = set.duration_seconds || 0
    sessions[dayKey].maxTime = Math.max(sessions[dayKey].maxTime, timeValue)
    sessions[dayKey].totalSets += 1
    sessions[dayKey].allTimes.push(timeValue)
  })
  
  // Ensuite, regrouper les séances par période (jour, semaine ou mois)
  const periodGroups = {}
  
  Object.values(sessions).forEach(session => {
    const date = session.date
    let periodKey
    let periodDate

    if (period === 'day') {
      const dayDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())
      periodDate = dayDate
      periodKey = dayDate.toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: 'numeric' })
    } else if (period === 'week') {
      const day = date.getDay() || 7
      const firstDayOfWeek = new Date(date)
      firstDayOfWeek.setDate(date.getDate() - day + 1)
      firstDayOfWeek.setHours(0, 0, 0, 0)
      periodDate = firstDayOfWeek
      periodKey = firstDayOfWeek.toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: 'numeric' }) + ' (sem)'
    } else if (period === 'month') {
      const firstDayOfMonth = new Date(date.getFullYear(), date.getMonth(), 1)
      periodDate = firstDayOfMonth
      periodKey = date.toLocaleDateString('fr-FR', { year: 'numeric', month: 'long' })
    }
    
    if (!periodGroups[periodKey]) {
      periodGroups[periodKey] = {
        period: periodKey,
        periodDate,
        maxTime: 0,
        totalSessions: 0,
        totalSets: 0
      }
    }
    
    // Prendre le meilleur temps de toutes les séances de cette période
    periodGroups[periodKey].maxTime = Math.max(periodGroups[periodKey].maxTime, session.maxTime)
    periodGroups[periodKey].totalSessions += 1
    periodGroups[periodKey].totalSets += session.totalSets
  })
  
  return Object.values(periodGroups).sort((a, b) => a.periodDate - b.periodDate)
}

// Fonction pour mettre à jour le graphique
const updateChart = () => {
  const data = allData.value
  if (!data.length) {
    chartData.value = null
    return
  }

  // Regrouper les séances par période et prendre le meilleur temps de chaque période
  const periodGroups = groupSessionsByPeriod(data, selectedPeriod.value)
  
  // Limiter à 12 dernières séances en vue "jour", sinon max 30 périodes
  let displayPeriods = periodGroups
  if (selectedPeriod.value === 'day' && periodGroups.length > 12) {
    displayPeriods = periodGroups.slice(-12)
  } else if (periodGroups.length > MAX_DISPLAY_POINTS) {
    displayPeriods = periodGroups.slice(-MAX_DISPLAY_POINTS)
  }
  
  const labels = []
  const times = []
  const sessionDetails = []
  
  displayPeriods.forEach((group) => {
    labels.push(group.period)
    times.push(group.maxTime)
    sessionDetails.push({
      maxTime: group.maxTime,
      totalSessions: group.totalSessions,
      totalSets: group.totalSets
    })
  })
  
  if (!labels.length || !times.length) {
    chartData.value = null
    return
  }

  const minTime = Math.min(...times)
  const maxTime = Math.max(...times)
  
  // Calculer la taille des barres selon le nombre de données
  const barThickness = times.length > 20 ? 'flex' : undefined
  const maxBarThickness = times.length > 20 ? 20 : 40

  chartData.value = {
    labels: labels,
    datasets: [{
      label: 'Meilleur temps par série',
      data: times,
      backgroundColor: '#FE751C',
      borderColor: '#FE751C',
      borderWidth: 1,
      barThickness: barThickness,
      maxBarThickness: maxBarThickness,
      // Stocker les détails des sessions dans les données pour le tooltip
      sessionDetails: sessionDetails
    }]
  }
  
  // Calculer le nombre optimal de ticks à afficher
  const optimalTicks = Math.min(times.length, 15)
  
  const showGroupedInfo = (selectedPeriod.value === 'day' && periodGroups.length > 12) ||
    (selectedPeriod.value !== 'day' && periodGroups.length > MAX_DISPLAY_POINTS)

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
            // Afficher les détails du meilleur temps de la période
            const dataset = context.dataset
            if (dataset.sessionDetails && dataset.sessionDetails[context.dataIndex]) {
              const details = dataset.sessionDetails[context.dataIndex]
              return [
                `Meilleur temps: ${formatTime(details.maxTime)}`,
                `${details.totalSessions} séance(s)`,
                `${details.totalSets} séries au total`
              ]
            }
            return `Meilleur temps: ${formatTime(context.parsed.y)}`
          }
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
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
          text: showGroupedInfo && periodGroups.length !== null
            ? `${selectedPeriod.value === 'day' ? 'Séances' : selectedPeriod.value === 'week' ? 'Semaines' : 'Mois'} (${periodGroups.length} au total, ${labels.length} affichées)` 
            : (selectedPeriod.value === 'day' ? 'Séances' : selectedPeriod.value === 'week' ? 'Semaines' : 'Mois')
        },
        ticks: {
          maxRotation: times.length > 15 ? 90 : 45,
          minRotation: times.length > 15 ? 90 : 0,
          maxTicksLimit: optimalTicks,
          autoSkip: true,
          autoSkipPadding: 5,
          font: {
            size: times.length > 20 ? 10 : 12
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

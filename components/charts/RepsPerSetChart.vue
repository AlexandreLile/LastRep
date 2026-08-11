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
const MAX_DISPLAY_WITH_GROUPING = 50 // Maximum avec regroupement par session

// Fonction pour regrouper les données par session (jour)
const groupBySession = (data) => {
  const sessions = {}
  data.forEach((set, index) => {
    const date = new Date(set.created_at).toLocaleDateString('fr-FR')
    if (!sessions[date]) {
      sessions[date] = {
        date: date,
        sets: [],
        maxReps: 0,
        avgReps: 0,
        totalReps: 0
      }
    }
    sessions[date].sets.push(set.reps)
    sessions[date].totalReps += set.reps
    sessions[date].maxReps = Math.max(sessions[date].maxReps, set.reps)
  })
  
  // Calculer la moyenne pour chaque session
  Object.values(sessions).forEach(session => {
    session.avgReps = session.totalReps / session.sets.length
  })
  
  return Object.values(sessions).sort((a, b) => 
    new Date(a.date) - new Date(b.date)
  )
}

// Pas de filtre temporel - on utilise toutes les données et on regroupe par période

// Fonction pour mettre à jour le graphique avec les données préparées
const updateChartWithData = (labels, reps, sessionDetails, showGroupedInfo, totalSeries = null) => {
  if (!labels.length || !reps.length) {
    chartData.value = null
    return
  }

  const minReps = Math.min(...reps)
  const maxReps = Math.max(...reps)
  
  // Calculer la taille des barres selon le nombre de données
  const barThickness = reps.length > 20 ? 'flex' : undefined
  const maxBarThickness = reps.length > 20 ? 20 : 40

  chartData.value = {
    labels: labels,
    datasets: [{
      label: 'Répétitions par série',
      data: reps,
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
  const optimalTicks = Math.min(reps.length, 15)
  
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
            // Afficher les détails de la meilleure série de la période
            const dataset = context.dataset
            if (dataset.sessionDetails && dataset.sessionDetails[context.dataIndex]) {
              const details = dataset.sessionDetails[context.dataIndex]
              return [
                `Meilleure série: ${details.maxReps} reps`,
                `${details.totalSessions} séance(s)`,
                `${details.totalSets} séries au total`
              ]
            }
            return `Meilleure série: ${context.parsed.y} reps`
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
          text: showGroupedInfo && totalSeries !== null
            ? `${selectedPeriod.value === 'day' ? 'Séances' : selectedPeriod.value === 'week' ? 'Semaines' : 'Mois'} (${totalSeries} au total, ${labels.length} affichées)` 
            : (selectedPeriod.value === 'day' ? 'Séances' : selectedPeriod.value === 'week' ? 'Semaines' : 'Mois')
        },
        ticks: {
          maxRotation: reps.length > 15 ? 90 : 45,
          minRotation: reps.length > 15 ? 90 : 0,
          maxTicksLimit: optimalTicks,
          autoSkip: true,
          autoSkipPadding: 5,
          font: {
            size: reps.length > 20 ? 10 : 12
          }
        }
      }
    }
  }
}

// Fonction pour regrouper les séances par période (semaine ou mois)
const groupSessionsByPeriod = (data, period) => {
  const sessions = {}
  
  // D'abord, grouper par séance (jour) et prendre la meilleure série
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
        maxReps: 0,
        totalSets: 0,
        allReps: []
      }
    }
    
    sessions[dayKey].maxReps = Math.max(sessions[dayKey].maxReps, set.reps || 0)
    sessions[dayKey].totalSets += 1
    sessions[dayKey].allReps.push(set.reps || 0)
  })
  
  // Ensuite, regrouper les séances par période (semaine ou mois)
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
        maxReps: 0,
        totalSessions: 0,
        totalSets: 0
      }
    }
    
    // Prendre la meilleure série de toutes les séances de cette période
    periodGroups[periodKey].maxReps = Math.max(periodGroups[periodKey].maxReps, session.maxReps)
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

  // Regrouper les séances par période et prendre la meilleure série de chaque période
  const periodGroups = groupSessionsByPeriod(data, selectedPeriod.value)
  
  // Limiter à 12 dernières séances en vue "jour", sinon max 30 périodes
  let displayPeriods = periodGroups
  if (selectedPeriod.value === 'day' && periodGroups.length > 12) {
    displayPeriods = periodGroups.slice(-12)
  } else if (periodGroups.length > MAX_DISPLAY_POINTS) {
    displayPeriods = periodGroups.slice(-MAX_DISPLAY_POINTS)
  }
  
  const labels = []
  const reps = []
  const sessionDetails = []
  
  displayPeriods.forEach((group, index) => {
    labels.push(group.period)
    reps.push(group.maxReps)
    sessionDetails.push({
      maxReps: group.maxReps,
      totalSessions: group.totalSessions,
      totalSets: group.totalSets
    })
  })
  
  const showGroupedInfo = (selectedPeriod.value === 'day' && periodGroups.length > 12) ||
    (selectedPeriod.value !== 'day' && periodGroups.length > MAX_DISPLAY_POINTS)
  
  updateChartWithData(labels, reps, sessionDetails, showGroupedInfo, periodGroups.length)
}

watch(() => props.sets, (newSets) => {
  allData.value = (newSets || []).filter(s => s.reps != null)
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

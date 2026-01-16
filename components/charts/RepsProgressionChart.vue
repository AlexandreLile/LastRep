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
import { ref, onMounted, watch } from 'vue'
import { useSupabaseClient } from '#imports'
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from 'chart.js'
import ChartPeriodFilter from './ChartPeriodFilter.vue'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend)

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
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
    
    if (!groups[key]) {
      groups[key] = { total: 0, max: 0, count: 0, periodDate: periodDate }
    }
    groups[key].total += item.reps || 0
    groups[key].max = Math.max(groups[key].max, item.reps || 0)
    groups[key].count += 1
  })
  
  // Trier par date de période (chronologique)
  const sortedEntries = Object.entries(groups).sort((a, b) => 
    a[1].periodDate - b[1].periodDate
  )
  
  // Retourner le total par période dans l'ordre chronologique
  return { 
    dates: sortedEntries.map(([key]) => key), 
    reps: sortedEntries.map(([, value]) => value.total)
  }
}

// Fonction pour mettre à jour le graphique
const updateChart = () => {
  const data = allData.value
  if (!data.length) {
    chartData.value = null
    return
  }
  
  // Regrouper selon la période sélectionnée
  const grouped = groupDataByPeriod(data, selectedPeriod.value)
  let dates = grouped.dates
  let reps = grouped.reps

  // Pour la vue "jour", limiter aux 12 dernières séances
  if (selectedPeriod.value === 'day' && dates.length > 12) {
    dates = dates.slice(-12)
    reps = reps.slice(-12)
  }
  
  // Calculer la taille des points selon le nombre de données
  const pointRadius = dates.length > 20 ? 3 : 5
  const pointHoverRadius = dates.length > 20 ? 5 : 7
  
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
watch(selectedPeriod, () => {
  if (allData.value.length) {
    updateChart()
  }
})
</script>

<style scoped>
/* Styles supprimés - plus de scroll horizontal */
</style>

<template>
  <div>
    <ChartPeriodFilter v-model="selectedPeriod" />
    <div v-if="loading" class="h-64 flex items-center justify-center">
      <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
    </div>
    <div v-else-if="!chartData || !chartData.datasets[0].data.length" class="h-64 flex items-center justify-center text-muted-foreground">
      Aucune donnée disponible
    </div>
    <div v-else class="h-64">
      <Line
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

const selectedPeriod = ref('day') // Sera auto-ajusté
const chartData = ref(null)
const chartOptions = ref(null)
const allData = ref([])
const loading = ref(true)

const MAX_POINTS = 12 // Nombre max de points pour rester lisible

// Calcul du volume pour un set: poids × reps
const calculateVolume = (set) => {
  const weight = set.weight_kg || 0
  const reps = set.reps || 0
  return weight * reps
}

// Auto-sélection intelligente de la période selon l'historique
const autoSelectPeriod = (data) => {
  if (!data.length) return 'day'
  
  const dates = data.map(d => new Date(d.created_at))
  const minDate = new Date(Math.min(...dates))
  const maxDate = new Date(Math.max(...dates))
  const daysDiff = Math.ceil((maxDate - minDate) / (1000 * 60 * 60 * 24))
  
  // Compter le nombre de jours uniques d'entraînement
  const uniqueDays = new Set(data.map(d => 
    new Date(d.created_at).toLocaleDateString()
  )).size
  
  if (uniqueDays <= MAX_POINTS) {
    return 'day' // Peu de séances → afficher par jour
  } else if (daysDiff <= 90) {
    return 'week' // 2 semaines à 3 mois → par semaine
  } else {
    return 'month' // Plus de 3 mois → par mois
  }
}

// Regrouper les données par période et calculer le volume total
const groupDataByPeriod = (data, period = 'day') => {
  // Trier par date
  data.sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
  
  const groups = {}
  
  data.forEach(item => {
    const date = new Date(item.created_at)
    let key
    let periodDate

    if (period === 'day') {
      const dayDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())
      periodDate = dayDate
      key = dayDate.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })
    } else if (period === 'week') {
      const day = date.getDay() || 7
      const firstDayOfWeek = new Date(date)
      firstDayOfWeek.setDate(date.getDate() - day + 1)
      firstDayOfWeek.setHours(0, 0, 0, 0)
      periodDate = firstDayOfWeek
      key = firstDayOfWeek.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' }) + ' (sem)'
    } else if (period === 'month') {
      const firstDayOfMonth = new Date(date.getFullYear(), date.getMonth(), 1)
      periodDate = firstDayOfMonth
      key = date.toLocaleDateString('fr-FR', { month: 'short', year: '2-digit' })
    }
    
    const volume = calculateVolume(item)
    
    // Additionner le volume pour chaque période
    if (!groups[key]) {
      groups[key] = { volume: volume, periodDate: periodDate, sets: 1 }
    } else {
      groups[key].volume += volume
      groups[key].sets += 1
    }
  })
  
  // Trier par date de période (chronologique)
  const sortedEntries = Object.entries(groups).sort((a, b) => 
    a[1].periodDate - b[1].periodDate
  )
  
  return { 
    labels: sortedEntries.map(([key]) => key), 
    volumes: sortedEntries.map(([, value]) => Math.round(value.volume)),
    sets: sortedEntries.map(([, value]) => value.sets)
  }
}

const loadData = async () => {
  loading.value = true
  try {
    const supabase = useSupabaseClient()
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      loading.value = false
      return
    }

    const { data, error } = await supabase
      .from('exerciseset')
      .select('weight_kg, reps, created_at')
      .eq('exercise_id', props.exerciseId)
      .eq('user_id', user.id)
      .order('created_at', { ascending: true })

    if (error) throw error
    
    allData.value = data || []
    
    // Auto-sélection de la période optimale
    selectedPeriod.value = autoSelectPeriod(data || [])
    
    updateChart()
  } catch (e) {
    console.error('Erreur lors du chargement des données:', e)
  } finally {
    loading.value = false
  }
}

const updateChart = () => {
  const data = allData.value
  if (!data.length) {
    chartData.value = { labels: [], datasets: [{ data: [] }] }
    return
  }
  
  // Regrouper selon la période sélectionnée
  const grouped = groupDataByPeriod(data, selectedPeriod.value)
  let { labels, volumes, sets } = grouped

  // Limiter aux X derniers points pour rester lisible (toutes périodes)
  if (labels.length > MAX_POINTS) {
    labels = labels.slice(-MAX_POINTS)
    volumes = volumes.slice(-MAX_POINTS)
    sets = sets.slice(-MAX_POINTS)
  }
  
  // Calculer min/max pour l'échelle
  const maxVolume = Math.max(...volumes)
  const minVolume = Math.min(...volumes)
  
  // Calculer la taille des points selon le nombre de données
  const pointRadius = labels.length > 20 ? 3 : 5
  const pointHoverRadius = labels.length > 20 ? 5 : 7
  
  chartData.value = {
    labels: labels,
    datasets: [{
      label: 'Volume (kg)',
      data: volumes,
      borderColor: '#FE751C',
      backgroundColor: 'rgba(254, 117, 28, 0.1)',
      tension: 0.4,
      fill: true,
      pointRadius: pointRadius,
      pointHoverRadius: pointHoverRadius,
      pointBackgroundColor: '#FE751C'
    }]
  }

  chartOptions.value = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      tooltip: {
        callbacks: {
          label: function(context) {
            const index = context.dataIndex
            const volume = context.parsed.y
            const setCount = sets[index]
            return [
              `Volume: ${volume} kg`,
              `Séries: ${setCount}`
            ]
          }
        }
      },
      legend: {
        display: false
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        min: 0,
        max: Math.ceil(maxVolume * 1.1), // +10% de marge
        title: {
          display: true,
          text: 'Volume (kg)'
        },
        ticks: {
          callback: function(value) {
            return value >= 1000 ? (value / 1000).toFixed(1) + 'k' : value
          }
        }
      },
      x: {
        title: {
          display: true,
          text: 'Date'
        },
        ticks: {
          maxRotation: labels.length > 8 ? 45 : 0,
          minRotation: 0,
          font: {
            size: labels.length > 10 ? 10 : 12
          }
        }
      }
    }
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

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
      <Bar
        :data="chartData"
        :options="chartOptions"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useSupabaseClient } from '#imports'
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js'
import ChartPeriodFilter from './ChartPeriodFilter.vue'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const selectedPeriod = ref('week')
const chartData = ref(null)
const chartOptions = ref(null)
const allData = ref([])
const loading = ref(true)

// Calcul du volume pour un set: poids × reps
const calculateVolume = (set) => {
  const weight = set.weight_kg || 0
  const reps = set.reps || 0
  return weight * reps
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

  // Pour la vue "jour", limiter aux 12 dernières séances
  if (selectedPeriod.value === 'day' && labels.length > 12) {
    labels = labels.slice(-12)
    volumes = volumes.slice(-12)
    sets = sets.slice(-12)
  }
  
  // Calculer min/max pour l'échelle
  const maxVolume = Math.max(...volumes)
  const minVolume = Math.min(...volumes)
  
  chartData.value = {
    labels: labels,
    datasets: [{
      label: 'Volume (kg)',
      data: volumes,
      backgroundColor: '#FE751C',
      borderColor: '#FE751C',
      borderWidth: 1,
      borderRadius: 4,
      barThickness: labels.length > 10 ? 'flex' : 20
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

<template>
  <div>
    <!-- Filtres de période -->
    <div class="mb-4 flex flex-wrap gap-2">
      <Button
        v-for="period in periods"
        :key="period.value"
        :variant="selectedPeriod === period.value ? 'default' : 'outline'"
        size="sm"
        @click="selectedPeriod = period.value"
        class="text-xs"
      >
        {{ period.label }}
      </Button>
    </div>
    
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
import { ref, onMounted, watch, computed } from 'vue'
import { useSupabaseClient } from '#imports'
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from 'chart.js'
import { Button } from '@/components/ui/button'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend)

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const chartData = ref(null)
const chartOptions = ref(null)
const MAX_DATA_POINTS = 30 // Limite max de points à afficher
const selectedPeriod = ref('all')
const allData = ref([])

const periods = [
  { value: 'all', label: 'Tout' },
  { value: 'year', label: '1 an' },
  { value: 'month', label: '1 mois' },
  { value: 'week', label: '1 semaine' },
  { value: 'last30', label: '30 derniers' }
]

// Filtrer les données selon la période sélectionnée
const filteredData = computed(() => {
  if (!allData.value.length) return []
  
  const now = new Date()
  let startDate = null
  
  switch (selectedPeriod.value) {
    case 'week':
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
      break
    case 'month':
      startDate = new Date(now.getFullYear(), now.getMonth(), 1)
      break
    case 'year':
      startDate = new Date(now.getFullYear(), 0, 1)
      break
    case 'last30':
      // Retourner les 30 derniers points
      return allData.value.slice(-30)
    case 'all':
    default:
      return allData.value
  }
  
  if (startDate) {
    return allData.value.filter(item => new Date(item.created_at) >= startDate)
  }
  
  return allData.value
})

// Fonction pour regrouper les données par période (semaine ou mois)
const groupDataByPeriod = (data, period = 'week') => {
  // Trier les données par date croissante
  data.sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
  
  const groups = {}
  
  data.forEach(item => {
    const date = new Date(item.created_at)
    let key
    
    if (period === 'week') {
      // Obtenir le premier jour de la semaine (lundi)
      const day = date.getDay() || 7 // getDay() renvoie 0 pour dimanche, donc on convertit en 7
      const firstDayOfWeek = new Date(date)
      firstDayOfWeek.setDate(date.getDate() - day + 1)
      key = firstDayOfWeek.toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: 'numeric' }) + ' (sem)'
    } else if (period === 'month') {
      key = date.toLocaleDateString('fr-FR', { year: 'numeric', month: 'long' })
    } else {
      key = date.toLocaleDateString('fr-FR')
    }
    
    if (!groups[key] || item.weight_kg > groups[key]) {
      groups[key] = item.weight_kg
    }
  })
  
  return { dates: Object.keys(groups), weights: Object.values(groups) }
}

const loadData = async () => {
  try {
    const supabase = useSupabaseClient()
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) return

    const { data, error } = await supabase
      .from('exerciseset')
      .select('weight_kg, created_at')
      .eq('exercise_id', props.exerciseId)
      .eq('user_id', user.id)
      .order('created_at', { ascending: true })

    if (error) throw error
    
    // Stocker toutes les données
    allData.value = data
    
    updateChart()
    
    // Trouver le poids minimum et maximum
    const minWeight = Math.min(...weights)
    const maxWeight = Math.max(...weights)
    
    chartData.value = {
      labels: dates,
      datasets: [{
        label: 'Poids max',
        data: weights,
        borderColor: '#FE751C',
        backgroundColor: '#FE751C',
        tension: 0.4,
        pointRadius: 5,
        pointHoverRadius: 7
      }]
    }

    // Mettre à jour les options du graphique
    chartOptions.value = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        tooltip: {
          callbacks: {
            label: function(context) {
              return `Poids max: ${context.parsed.y} kg`;
            }
          }
        },
        legend: {
          display: false
        }
      },
      scales: {
        y: {
          min: Math.max(0, minWeight - 5),
          max: maxWeight + 5,
          title: {
            display: true,
            text: 'Poids (kg)'
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
  } catch (e) {
    console.error('Erreur lors du chargement des données:', e)
  }
}

// Fonction pour mettre à jour le graphique avec les données filtrées
const updateChart = () => {
  const data = filteredData.value
  if (!data.length) {
    chartData.value = null
    return
  }
  
  let dates, weights
  
  // Regrouper par date et trouver le poids maximum pour chaque jour
  const dailyMaxWeights = data.reduce((acc, item) => {
    const date = new Date(item.created_at).toLocaleDateString('fr-FR')
    if (!acc[date] || item.weight_kg > acc[date]) {
      acc[date] = item.weight_kg
    }
    return acc
  }, {})

  // Convertir en tableaux pour le graphique
  dates = Object.keys(dailyMaxWeights)
  weights = Object.values(dailyMaxWeights)
  
  // Si trop de données, regrouper par semaine ou par mois
  if (dates.length > MAX_DATA_POINTS) {
    // Si plus de MAX_DATA_POINTS jours, regrouper par semaine
    const grouped = groupDataByPeriod(data, 'week')
    dates = grouped.dates
    weights = grouped.weights
    
    // Si toujours trop, regrouper par mois
    if (dates.length > MAX_DATA_POINTS) {
      const groupedByMonth = groupDataByPeriod(data, 'month')
      dates = groupedByMonth.dates
      weights = groupedByMonth.weights
    }
  }
  
  // Trouver le poids minimum et maximum
  const minWeight = Math.min(...weights)
  const maxWeight = Math.max(...weights)
  
  chartData.value = {
    labels: dates,
    datasets: [{
      label: 'Poids max',
      data: weights,
      borderColor: '#FE751C',
      backgroundColor: '#FE751C',
      tension: 0.4,
      pointRadius: 5,
      pointHoverRadius: 7
    }]
  }

  // Mettre à jour les options du graphique
  chartOptions.value = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      tooltip: {
        callbacks: {
          label: function(context) {
            return `Poids max: ${context.parsed.y} kg`;
          }
        }
      },
      legend: {
        display: false
      }
    },
    scales: {
      y: {
        min: Math.max(0, minWeight - 5),
        max: maxWeight + 5,
        title: {
          display: true,
          text: 'Poids (kg)'
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
          maxTicksLimit: 15, // Limiter le nombre de dates affichées
          autoSkip: true,
          autoSkipPadding: 10
        }
      }
    }
  }
}

// Mettre à jour le graphique quand la période change
watch(selectedPeriod, () => {
  updateChart()
})

onMounted(loadData)
watch(() => props.exerciseId, loadData)
</script> 
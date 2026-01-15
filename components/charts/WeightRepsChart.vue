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
      <Bar
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
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js'
import { Button } from '@/components/ui/button'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const chartData = ref(null)
const chartOptions = ref(null)
const MAX_DATA_POINTS = 20 // Limite max de barres à afficher
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

const loadData = async () => {
  try {
    const supabase = useSupabaseClient()
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) return

    const { data, error } = await supabase
      .from('exerciseset')
      .select('weight_kg, reps, created_at')
      .eq('exercise_id', props.exerciseId)
      .eq('user_id', user.id)
      .order('created_at', { ascending: true })

    if (error) throw error
    
    // Stocker toutes les données
    allData.value = data
    
    updateChart()
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

  // Trouver le maximum de répétitions pour chaque poids
  const maxRepsByWeight = data.reduce((acc, curr) => {
    const weight = `${curr.weight_kg}kg`
    if (!acc[weight] || curr.reps > acc[weight]) {
      acc[weight] = curr.reps
    }
    return acc
  }, {})

  // Trier les poids par valeur numérique croissante
  let sortedWeights = Object.keys(maxRepsByWeight).sort((a, b) => {
    return parseFloat(a) - parseFloat(b)
  })

  // Si trop de données, regrouper les poids par incréments
  if (sortedWeights.length > MAX_DATA_POINTS) {
    const groupedMaxReps = {}
    const allWeights = sortedWeights.map(w => parseFloat(w))
    const minWeight = Math.min(...allWeights)
    const maxWeight = Math.max(...allWeights)
    const range = maxWeight - minWeight
    
    // Calculer l'incrément optimal
    let increment = 2.5 // Incrément minimum
    if (range / increment > MAX_DATA_POINTS) {
      // Augmenter l'incrément pour avoir moins de barres
      increment = Math.ceil(range / MAX_DATA_POINTS / 2.5) * 2.5
    }
    
    // Regrouper par incréments
    sortedWeights.forEach(weight => {
      const numWeight = parseFloat(weight)
      // Arrondir au plus proche multiple de l'incrément
      const groupKey = `${Math.round(numWeight / increment) * increment}kg`
      if (!groupedMaxReps[groupKey] || maxRepsByWeight[weight] > groupedMaxReps[groupKey]) {
        groupedMaxReps[groupKey] = maxRepsByWeight[weight]
      }
    })
    
    // Mettre à jour les données
    sortedWeights = Object.keys(groupedMaxReps).sort((a, b) => {
      return parseFloat(a) - parseFloat(b)
    })
    maxRepsByWeight = groupedMaxReps
  }

  chartData.value = {
    labels: sortedWeights,
    datasets: [{
      label: 'Répétitions max',
      data: sortedWeights.map(weight => maxRepsByWeight[weight]),
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
            return `Répétitions max: ${context.parsed.y}`;
          }
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        title: {
          display: true,
          text: 'Répétitions (max)'
        }
      },
      x: {
        title: {
          display: true,
          text: 'Poids (kg)'
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
<template>
  <div>
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
import { ref, onMounted, watch } from 'vue'
import { useSupabaseClient } from '#imports'
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, LineElement, PointElement, Title, Tooltip, Legend } from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, BarElement, LineElement, PointElement, Title, Tooltip, Legend)

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const chartData = ref(null)
const chartOptions = ref(null)
const MAX_DATA_POINTS = 25 // Limite max de barres avant regroupement
const MAX_DISPLAY_POINTS = 40 // Maximum avec regroupement
const allData = ref([])

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

// Limiter aux 12 dernières séances (jours distincts)
const limitToLast12Days = data => {
  const daySet = new Set()
  const sorted = [...data].sort((a, b) => new Date(a.created_at) - new Date(b.created_at))

  for (let i = sorted.length - 1; i >= 0; i--) {
    const date = new Date(sorted[i].created_at)
    const dayKey = new Date(date.getFullYear(), date.getMonth(), date.getDate()).toISOString()
    daySet.add(dayKey)
    if (daySet.size >= 12) break
  }

  return sorted.filter(item => {
    const date = new Date(item.created_at)
    const dayKey = new Date(date.getFullYear(), date.getMonth(), date.getDate()).toISOString()
    return daySet.has(dayKey)
  })
}

// Fonction pour mettre à jour le graphique
const updateChart = () => {
  const data = allData.value
  if (!data.length) {
    chartData.value = null
    return
  }

  const limitedData = limitToLast12Days(data)

  // Trouver le maximum de répétitions pour chaque poids
  let maxRepsByWeight = limitedData.reduce((acc, curr) => {
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

  // Si beaucoup de données, regrouper les poids par incréments plus grands
  if (sortedWeights.length > MAX_DISPLAY_POINTS) {
    // Plus de 40 poids différents : utiliser un incrément plus grand
    const allWeights = sortedWeights.map(w => parseFloat(w))
    const minWeight = Math.min(...allWeights)
    const maxWeight = Math.max(...allWeights)
    const range = maxWeight - minWeight
    
    // Incrément plus grand pour réduire le nombre de barres
    let increment = Math.ceil(range / MAX_DATA_POINTS / 5) * 5 // Arrondir à 5kg près
    
    const groupedMaxReps = {}
    sortedWeights.forEach(weight => {
      const numWeight = parseFloat(weight)
      const groupKey = `${Math.round(numWeight / increment) * increment}kg`
      if (!groupedMaxReps[groupKey] || maxRepsByWeight[weight] > groupedMaxReps[groupKey]) {
        groupedMaxReps[groupKey] = maxRepsByWeight[weight]
      }
    })
    
    sortedWeights = Object.keys(groupedMaxReps).sort((a, b) => {
      return parseFloat(a) - parseFloat(b)
    })
    maxRepsByWeight = groupedMaxReps
  } else if (sortedWeights.length > MAX_DATA_POINTS) {
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
  
  // Calculer la taille des barres selon le nombre de données
  const barThickness = sortedWeights.length > 20 ? 'flex' : undefined
  const maxBarThickness = sortedWeights.length > 20 ? 20 : 40

  chartData.value = {
    labels: sortedWeights,
    datasets: [{
      label: 'Répétitions max',
      data: sortedWeights.map(weight => maxRepsByWeight[weight]),
      backgroundColor: '#FE751C',
      borderColor: '#FE751C',
      borderWidth: 1,
      order: 1,
      barThickness: barThickness,
      maxBarThickness: maxBarThickness
    }, {
      type: 'line',
      label: 'Repère 10 reps',
      data: sortedWeights.map(() => 10),
      borderColor: '#22c55e',
      borderWidth: 3,
      order: 999,
      pointRadius: 0,
      pointHoverRadius: 0,
      fill: false
    }, {
      type: 'line',
      label: 'Repère 5 reps',
      data: sortedWeights.map(() => 5),
      borderColor: '#22c55e',
      borderWidth: 3,
      borderDash: [6, 6],
      order: 999,
      pointRadius: 0,
      pointHoverRadius: 0,
      fill: false
    }]
  }
  
  // Calculer le nombre optimal de ticks à afficher
  const optimalTicks = Math.min(sortedWeights.length, 15)
  
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
        },
        ticks: {
          maxRotation: sortedWeights.length > 15 ? 90 : 45,
          minRotation: sortedWeights.length > 15 ? 90 : 0,
          maxTicksLimit: optimalTicks,
          autoSkip: true,
          autoSkipPadding: 5,
          font: {
            size: sortedWeights.length > 20 ? 10 : 12
          }
        }
      }
    }
  }
}

// Mettre à jour le graphique quand la période change
onMounted(loadData)
watch(() => props.exerciseId, loadData)
</script>

<style scoped>
/* Styles supprimés - plus de scroll horizontal */
</style> 
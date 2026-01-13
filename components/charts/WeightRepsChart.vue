<template>
  <div class="h-64">
    <Bar
      v-if="chartData"
      :data="chartData"
      :options="{
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
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
      }"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useSupabaseClient } from '#imports'
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const chartData = ref(null)
const MAX_DATA_POINTS = 20 // Limite max de barres à afficher

const loadData = async () => {
  try {
    const supabase = useSupabaseClient()
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) return

    const { data, error } = await supabase
      .from('exerciseset')
      .select('weight_kg, reps')
      .eq('exercise_id', props.exerciseId)
      .eq('user_id', user.id)
      .order('weight_kg', { ascending: true })

    if (error) throw error

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
  } catch (e) {
    console.error('Erreur lors du chargement des données:', e)
  }
}

onMounted(loadData)
watch(() => props.exerciseId, loadData)
</script> 
<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg p-6">
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Progression du poids</h3>
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

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend)

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const chartData = ref(null)
const chartOptions = ref(null)

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

    const weights = data.map(item => item.weight_kg)
    const dates = data.map(item => new Date(item.created_at).toLocaleDateString('fr-FR'))
    
    // Trouver le poids minimum et maximum
    const minWeight = Math.min(...weights)
    const maxWeight = Math.max(...weights)
    
    chartData.value = {
      labels: dates,
      datasets: [{
        label: 'Poids',
        data: weights,
        borderColor: 'oklch(51.1% 0.262 276.966)',
        backgroundColor: 'oklch(51.1% 0.262 276.966)',
        tension: 0.4
      }]
    }

    // Mettre à jour les options du graphique
    chartOptions.value = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        }
      },
      scales: {
        y: {
          min: Math.max(0, minWeight - 5), // Commencer 5kg en dessous du poids minimum
          max: maxWeight + 5, // Finir 5kg au-dessus du poids maximum
          title: {
            display: true,
            text: 'Poids (kg)'
          }
        },
        x: {
          title: {
            display: true,
            text: 'Date'
          }
        }
      }
    }
  } catch (e) {
    console.error('Erreur lors du chargement des données:', e)
  }
}

onMounted(loadData)
watch(() => props.exerciseId, loadData)
</script> 
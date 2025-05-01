<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg p-6">
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Poids vs Répétitions</h3>
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
                text: 'Répétitions'
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

    // Grouper les répétitions par poids
    const groupedData = data.reduce((acc, curr) => {
      const weight = `${curr.weight_kg}kg`
      if (!acc[weight]) {
        acc[weight] = 0
      }
      acc[weight] += curr.reps
      return acc
    }, {})

    chartData.value = {
      labels: Object.keys(groupedData),
      datasets: [{
        label: 'Répétitions',
        data: Object.values(groupedData),
        backgroundColor: 'oklch(51.1% 0.262 276.966)',
        borderColor: 'oklch(51.1% 0.262 276.966)',
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
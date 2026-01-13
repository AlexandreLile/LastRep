<template>
  <div class="h-64">
    <Line
      v-if="chartData"
      :data="chartData"
      :options="chartOptions"
    />
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
const MAX_DATA_POINTS = 30 // Limite max de points à afficher

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
            minRotation: 45
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
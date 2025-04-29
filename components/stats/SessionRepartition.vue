<template>
    <div class="relative w-full rounded-2xl p-6">
        <div class="max-w-full py-10 sm:max-w-2xl lg:max-w-4xl md:items-start mx-auto flex flex-col justify-center items-center md:items-start">
            <h2 class="text-2xl font-semibold text-left mb-4">Répartition des séances</h2>
            <div class="w-full h-full flex flex-col md:flex-row items-center md:items-start justify-center md:justify-start gap-8">
                <div class="w-[300px] h-[300px] md:w-[400px] md:h-[400px]">
                    <Doughnut
                        :data="chartData"
                        :options="chartOptions"
                    />
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Doughnut } from 'vue-chartjs'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
import { useSupabaseClient } from '#imports'
import { ref, onMounted } from 'vue'

ChartJS.register(ArcElement, Tooltip, Legend)

const supabase = useSupabaseClient()
const chartData = ref({
    labels: [],
    datasets: [{
        data: [],
        backgroundColor: [
            'oklch(54.6% 0.245 262.881)', 
            'oklch(59.1% 0.293 322.896)', 
            'oklch(55.8% 0.288 302.321)', 
            'oklch(59.2% 0.249 0.584)', 
            'oklch(51.1% 0.262 276.966)',
        ],
        borderWidth: 0,
        cutout: '75%',
    }]
})

const loadMuscleData = async () => {
    try {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) return

        // Récupérer toutes les séances de l'utilisateur
        const { data: workouts, error: workoutsError } = await supabase
            .from('workoutsession')
            .select('id')
            .eq('user_id', user.id)

        if (workoutsError) throw workoutsError

        // Récupérer tous les exercices de toutes les séances
        const { data: workoutExercises, error: exercisesError } = await supabase
            .from('workoutexercise')
            .select(`
                id,
                exercise (
                    primary_muscle
                )
            `)
            .in('session_id', workouts.map(w => w.id))

        if (exercisesError) throw exercisesError

        // Compter les occurrences de chaque muscle
        const muscleCount = {}
        workoutExercises.forEach(we => {
            const muscle = we.exercise?.primary_muscle
            if (muscle) {
                muscleCount[muscle] = (muscleCount[muscle] || 0) + 1
            }
        })

        // Mettre à jour les données du graphique
        chartData.value = {
            labels: Object.keys(muscleCount),
            datasets: [{
                data: Object.values(muscleCount),
                backgroundColor: [
                    'oklch(54.6% 0.245 262.881)', 
                    'oklch(59.1% 0.293 322.896)', 
                    'oklch(55.8% 0.288 302.321)', 
                    'oklch(59.2% 0.249 0.584)', 
                    'oklch(51.1% 0.262 276.966)',
                ],
                borderWidth: 0,
                cutout: '75%',
            }]
        }
    } catch (error) {
        console.error('Erreur lors du chargement des données musculaires:', error)
    }
}

onMounted(() => {
    loadMuscleData()
})

const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            position: 'right',
            align: 'center',
            labels: {
                color: 'hsl(var(--foreground))',
                font: {
                    size: 14,
                    weight: 'bold',
                },
                padding: 20,
                usePointStyle: true,
                pointStyle: 'circle',
                boxWidth: 10,
                boxHeight: 10,
            },
        },
        tooltip: {
            callbacks: {
                label: function(context) {
                    const label = context.label || ''
                    const value = context.raw || 0
                    const total = context.dataset.data.reduce((a, b) => a + b, 0)
                    const percentage = Math.round((value / total) * 100)
                    return `${label}: ${value} séances (${percentage}%)`
                }
            },
            backgroundColor: 'rgba(255, 255, 255, 1)',
            titleColor: 'hsl(var(--foreground))',
            bodyColor: 'hsl(var(--foreground))',
            borderColor: 'hsl(var(--border))',
            borderWidth: 1,
            titleFont: {
                weight: 'bold',
            },
            bodyFont: {
                weight: 'bold',
            },
        }
    }
}
</script>

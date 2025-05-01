<template>
    <div class="space-y-6 p-4 sm:p-6">
        <div class="space-y-2">
            <h3 class="text-lg font-medium">Répartition des séances</h3>
            <p class="text-sm text-muted-foreground">Distribution de vos séances par groupe musculaire</p>
        </div>

        <div class="flex flex-col items-center justify-center space-y-4">
            <div class="w-full max-w-[300px] h-[250px] sm:h-[300px] md:max-w-[400px] md:h-[400px]">
                <Doughnut
                    :data="chartData"
                    :options="chartOptions"
                />
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
        cutout: '80%',
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
                cutout: '80%',
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
            position: 'bottom',
            align: 'center',
            labels: {
                color: 'hsl(var(--foreground))',
                font: {
                    size: 20,
                    weight: 'medium',
                },
                padding: 16,
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
            backgroundColor: 'hsl(var(--background))',
            titleColor: 'hsl(var(--foreground))',
            bodyColor: 'hsl(var(--foreground))',
            borderColor: 'hsl(var(--border))',
            borderWidth: 1,
            titleFont: {
                weight: 'medium',
            },
            bodyFont: {
                weight: 'medium',
            },
        }
    }
}
</script>

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
            '#3B82F6', // Bleu vif
            '#10B981', // Vert émeraude
            '#F59E0B', // Orange
            '#EF4444', // Rouge
            '#8B5CF6', // Violet
            '#EC4899', // Rose
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
            labels: Object.keys(muscleCount).map(muscle => {
                // Traduire les noms des muscles en français
                const translations = {
                    'chest': 'Pectoraux',
                    'back': 'Dos',
                    'shoulders': 'Épaules',
                    'legs': 'Jambes',
                    'arms': 'Bras',
                    'abs': 'Abdominaux'
                }
                return translations[muscle] || muscle
            }),
            datasets: [{
                data: Object.values(muscleCount),
                backgroundColor: [
                    '#3B82F6', // Bleu vif
                    '#10B981', // Vert émeraude
                    '#F59E0B', // Orange
                    '#EF4444', // Rouge
                    '#8B5CF6', // Violet
                    '#EC4899', // Rose
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
                color: '#F2F2F2',
                font: {
                    size: 15,
                    weight: 'bold',
                    family: 'system-ui, -apple-system, sans-serif',
                },
                padding: 20,
                usePointStyle: true,
                pointStyle: 'circle',
                boxWidth: 14,
                boxHeight: 14,
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
            backgroundColor: 'white',
            titleColor: 'black',
            bodyColor: 'black',
            borderColor: 'hsl(var(--border))',
            borderWidth: 1,
            titleFont: {
                size: 14,
                weight: 'bold',
            },
            bodyFont: {
                size: 14,
                weight: 'medium',
            },
            padding: 12,
            displayColors: true,
            boxPadding: 6,
            boxWidth: 12,
            boxHeight: 12,
        }
    }
}
</script>

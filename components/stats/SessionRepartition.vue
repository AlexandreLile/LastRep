<template>
    <div class="rounded-2xl p-6">
        <h2 class="text-2xl font-semibold text-center mb-5">Répartition des séances</h2>
        <div class="w-full h-full ">
            <div class="w-max-[300px]">
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

ChartJS.register(ArcElement, Tooltip, Legend)

// Données factices pour le moment
const chartData = {
    labels: ['Pectoraux', 'Dos', 'Jambes', 'Épaules', 'Bras'],
    datasets: [
        {
            data: [12, 19, 8, 15, 10],
            backgroundColor: [
                'oklch(54.6% 0.245 262.881)', 
                'oklch(59.1% 0.293 322.896)', 
                'oklch(55.8% 0.288 302.321)', 
                'oklch(59.2% 0.249 0.584)', 
                'oklch(51.1% 0.262 276.966)',
            ],
          
            borderWidth: 0,
            cutout: '75%',
        },
    ],
}

const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            position: 'bottom',
            labels: {
                color: 'hsl(var(--foreground))',
                font: {
                    size: 12,
                    weight: 'bold',
                },
                padding: 15,
                usePointStyle: true,
                pointStyle: 'circle',
                boxWidth: 8,
                boxHeight: 8,
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

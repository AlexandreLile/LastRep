<template>
  <div class="w-fit">
    <div class="flex items-center justify-between mb-2">
      <button 
        @click="previousMonth" 
        class="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
      >
        <ChevronLeft class="h-4 w-4" />
      </button>
      <h3 class="text-sm font-medium">
        {{ formatMonthYear }}
      </h3>
      <button 
        @click="nextMonth" 
        class="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
      >
        <ChevronRight class="h-4 w-4" />
      </button>
    </div>

    <div class="grid grid-cols-7 gap-1 text-xs">
      <!-- En-têtes des jours -->
      <div 
        v-for="day in ['L', 'M', 'M', 'J', 'V', 'S', 'D']" 
        :key="day"
        class="text-center font-medium text-gray-500 dark:text-gray-400"
      >
        {{ day }}
      </div>

      <!-- Jours du mois -->
      <div 
        v-for="day in monthDays" 
        :key="day.date"
        class="aspect-square"
      >
        <div 
          class="w-full h-full flex items-center justify-center"
          :class="{
            'cursor-pointer': day.hasTraining
          }"
          @click="day.hasTraining ? selectDay(day) : null"
        >
          <span 
            class="w-7 h-7 flex items-center justify-center rounded-md"
            :class="{
              'bg-primary text-primary-foreground': day.hasTraining,
              'text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800': !day.hasTraining && day.isCurrentMonth,
              'text-gray-400 dark:text-gray-500': !day.isCurrentMonth
            }"
          >
            {{ day.date.getDate() }}
          </span>
        </div>
      </div>
    </div>

    <Dialog :open="!!selectedDay" @update:open="selectedDay = null">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{{ formatDate(selectedDay?.date) }}</DialogTitle>
        </DialogHeader>
        <div class="space-y-4">
          <div 
            v-for="session in selectedDay?.sessions" 
            :key="session.id" 
            class="border-b dark:border-gray-700 pb-4 last:border-0"
          >
            <h4 class="font-medium">{{ session.name }}</h4>
            <div class="mt-2 space-y-1">
              <p class="text-sm text-gray-500 dark:text-gray-400">
                Durée : {{ formatDuration(session.duration) }}
              </p>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  </div>
</template>

<script setup>

import { ChevronLeft, ChevronRight } from 'lucide-vue-next'



const supabase = useSupabaseClient()
const currentDate = ref(new Date())
const selectedDay = ref(null)
const trainingSessions = ref([])

const monthDays = computed(() => {
  const days = []
  const year = currentDate.value.getFullYear()
  const month = currentDate.value.getMonth()
  
  // Premier jour du mois
  const firstDay = new Date(year, month, 1)
  // Dernier jour du mois
  const lastDay = new Date(year, month + 1, 0)
  
  // Jours du mois précédent
  const firstDayOfWeek = firstDay.getDay() || 7 // Convertir dimanche (0) en 7
  for (let i = firstDayOfWeek - 1; i > 0; i--) {
    const date = new Date(year, month, -i + 1)
    days.push({
      date,
      isCurrentMonth: false,
      hasTraining: false
    })
  }
  
  // Jours du mois courant
  for (let i = 1; i <= lastDay.getDate(); i++) {
    const date = new Date(year, month, i)
    const sessions = trainingSessions.value.filter(s => 
      new Date(s.created_at).toDateString() === date.toDateString()
    )
    
    days.push({
      date,
      isCurrentMonth: true,
      hasTraining: sessions.length > 0,
      sessions
    })
  }
  
  // Jours du mois suivant
  const remainingDays = 42 - days.length // 6 semaines * 7 jours
  for (let i = 1; i <= remainingDays; i++) {
    const date = new Date(year, month + 1, i)
    days.push({
      date,
      isCurrentMonth: false,
      hasTraining: false
    })
  }
  
  return days
})

const formatMonthYear = computed(() => {
  return currentDate.value.toLocaleDateString('fr-FR', {
    month: 'long',
    year: 'numeric'
  })
})

const loadTrainingSessions = async () => {
  try {
    const user = (await supabase.auth.getUser()).data.user
    if (!user) return

    const { data, error } = await supabase
      .from('performedsession')
      .select(`
        id,
        started_at,
        ended_at,
        workout_session_id,
        workout:workoutsession!left (
          title
        )
      `)
      .eq('user_id', user.id)
      .order('started_at', { ascending: false })

    if (error) throw error

    trainingSessions.value = data
      .filter(session => session.workout) // Ne garder que les séances qui ont encore un workout
      .map(session => ({
        id: session.id,
        created_at: session.started_at,
        duration: session.ended_at ? 
          Math.round((new Date(session.ended_at) - new Date(session.started_at)) / 60000) : 
          0,
        name: session.workout.title
      }))
  } catch (e) {
    console.error('Erreur lors du chargement des séances:', e)
  }
}

const previousMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() - 1, 1)
}

const nextMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() + 1, 1)
}

const selectDay = (day) => {
  selectedDay.value = day
}

const formatDate = (date) => {
  if (!date) return ''
  return date.toLocaleDateString('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

const formatDuration = (minutes) => {
  if (!minutes) return '0 min'
  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60
  if (hours > 0) {
    return `${hours}h ${remainingMinutes} min`
  }
  return `${minutes} min`
}

const handleDayClick = (date) => {
  const day = monthDays.value.find(d => d.date.toDateString() === date.toDateString())
  if (day) {
    selectDay(day)
  }
}

onMounted(loadTrainingSessions)
</script> 
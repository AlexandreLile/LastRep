<template>
  <div>
    <!-- Temps total hebdomadaire -->
    <div class="mb-8">
      <div class="mb-1 text-sm text-muted-foreground font-medium">Cette semaine</div>
      <p class="text-3xl font-bold text-gray-900">{{ formatTotalDuration }}</p>
      
      <!-- Barres de temps par jour -->
      <div class="grid grid-cols-7 gap-3 mt-6">
        <div v-for="(day, index) in weekDays" :key="index" class="flex flex-col items-center">
          <div class="h-28 w-2 bg-gray-100 rounded-full relative mb-2">
            <div 
              class="absolute bottom-0 w-full rounded-full transition-all duration-300 bg-primary"
              :style="{ height: `${getHeightPercentage(day.duration)}%` }"
            ></div>
          </div>
          <span class="text-xs font-medium text-gray-600">{{ day.label }}</span>
          <span v-if="day.duration > 0" class="text-xs text-gray-500 mt-1">
            {{ formatShortDuration(day.duration) }}
          </span>
        </div>
      </div>
    </div>

    <!-- Séparateur -->
    <div class="h-px bg-gray-200 my-6"></div>

    <!-- Calendrier -->
    <div>
      <div class="flex items-center justify-between mb-6">
        <button 
          @click="previousMonth" 
          class="p-2 rounded-md hover:bg-gray-100 transition-colors"
        >
          <ChevronLeft class="h-5 w-5" />
        </button>
        <h3 class="text-base font-semibold text-gray-900">
          {{ formatMonthYear }}
        </h3>
        <button 
          @click="nextMonth" 
          class="p-2 rounded-md hover:bg-gray-100 transition-colors"
        >
          <ChevronRight class="h-5 w-5" />
        </button>
      </div>

      <div class="grid grid-cols-7 gap-1">
        <!-- En-têtes des jours -->
        <div 
          v-for="day in ['L', 'M', 'M', 'J', 'V', 'S', 'D']" 
          :key="day"
          class="text-center font-medium text-gray-500 text-sm py-2"
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
              'cursor-pointer hover:bg-gray-50': day.hasTraining
            }"
            @click="day.hasTraining ? selectDay(day) : null"
          >
            <span 
              class="w-8 h-8 flex items-center justify-center rounded-full text-sm"
              :class="{
                'bg-primary text-white font-medium': day.hasTraining,
                'text-gray-900': !day.hasTraining && day.isCurrentMonth,
                'text-gray-400': !day.isCurrentMonth
              }"
            >
              {{ day.date.getDate() }}
            </span>
          </div>
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
              <p class="text-sm text-gray-500">
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
import { ChevronLeft, ChevronRight, Clock } from 'lucide-vue-next'

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

// Nouveau computed pour les données de la semaine
const weekDays = computed(() => {
  const today = new Date()
  const days = []
  const dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
  
  // Trouver le lundi de la semaine
  const monday = new Date(today)
  monday.setDate(today.getDate() - (today.getDay() || 7) + 1)
  
  // Créer les données pour chaque jour
  for (let i = 0; i < 7; i++) {
    const date = new Date(monday)
    date.setDate(monday.getDate() + i)
    
    // Trouver les sessions du jour
    const daySessions = trainingSessions.value.filter(session => 
      new Date(session.created_at).toDateString() === date.toDateString()
    )
    
    // Calculer la durée totale du jour
    const totalDuration = daySessions.reduce((total, session) => total + session.duration, 0)
    
    days.push({
      date,
      label: dayLabels[i],
      duration: totalDuration
    })
  }
  
  return days
})

// Calculer le temps total de la semaine
const formatTotalDuration = computed(() => {
  const totalMinutes = weekDays.value.reduce((total, day) => total + day.duration, 0)
  const hours = Math.floor(totalMinutes / 60)
  const minutes = totalMinutes % 60
  return `${hours} h ${minutes} m`
})

// Fonction pour calculer le pourcentage de hauteur de la barre
const getHeightPercentage = (duration) => {
  const maxDuration = Math.max(...weekDays.value.map(day => day.duration))
  if (maxDuration === 0) return 0
  return (duration / maxDuration) * 100
}

// Version courte du format de durée
const formatShortDuration = (minutes) => {
  if (minutes < 60) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60
  return remainingMinutes > 0 ? `${hours}h${remainingMinutes}` : `${hours}h`
}

onMounted(loadTrainingSessions)
</script>

<style scoped>
.bg-primary {
  transition: height 0.3s ease-in-out;
}
</style> 
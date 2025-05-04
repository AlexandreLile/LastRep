<template>
  <div class="relative">
    <!-- En-tête amélioré -->
    <div class="mb-8 bg-white rounded-xl p-6">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
          <History class="h-6 w-6 text-primary" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Historique</h2>
          <p class="text-sm text-muted-foreground">Consultez l'historique de vos séances d'entraînement</p>
        </div>
      </div>
    </div>

    <!-- État de chargement -->
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <!-- Message d'erreur -->
    <div v-else-if="error" class="text-red-500 text-center py-8 bg-white rounded-xl p-6">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4 text-red-500" />
      {{ error }}
    </div>

    <!-- Contenu principal quand il y a des sessions -->
    <div v-else class="space-y-6">
      <!-- Filtres de période -->
      <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Filter class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Filtrer par période</h3>
            <p class="text-sm text-muted-foreground">Sélectionnez une période pour filtrer vos séances</p>
          </div>
        </div>

        <Tabs default-value="all" class="w-full" v-model="currentFilter">
          <div class="overflow-x-auto px-2 pb-2 -mx-2">
            <TabsList class="flex w-full min-w-max space-x-2">
              <TabsTrigger 
                value="all" 
                class="whitespace-nowrap data-[state=active]:bg-primary data-[state=active]:text-white"
              >
                Toutes
              </TabsTrigger>
              <TabsTrigger 
                value="week" 
                class="whitespace-nowrap data-[state=active]:bg-primary data-[state=active]:text-white"
              >
                Cette semaine
              </TabsTrigger>
              <TabsTrigger 
                value="month" 
                class="whitespace-nowrap data-[state=active]:bg-primary data-[state=active]:text-white"
              >
                Ce mois
              </TabsTrigger>
              <TabsTrigger 
                value="year" 
                class="whitespace-nowrap data-[state=active]:bg-primary data-[state=active]:text-white"
              >
                Cette année
              </TabsTrigger>
            </TabsList>
          </div>
        </Tabs>
      </div>

      <!-- Aucune session -->
      <div v-if="filteredSessions.length === 0" class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-white rounded-xl p-6">
        <Calendar class="w-16 h-16 text-muted-foreground/30" />
        <p class="text-center text-muted-foreground">
          Aucune séance d'entraînement pour cette période
        </p>
        <Button @click="navigateTo('/seances')" class="flex items-center gap-2">
          <Plus class="h-4 w-4" />
          Commencer une séance
        </Button>
      </div>

      <!-- Liste des sessions -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <SessionHistoryCard 
          v-for="session in filteredSessions" 
          :key="session.id" 
          :session="session"
          @delete="handleDeleteSession"
          class="animate-fade-in"
        />
      </div>

      <!-- Statistiques -->
      <div v-if="filteredSessions.length > 0" class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <BarChart class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Statistiques</h3>
            <p class="text-sm text-muted-foreground">Récapitulatif de vos performances</p>
          </div>
        </div>
        
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div class="bg-gray-50 rounded-xl p-4">
            <div class="flex items-center gap-3 mb-2">
              <div class="p-2 rounded-full bg-primary/10">
                <Calendar class="h-4 w-4 text-primary" />
              </div>
              <span class="text-sm font-medium">Séances</span>
            </div>
            <p class="text-3xl font-bold text-primary">{{ filteredSessions.length }}</p>
          </div>
          
          <div class="bg-gray-50 rounded-xl p-4">
            <div class="flex items-center gap-3 mb-2">
              <div class="p-2 rounded-full bg-primary/10">
                <Clock class="h-4 w-4 text-primary" />
              </div>
              <span class="text-sm font-medium">Durée moyenne</span>
            </div>
            <p class="text-3xl font-bold text-primary">{{ averageDuration }}</p>
          </div>
          
          <div class="bg-gray-50 rounded-xl p-4">
            <div class="flex items-center gap-3 mb-2">
              <div class="p-2 rounded-full bg-primary/10">
                <Dumbbell class="h-4 w-4 text-primary" />
              </div>
              <span class="text-sm font-medium">Exercices totaux</span>
            </div>
            <p class="text-3xl font-bold text-primary">{{ totalExercisesCount }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useSessionHistory } from '~/composables/useSessionHistory'
import SessionHistoryCard from '~/components/sessions/SessionHistoryCard.vue'
import { Button } from '@/components/ui/button'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  Calendar, 
  History, 
  AlertTriangle, 
  Filter, 
  Plus, 
  BarChart,
  Clock,
  Dumbbell
} from 'lucide-vue-next'

const { sessions, loading, error, loadSessions, deleteSession } = useSessionHistory()
const currentFilter = ref('all')

// Filtrer les sessions par période
const filteredSessions = computed(() => {
  if (currentFilter.value === 'all') {
    return sessions.value
  }
  
  const now = new Date()
  let startDate = new Date()
  
  switch (currentFilter.value) {
    case 'week':
      // Get first day of current week (Sunday = 0, Monday = 1, etc.)
      const firstDayOfWeek = 1 // Monday
      const dayOfWeek = now.getDay() || 7 // Convert Sunday from 0 to 7
      const diff = dayOfWeek >= firstDayOfWeek ? dayOfWeek - firstDayOfWeek : 6 - firstDayOfWeek + dayOfWeek
      startDate.setDate(now.getDate() - diff)
      break
    case 'month':
      // First day of current month
      startDate.setDate(1)
      break
    case 'year':
      // First day of current year
      startDate.setMonth(0, 1)
      break
  }
  
  // Set to beginning of the day
  startDate.setHours(0, 0, 0, 0)
  
  return sessions.value.filter(session => {
    const sessionDate = new Date(session.ended_at || session.started_at)
    return sessionDate >= startDate
  })
})

// Calculer la durée moyenne des séances
const averageDuration = computed(() => {
  if (filteredSessions.value.length === 0) return '0 min'
  
  const totalMinutes = filteredSessions.value.reduce((total, session) => {
    if (!session.started_at || !session.ended_at) return total
    
    const start = new Date(session.started_at)
    const end = new Date(session.ended_at)
    const duration = Math.round((end - start) / (1000 * 60))
    
    return total + (duration > 0 ? duration : 0)
  }, 0)
  
  const avgMinutes = Math.round(totalMinutes / filteredSessions.value.length)
  
  if (avgMinutes >= 60) {
    const hours = Math.floor(avgMinutes / 60)
    const minutes = avgMinutes % 60
    return `${hours}h${minutes > 0 ? ` ${minutes}m` : ''}`
  }
  
  return `${avgMinutes}m`
})

// Calculer le nombre total d'exercices
const totalExercisesCount = computed(() => {
  return filteredSessions.value.reduce((total, session) => {
    return total + (session.exercise_count || 0)
  }, 0)
})

const handleDeleteSession = async (sessionId) => {
  try {
    await deleteSession(sessionId)
  } catch (e) {
    console.error("Erreur lors de la suppression:", e)
  }
}

onMounted(loadSessions)
</script>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.5s ease-out forwards;
  opacity: 0;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style> 
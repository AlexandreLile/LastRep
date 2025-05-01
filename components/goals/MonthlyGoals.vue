<template>
  <div class="space-y-6 p-6">
    <div class="flex items-center justify-between">
      <h2 class="text-lg font-semibold">Objectifs du mois</h2>
      <span class="text-sm text-gray-500">{{ currentMonth }}</span>
    </div>

    <!-- Objectif de séances -->
    <div class="space-y-4">
      <div class="space-y-2">
        <h3 class="text-sm font-medium">Séances d'entraînement</h3>
        <p class="text-2xl font-semibold text-primary">
          {{ sessionsCount }}/{{ targetSessions }} séances
        </p>
        <p class="text-xs text-gray-500" v-if="nextMilestone">
          Atteindre {{ targetSessions }} séances pour débloquer le palier suivant
        </p>
      </div>
      <div class="w-full">
        <div class="h-4 bg-gray-200 rounded-full overflow-hidden">
          <div 
            class="h-full bg-primary transition-all duration-300" 
            :style="{ width: `${Math.min((sessionsCount / targetSessions) * 100, 100)}%` }"
          ></div>
        </div>
      </div>
    </div>

    <!-- Récompenses -->
    <div class="space-y-4">
      <h3 class="text-sm font-medium">Récompenses à débloquer</h3>
      <div class="flex flex-wrap gap-4">
        <!-- Badge Régularité -->
        <div 
          class="p-4 rounded-lg transition-colors duration-300 flex-1 min-w-[200px]"
          :class="sessionsCount >= 12 ? 'bg-primary/5' : 'bg-gray-50 dark:bg-gray-800'"
        >
          <div class="flex items-center space-x-3">
            <div 
              class="p-2 rounded-full transition-colors duration-300"
              :class="sessionsCount >= 12 ? 'bg-primary/10' : 'bg-gray-100 dark:bg-gray-700'"
            >
              <Target 
                class="h-5 w-5 transition-colors duration-300"
                :class="sessionsCount >= 12 ? 'text-primary' : 'text-gray-400'"
              />
            </div>
            <div>
              <h4 class="text-sm font-medium">Régularité</h4>
              <p class="text-xs text-gray-500">12 séances dans le mois</p>
            </div>
          </div>
        </div>

        <!-- Badge Détermination -->
        <div 
          class="p-4 rounded-lg transition-colors duration-300 flex-1 min-w-[200px]"
          :class="sessionsCount >= 16 ? 'bg-primary/5' : 'bg-gray-50 dark:bg-gray-800'"
        >
          <div class="flex items-center space-x-3">
            <div 
              class="p-2 rounded-full transition-colors duration-300"
              :class="sessionsCount >= 16 ? 'bg-primary/10' : 'bg-gray-100 dark:bg-gray-700'"
            >
              <Trophy 
                class="h-5 w-5 transition-colors duration-300"
                :class="sessionsCount >= 16 ? 'text-primary' : 'text-gray-400'"
              />
            </div>
            <div>
              <h4 class="text-sm font-medium">Détermination</h4>
              <p class="text-xs text-gray-500">16 séances dans le mois</p>
            </div>
          </div>
        </div>

        <!-- Badge Expert -->
        <div 
          class="p-4 rounded-lg transition-colors duration-300 flex-1 min-w-[200px]"
          :class="sessionsCount >= 20 ? 'bg-primary/5' : 'bg-gray-50 dark:bg-gray-800'"
        >
          <div class="flex items-center space-x-3">
            <div 
              class="p-2 rounded-full transition-colors duration-300"
              :class="sessionsCount >= 20 ? 'bg-primary/10' : 'bg-gray-100 dark:bg-gray-700'"
            >
              <Award 
                class="h-5 w-5 transition-colors duration-300"
                :class="sessionsCount >= 20 ? 'text-primary' : 'text-gray-400'"
              />
            </div>
            <div>
              <h4 class="text-sm font-medium">Expert</h4>
              <p class="text-xs text-gray-500">20 séances dans le mois</p>
            </div>
          </div>
        </div>

        <!-- Badge Elite -->
        <div 
          class="p-4 rounded-lg transition-colors duration-300 flex-1 min-w-[200px]"
          :class="sessionsCount >= 24 ? 'bg-primary/5' : 'bg-gray-50 dark:bg-gray-800'"
        >
          <div class="flex items-center space-x-3">
            <div 
              class="p-2 rounded-full transition-colors duration-300"
              :class="sessionsCount >= 24 ? 'bg-primary/10' : 'bg-gray-100 dark:bg-gray-700'"
            >
              <Medal 
                class="h-5 w-5 transition-colors duration-300"
                :class="sessionsCount >= 24 ? 'text-primary' : 'text-gray-400'"
              />
            </div>
            <div>
              <h4 class="text-sm font-medium">Elite</h4>
              <p class="text-xs text-gray-500">24 séances dans le mois</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { Target, Trophy, Award, Medal } from 'lucide-vue-next'


const supabase = useSupabaseClient()

// Données dynamiques
const sessionsCount = ref(0)
const currentMonth = ref('')

// Objectifs par défaut
const targetSessions = ref(12)

// Calcul du prochain palier
const nextMilestone = computed(() => {
  if (sessionsCount.value >= 24) return null
  if (sessionsCount.value >= 20) return 24
  if (sessionsCount.value >= 16) return 20
  if (sessionsCount.value >= 12) return 16
  return 12
})

const loadMonthlyStats = async () => {
  try {
    // Récupérer l'utilisateur connecté
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      console.log('Aucun utilisateur connecté')
      return
    }
    console.log('Utilisateur connecté:', user.id)

    // Définir le mois en cours
    const now = new Date()
    currentMonth.value = now.toLocaleString('fr-FR', { month: 'long', year: 'numeric' })
    
    // Ajuster les dates pour le fuseau horaire
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
    startOfMonth.setHours(0, 0, 0, 0)
    
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0)
    endOfMonth.setHours(23, 59, 59, 999)

    console.log('Dates de recherche:', {
      start: startOfMonth.toISOString(),
      end: endOfMonth.toISOString(),
      startLocal: startOfMonth.toLocaleString(),
      endLocal: endOfMonth.toLocaleString()
    })

    // D'abord, récupérer toutes les séances de l'utilisateur
    const { data: allSessions, error: allError } = await supabase
      .from('performedsession')
      .select('id, created_at')
      .eq('user_id', user.id)
      .order('created_at', { ascending: true })

    if (allError) {
      console.error('Erreur lors de la requête de toutes les séances:', allError)
      return
    }

    console.log('Toutes les séances:', allSessions)

    // Filtrer les séances du mois en cours
    const sessionsThisMonth = allSessions.filter(session => {
      const sessionDate = new Date(session.created_at)
      return sessionDate >= startOfMonth && sessionDate <= endOfMonth
    })

    console.log('Séances du mois en cours:', sessionsThisMonth)
    sessionsCount.value = sessionsThisMonth.length

    // Mettre à jour l'objectif en fonction des paliers atteints
    if (sessionsCount.value >= 24) {
      targetSessions.value = 24
    } else if (sessionsCount.value >= 20) {
      targetSessions.value = 24
    } else if (sessionsCount.value >= 16) {
      targetSessions.value = 20
    } else if (sessionsCount.value >= 12) {
      targetSessions.value = 16
    } else {
      targetSessions.value = 12
    }
  } catch (error) {
    console.error('Erreur lors du chargement des statistiques:', error)
  }
}

onMounted(() => {
  loadMonthlyStats()
})
</script> 
<template>
  <div class="space-y-6 p-6 border rounded-lg">
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
      <div class="grid grid-cols-2 gap-4">
        <!-- Badge Régularité -->
        <div 
          class="p-4 rounded-lg border transition-colors duration-300"
          :class="sessionsCount >= 12 ? 'bg-primary/5 border-primary' : 'bg-gray-50 dark:bg-gray-800'"
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
          class="p-4 rounded-lg border transition-colors duration-300"
          :class="sessionsCount >= 16 ? 'bg-primary/5 border-primary' : 'bg-gray-50 dark:bg-gray-800'"
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
          class="p-4 rounded-lg border transition-colors duration-300"
          :class="sessionsCount >= 20 ? 'bg-primary/5 border-primary' : 'bg-gray-50 dark:bg-gray-800'"
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
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { Target, Trophy, Award } from 'lucide-vue-next'
import { useSupabaseClient } from '#imports'

const supabase = useSupabaseClient()

// Données dynamiques
const sessionsCount = ref(0)
const currentMonth = ref('')

// Objectifs par défaut
const targetSessions = ref(12)

// Calcul du prochain palier
const nextMilestone = computed(() => {
  if (sessionsCount.value >= 20) return null
  if (sessionsCount.value >= 16) return 20
  if (sessionsCount.value >= 12) return 16
  return 12
})

const loadMonthlyStats = async () => {
  try {
    // Récupérer l'utilisateur connecté
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Définir le mois en cours
    const now = new Date()
    currentMonth.value = now.toLocaleString('fr-FR', { month: 'long', year: 'numeric' })
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0)

    // Compter les séances du mois
    const { count } = await supabase
      .from('performedsession')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)
      .gte('created_at', startOfMonth.toISOString())
      .lte('created_at', endOfMonth.toISOString())

    sessionsCount.value = count || 0

    // Mettre à jour l'objectif en fonction des paliers atteints
    if (sessionsCount.value >= 20) {
      targetSessions.value = 20
    } else if (sessionsCount.value >= 16) {
      targetSessions.value = 16
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
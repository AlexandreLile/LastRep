<template>
  <div class="space-y-6">
    <div class="flex justify-end">
      <span class="text-sm text-muted-foreground">{{ currentMonth }}</span>
    </div>

    <!-- Objectif de séances -->
    <div class="space-y-4">
      <div class="space-y-2">
        <h3 class="text-sm font-medium">Séances d'entraînement</h3>
        <p class="text-2xl font-semibold text-primary">
          {{ sessionsCount }}/{{ targetSessions }} séances
        </p>
        <p class="text-xs text-muted-foreground" v-if="nextMilestone">
          Atteindre {{ targetSessions }} séances pour débloquer le palier suivant
        </p>
      </div>
      <div class="w-full">
        <div class="h-4 bg-muted rounded-full overflow-hidden">
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
          class="p-4 rounded-lg border transition-all duration-300 flex-1 min-w-[200px]"
          :class="[
            sessionsCount >= 12 
              ? 'bg-primary/10 border-primary/30 shadow-md shadow-primary/10' 
              : 'bg-card border-border'
          ]"
        >
          <div class="flex items-center space-x-3">
            <div 
              class="p-2 rounded-full transition-all duration-300"
              :class="[
                sessionsCount >= 12 
                  ? 'bg-primary/20 animate-[zoom_2s_ease-in-out_infinite]' 
                  : 'bg-muted'
              ]"
            >
              <Target 
                class="h-5 w-5 transition-all duration-300"
                :class="sessionsCount >= 12 ? 'text-primary' : 'text-muted-foreground'"
              />
            </div>
            <div>
              <h4 class="text-sm font-semibold text-foreground">Régularité</h4>
              <p class="text-xs text-muted-foreground mt-0.5">12 séances dans le mois</p>
            </div>
          </div>
        </div>

        <!-- Badge Détermination -->
        <div 
          class="p-4 rounded-lg border transition-all duration-300 flex-1 min-w-[200px]"
          :class="[
            sessionsCount >= 16 
              ? 'bg-primary/10 border-primary/30 shadow-md shadow-primary/10' 
              : 'bg-card border-border'
          ]"
        >
          <div class="flex items-center space-x-3">
            <div 
              class="p-2 rounded-full transition-all duration-300"
              :class="[
                sessionsCount >= 16 
                  ? 'bg-primary/20 animate-[zoom_2s_ease-in-out_infinite]' 
                  : 'bg-muted'
              ]"
            >
              <Trophy 
                class="h-5 w-5 transition-all duration-300"
                :class="sessionsCount >= 16 ? 'text-primary' : 'text-muted-foreground'"
              />
            </div>
            <div>
              <h4 class="text-sm font-semibold text-foreground">Détermination</h4>
              <p class="text-xs text-muted-foreground mt-0.5">16 séances dans le mois</p>
            </div>
          </div>
        </div>

        <!-- Badge Expert -->
        <div 
          class="p-4 rounded-lg border transition-all duration-300 flex-1 min-w-[200px]"
          :class="[
            sessionsCount >= 20 
              ? 'bg-primary/10 border-primary/30 shadow-md shadow-primary/10' 
              : 'bg-card border-border'
          ]"
        >
          <div class="flex items-center space-x-3">
            <div 
              class="p-2 rounded-full transition-all duration-300"
              :class="[
                sessionsCount >= 20 
                  ? 'bg-primary/20 animate-[zoom_2s_ease-in-out_infinite]' 
                  : 'bg-muted'
              ]"
            >
              <Award 
                class="h-5 w-5 transition-all duration-300"
                :class="sessionsCount >= 20 ? 'text-primary' : 'text-muted-foreground'"
              />
            </div>
            <div>
              <h4 class="text-sm font-semibold text-foreground">Expert</h4>
              <p class="text-xs text-muted-foreground mt-0.5">20 séances dans le mois</p>
            </div>
          </div>
        </div>

        <!-- Badge Elite -->
        <div 
          class="p-4 rounded-lg border transition-all duration-300 flex-1 min-w-[200px]"
          :class="[
            sessionsCount >= 24 
              ? 'bg-primary/10 border-primary/30 shadow-md shadow-primary/10' 
              : 'bg-card border-border'
          ]"
        >
          <div class="flex items-center space-x-3">
            <div 
              class="p-2 rounded-full transition-all duration-300"
              :class="[
                sessionsCount >= 24 
                  ? 'bg-primary/20 animate-[zoom_2s_ease-in-out_infinite]' 
                  : 'bg-muted'
              ]"
            >
              <Medal 
                class="h-5 w-5 transition-all duration-300"
                :class="sessionsCount >= 24 ? 'text-primary' : 'text-muted-foreground'"
              />
            </div>
            <div>
              <h4 class="text-sm font-semibold text-foreground">Elite</h4>
              <p class="text-xs text-muted-foreground mt-0.5">24 séances dans le mois</p>
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
import { logger } from '~/utils/logger'

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
      logger.log('Aucun utilisateur connecté')
      return
    }
    logger.log('MonthlyGoals: Utilisateur connecté:', user.id)
    logger.log('MonthlyGoals: ID attendu pour les données de seed:', '9af8cb22-9196-4616-bea9-5fafc0b48af7')
    logger.log('MonthlyGoals: IDs correspondent?', user.id === '9af8cb22-9196-4616-bea9-5fafc0b48af7')

    // Définir le mois en cours
    const now = new Date()
    currentMonth.value = now.toLocaleString('fr-FR', { month: 'long', year: 'numeric' })
    
    // Ajuster les dates pour le fuseau horaire
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
    startOfMonth.setHours(0, 0, 0, 0)
    
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0)
    endOfMonth.setHours(23, 59, 59, 999)

    logger.log('MonthlyGoals: Dates de recherche:', {
      moisActuel: currentMonth.value,
      anneeActuelle: now.getFullYear(),
      moisActuelNumero: now.getMonth() + 1, // 1-12
      start: startOfMonth.toISOString(),
      end: endOfMonth.toISOString(),
      startLocal: startOfMonth.toLocaleString('fr-FR'),
      endLocal: endOfMonth.toLocaleString('fr-FR')
    })

    // D'abord, récupérer toutes les séances de l'utilisateur
    const { data: allSessions, error: allError } = await supabase
      .from('performedsession')
      .select('id, started_at')
      .eq('user_id', user.id)
      .not('started_at', 'is', null)
      .order('started_at', { ascending: true })

    if (allError) {
      console.error('Erreur lors de la requête de toutes les séances:', allError)
      return
    }

    logger.log('MonthlyGoals: Toutes les séances récupérées:', allSessions?.length || 0, allSessions)

    // Filtrer les séances du mois en cours en utilisant started_at
    const sessionsThisMonth = (allSessions || []).filter(session => {
      if (!session.started_at) return false
      const sessionDate = new Date(session.started_at)
      
      // Normaliser les dates pour la comparaison (ignorer les heures)
      const sessionYear = sessionDate.getFullYear()
      const sessionMonth = sessionDate.getMonth()
      const targetYear = startOfMonth.getFullYear()
      const targetMonth = startOfMonth.getMonth()
      
      const isInMonth = sessionYear === targetYear && sessionMonth === targetMonth
      
      if (isInMonth) {
        logger.log('MonthlyGoals: Séance trouvée dans le mois:', {
          date: session.started_at,
          sessionDate: sessionDate.toISOString(),
          sessionYear,
          sessionMonth: sessionMonth + 1, // 1-12 pour affichage
          targetYear,
          targetMonth: targetMonth + 1,
          startOfMonth: startOfMonth.toISOString(),
          endOfMonth: endOfMonth.toISOString()
        })
      } else {
        logger.log('MonthlyGoals: Séance hors du mois:', {
          date: session.started_at,
          sessionYear,
          sessionMonth: sessionMonth + 1,
          targetYear,
          targetMonth: targetMonth + 1
        })
      }
      return isInMonth
    })

    logger.log('MonthlyGoals: Séances du mois en cours:', sessionsThisMonth.length, sessionsThisMonth)
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
    logger.error('Erreur lors du chargement des statistiques:', error)
  }
}

onMounted(() => {
  loadMonthlyStats()
})
</script>

<style scoped>
@keyframes zoom {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.1);
  }
}
</style> 
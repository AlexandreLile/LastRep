<template>
  <div class="relative">
    <!-- Animation de célébration -->
    <div v-if="showCelebration" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div class="bg-card rounded-xl p-8 max-w-md w-full mx-4 text-center">
        <div class="confetti-explosion">
          <div v-for="n in 20" :key="n" class="confetti"></div>
        </div>
        <div class="text-5xl mb-4">🏆</div>
        <h3 class="text-2xl font-bold text-foreground mb-2">Félicitations !</h3>
        <p class="text-muted-foreground mb-6">Vous avez terminé votre séance avec succès !</p>
        <Button @click="showCelebration = false" class="w-full">
          Continuer
        </Button>
      </div>
    </div>

    <!-- Modal de bienvenue (affichée automatiquement pour les nouveaux utilisateurs) -->
    <WelcomeModal :open="showWelcomeModal" @update:open="showWelcomeModal = $event" />

    <!-- Header amélioré -->
    <div class="mb-8 bg-card rounded-xl p-6">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
          <LayoutDashboard class="h-6 w-6 text-primary" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-foreground">Vue d'ensemble</h2>
          <p class="text-sm text-muted-foreground">Suivez vos progrès et vos performances</p>
        </div>
      </div>
    </div>

    <!-- Stats Grid avec styles améliorés -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6 mb-8">
      <div class="bg-card rounded-xl p-6 border border-border">
        <div class="flex flex-col h-full">
          <div class="mb-3 flex items-center gap-3">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <Dumbbell class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-sm font-medium text-muted-foreground">Séances complétées</h3>
          </div>
          <SessionCountSupabase class="mt-auto" />
        </div>
      </div>
      <div class="bg-card rounded-xl p-6 border border-border">
        <div class="flex flex-col h-full">
          <div class="mb-3 flex items-center gap-3">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <Weight class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-sm font-medium text-muted-foreground">Poids total soulevé</h3>
          </div>
          <TotalWeightLiftedSupabase class="mt-auto" />
        </div>
      </div>
      <div class="bg-card rounded-xl p-6 border border-border">
        <div class="flex flex-col h-full">
          <div class="mb-3 flex items-center gap-3">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <ClockIcon class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-sm font-medium text-foreground">Temps d'entraînement</h3>
          </div>
          <TotalTrainingTimeSupabase class="mt-auto" />
        </div>
      </div>
    </div>

    <!-- Cycle en cours -->
    <CycleEnCours class="mb-8" />

    <!-- Two Columns Layout avec styles améliorés -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Left Column -->
      <div class="flex flex-col gap-6">
        <!-- Last Session -->
        <div class="bg-card rounded-xl p-6">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <Timer class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold">Dernière séance</h3>
          </div>
          <LastSessionStats />
        </div>
        
        <!-- Monthly Goals -->
        <div class="bg-card rounded-xl p-6">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <Target class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold">Objectifs mensuels</h3>
          </div>
          <MonthlyGoals />
        </div>
      </div>

      <!-- Right Column - Calendar -->
      <div class="bg-card rounded-xl p-6 self-start">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Calendar class="w-5 h-5 text-primary" />
          </div>
          <h3 class="text-lg font-semibold">Calendrier d'entraînement</h3>
        </div>
        <TrainingCalendar />
      </div>
    </div>

    <!-- Section de motivation -->
    <div class="bg-primary rounded-xl p-6 text-white mt-8">
      <div class="flex flex-col items-center text-center py-4">
        <h3 class="text-xl md:text-2xl font-bold mb-2">Restez motivé !</h3>
        <p class="text-white/90 max-w-2xl mx-auto mb-4">Chaque séance vous rapproche de vos objectifs. Continuez à repousser vos limites !</p>
        <div class="text-4xl mb-2">💪</div>
        <p class="text-sm text-white/80 italic">"La douleur que vous ressentirez aujourd'hui sera la force que vous ressentirez demain."</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, defineAsyncComponent } from 'vue'
import { useSupabaseClient } from '#imports'
import { useRouter, useRoute } from 'vue-router'
import { LayoutDashboard, Timer, Target, LogOut, Calendar, Dumbbell, Weight, Clock as ClockIcon } from 'lucide-vue-next'
import SessionCountSupabase from '~/components/stats/SessionCountSupabase.vue'
import TotalWeightLiftedSupabase from '~/components/stats/TotalWeightLiftedSupabase.vue'
import TotalTrainingTimeSupabase from '~/components/stats/TotalTrainingTimeSupabase.vue'
import WelcomeModal from '@/components/onboarding/WelcomeModal.vue'
import CycleEnCours from '~/components/cycles/CycleEnCours.vue'
import { Button } from '@/components/ui/button'
import { useAuthentication } from '~/composables/useAuthentication'
import { clearCachedUser } from '~/utils/offlineTraining'

// Code splitting : charger les composants lourds de manière asynchrone
const TrainingCalendar = defineAsyncComponent(() => import('~/components/calendar/TrainingCalendar.vue'))
const MonthlyGoals = defineAsyncComponent(() => import('~/components/goals/MonthlyGoals.vue'))
const LastSessionStats = defineAsyncComponent(() => import('~/components/stats/LastSessionStats.vue'))

// Définir la configuration de la page
definePageMeta({
  middleware: ['client-only']
})

// Utiliser le composable d'authentification
const { user, loading: authLoading, initialized, checkAuth } = useAuthentication()
const dataLoading = ref(true)
const showWelcomeModal = ref(false)
const showCelebration = ref(false)

const supabase = useSupabaseClient()
const router = useRouter()
const route = useRoute()

// Vérifier si l'utilisateur est nouveau (pas de séances)
const checkIfNewUser = async () => {
  try {
    const { data: { user: currentUser } } = await supabase.auth.getUser()
    if (!currentUser) return false

    // Vérifier si la modal a déjà été vue pour CET utilisateur spécifique
    // Utiliser l'ID utilisateur pour éviter les conflits entre comptes
    if (typeof window !== 'undefined') {
      // Nettoyer l'ancienne clé globale si elle existe (migration)
      const oldKey = localStorage.getItem('welcomeModalSeen')
      if (oldKey) {
        localStorage.removeItem('welcomeModalSeen')
      }
      
      // Vérifier avec la nouvelle clé spécifique à l'utilisateur
      const welcomeModalKey = `welcomeModalSeen_${currentUser.id}`
      const welcomeModalSeen = localStorage.getItem(welcomeModalKey) === 'true'
      
      if (welcomeModalSeen) return false
    }

    // Vérifier si l'utilisateur a des séances
    const { data: sessions, error } = await supabase
      .from('workoutsession')
      .select('id')
      .eq('user_id', currentUser.id)
      .limit(1)

    if (error) {
      console.error('Erreur lors de la vérification des séances:', error)
      return false
    }

    // Si aucune séance, c'est un nouvel utilisateur
    return !sessions || sessions.length === 0
  } catch (error) {
    console.error('Erreur lors de la vérification:', error)
    return false
  }
}

// Assurer que l'authentification est vérifiée avant d'afficher la page
onMounted(async () => {
  if (!initialized.value) {
    await checkAuth()
  }
  
  // Une fois l'authentification vérifiée, charger les données
  setTimeout(() => {
    dataLoading.value = false
  }, 200)

  // Vérifier si on doit afficher la modal de bienvenue (première connexion)
  const isNewUser = await checkIfNewUser()
  if (isNewUser) {
    // Attendre un peu pour que la page soit chargée
    setTimeout(() => {
      showWelcomeModal.value = true
    }, 500)
  }

  if (route.query.celebrate === '1') {
    showCelebration.value = true
    const { celebrate, ...restQuery } = route.query
    router.replace({ query: restQuery })
  }
})

const logout = async () => {
  try {
    await supabase.auth.signOut()
    // Effacer le cache utilisateur offline
    clearCachedUser()
    router.push('/login')
  } catch (error) {
    console.error('Erreur lors de la déconnexion:', error)
  }
}
</script>

<style>
.bg-white\/80 {
  background-color: rgba(255, 255, 255, 0.8);
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 0.5;
  }
  50% {
    opacity: 0.1;
  }
}

/* Animation de confetti */
.confetti-explosion {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  z-index: 1;
}

.confetti {
  position: absolute;
  width: 8px;
  height: 16px;
  background-color: var(--primary);
  opacity: 0;
  animation: confetti-fall 3s ease-in-out forwards;
}

.confetti:nth-child(even) {
  background-color: #ffcc00;
}

.confetti:nth-child(3n) {
  background-color: #ff6b6b;
}

.confetti:nth-child(4n) {
  background-color: #4ecdc4;
}

@keyframes confetti-fall {
  0% {
    opacity: 1;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    opacity: 0;
    top: -20%;
    left: var(--random-x, 50%);
    transform: translate(-50%, 0) rotate(var(--random-rotate, 180deg));
  }
}
</style>

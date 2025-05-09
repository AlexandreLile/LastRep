<template>
  <div class="relative min-h-screen bg-gradient-to-br from-[#0a174e] via-[#19398a] to-[#1e2a78] py-8 px-2 sm:px-6">
    <!-- Header amélioré -->
    <div class="mb-8 backdrop-blur-md rounded-3xl p-6 shadow-xl border border-white border-opacity-20 glass-card">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-primary bg-opacity-20 rounded-full flex items-center justify-center">
          <LayoutDashboard class="h-6 w-6 text-blue-200" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-white">Vue d'ensemble</h2>
          <p class="text-sm text-blue-200">Ta discipline d'aujourd'hui construit ta force de demain.</p>
        </div>
      </div>
    </div>

    <!-- Stats Grid avec styles améliorés -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6 mb-8">
      <div class="glass-card">
        <div class="flex flex-col h-full">
          <div class="mb-3 flex items-center gap-3">
            <div class="w-10 h-10 bg-primary bg-opacity-20 rounded-full flex items-center justify-center">
              <Dumbbell class="w-5 h-5 text-blue-200" />
            </div>
            <h3 class="text-sm font-medium text-blue-200">Séances complétées</h3>
          </div>
          <SessionCount class="mt-auto text-white" />
        </div>
      </div>
      <div class="glass-card">
        <div class="flex flex-col h-full">
          <div class="mb-3 flex items-center gap-3">
            <div class="w-10 h-10 bg-primary bg-opacity-20 rounded-full flex items-center justify-center">
              <Weight class="w-5 h-5 text-blue-200" />
            </div>
            <h3 class="text-sm font-medium text-blue-200">Poids total soulevé</h3>
          </div>
          <TotalWeightLifted class="mt-auto text-white" />
        </div>
      </div>
      <div class="glass-card">
        <div class="flex flex-col h-full">
          <div class="mb-3 flex items-center gap-3">
            <div class="w-10 h-10 bg-primary bg-opacity-20 rounded-full flex items-center justify-center">
              <ClockIcon class="w-5 h-5 text-blue-200" />
            </div>
            <h3 class="text-sm font-medium text-blue-200">Temps d'entraînement</h3>
          </div>
          <TotalTrainingTime class="mt-auto text-white" />
        </div>
      </div>
    </div>

    <!-- Two Columns Layout avec styles améliorés -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Left Column -->
      <div class="flex flex-col gap-6">
        <!-- Monthly Goals -->
        <div class="glass-card">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary bg-opacity-20 rounded-full flex items-center justify-center">
              <Target class="w-5 h-5 text-blue-200" />
            </div>
            <h3 class="text-lg font-semibold text-white">Objectifs mensuels</h3>
          </div>
          <MonthlyGoals />
        </div>
        <!-- Last Session -->
        <div class="glass-card">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary bg-opacity-20 rounded-full flex items-center justify-center">
              <Timer class="w-5 h-5 text-blue-200" />
            </div>
            <h3 class="text-lg font-semibold text-white">Dernière séance</h3>
          </div>
          <LastSessionStats />
        </div>
      </div>
      <!-- Right Column - Calendar -->
      <div class="glass-card self-start">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary bg-opacity-20 rounded-full flex items-center justify-center">
            <Calendar class="w-5 h-5 text-blue-200" />
          </div>
          <h3 class="text-lg font-semibold text-white">Calendrier d'entraînement</h3>
        </div>
        <TrainingCalendar />
      </div>
    </div>

    <!-- Section de motivation -->
    <div class="bg-gradient-to-r from-blue-700 bg-opacity-80 to-blue-900 bg-opacity-80 rounded-3xl p-6 text-white mt-8 shadow-xl border border-white border-opacity-20">
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
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'
import { useRouter } from 'vue-router'
import { LayoutDashboard, Timer, Target, LogOut, Calendar, Dumbbell, Weight, Clock as ClockIcon } from 'lucide-vue-next'
import SessionCount from '~/components/stats/SessionCount.vue'
import TotalWeightLifted from '~/components/stats/TotalWeightLifted.vue'
import TotalTrainingTime from '~/components/stats/TotalTrainingTime.vue'
import TrainingCalendar from '~/components/calendar/TrainingCalendar.vue'
import MonthlyGoals from '~/components/goals/MonthlyGoals.vue'
import LastSessionStats from '~/components/stats/LastSessionStats.vue'
import { Button } from '@/components/ui/button'
import { useAuthentication } from '~/composables/useAuthentication'

// Définir la configuration de la page
definePageMeta({
  middleware: ['client-only']
})

// Utiliser le composable d'authentification
const { user, loading: authLoading, initialized, checkAuth } = useAuthentication()
const dataLoading = ref(true)

const supabase = useSupabaseClient()
const router = useRouter()

// Assurer que l'authentification est vérifiée avant d'afficher la page
onMounted(async () => {
  if (!initialized.value) {
    await checkAuth()
  }
  
  // Une fois l'authentification vérifiée, charger les données
  setTimeout(() => {
    dataLoading.value = false
  }, 200)
})

const logout = async () => {
  try {
    await supabase.auth.signOut()
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

.glass-card {
  background-color: hsl(var(--card) / 0.18);
  backdrop-filter: blur(16px);
  border-radius: 1.5rem;
  padding: 1.5rem;
  box-shadow: 0 12px 40px 0 rgba(31, 38, 135, 0.25), 0 1.5px 8px 0 rgba(255,255,255,0.10) inset;
  border: 1.5px solid rgba(255,255,255,0.25);
}
</style>

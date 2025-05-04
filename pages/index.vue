<template>
  <div class="relative">
   

    <!-- Header amélioré -->
    <div class="mb-8 bg-white rounded-xl p-6">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
          <LayoutDashboard class="h-6 w-6 text-primary" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Vue d'ensemble</h2>
          <p class="text-sm text-muted-foreground">Suivez vos progrès et vos performances</p>
        </div>
      </div>
    </div>

    <!-- Stats Grid avec styles améliorés -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6 mb-8">
      <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300 transform hover:scale-[1.01]">
        <SessionCount />
      </div>
      <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300 transform hover:scale-[1.01]">
        <TotalWeightLifted />
      </div>
      <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300 transform hover:scale-[1.01]">
        <TotalTrainingTime />
      </div>
    </div>

    <!-- Two Columns Layout avec styles améliorés -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Left Column -->
      <div class="flex flex-col gap-6">
        <!-- Monthly Goals -->
        <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <Target class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold">Objectifs mensuels</h3>
          </div>
          <MonthlyGoals />
        </div>
        
        <!-- Last Session -->
        <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <Timer class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold">Dernière séance</h3>
          </div>
          <LastSessionStats />
        </div>
      </div>

      <!-- Right Column - Calendar -->
      <div class="bg-white rounded-xl p-6 self-start hover:shadow-md transition-all duration-300">
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
import { ref } from 'vue'
import { useSupabaseClient } from '#imports'
import { useRouter } from 'vue-router'
import { LayoutDashboard, Timer, Target, LogOut, Calendar } from 'lucide-vue-next'
import SessionCount from '~/components/stats/SessionCount.vue'
import TotalWeightLifted from '~/components/stats/TotalWeightLifted.vue'
import TotalTrainingTime from '~/components/stats/TotalTrainingTime.vue'
import TrainingCalendar from '~/components/calendar/TrainingCalendar.vue'
import MonthlyGoals from '~/components/goals/MonthlyGoals.vue'
import LastSessionStats from '~/components/stats/LastSessionStats.vue'
import { Button } from '@/components/ui/button'

const supabase = useSupabaseClient()
const router = useRouter()

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
</style>

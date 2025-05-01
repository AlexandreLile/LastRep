<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <h2 class="text-2xl font-semibold text-gray-900">Vue d'ensemble</h2>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 mb-8">
      <div class="bg-white rounded-xl p-6">
        <SessionCount />
      </div>
      <div class="bg-white rounded-xl p-6">
        <TotalWeightLifted />
      </div>
      <div class="bg-white rounded-xl p-6">
        <TotalTrainingTime />
      </div>
    </div>

    <!-- Two Columns Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Left Column -->
      <div class="flex flex-col gap-6">
        <!-- Monthly Goals -->
        <div class="bg-white rounded-xl">
          <MonthlyGoals />
        </div>
        
        <!-- Last Session -->
        <div class="bg-white rounded-xl p-6">
          <LastSessionStats />
        </div>
      </div>

      <!-- Right Column - Calendar adapté à la hauteur de la colonne de gauche -->
      <div class="bg-white rounded-xl self-start">
        <TrainingCalendar />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useSupabaseClient } from '#imports'
import { useRouter } from 'vue-router'
import { LayoutDashboard, Timer, Target, LogOut } from 'lucide-vue-next'
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
</style>

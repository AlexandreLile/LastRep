<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center py-4">
      <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
    </div>
    <div v-else class="flex flex-col">
      <p class="text-3xl font-bold text-foreground">{{ sessionCount }}</p>
      <div class="flex flex-wrap items-center justify-between gap-2 mt-1">
        <p class="text-sm text-muted-foreground">séances complétées</p>
        <div class="bg-primary/10 text-primary text-xs font-medium px-3 py-1.5 rounded-full border border-primary/20 shadow-sm flex items-center gap-1.5">
          <Dumbbell class="h-3 w-3" />
          <span>{{ formatWeeklyAverage }}/semaine</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useSupabaseClient } from '#imports'
import { Dumbbell } from 'lucide-vue-next'
import { useUserStats } from '~/composables/useUserStats'

const supabase = useSupabaseClient()
const { getSessionStats } = useUserStats()
const sessionCount = ref(0)
const weeklyAverage = ref(0)
const loading = ref(true)

const formatWeeklyAverage = computed(() => {
  if (weeklyAverage.value === 0) return '0'
  return weeklyAverage.value < 10 
    ? weeklyAverage.value.toFixed(1) 
    : Math.round(weeklyAverage.value).toString()
})

const loadSessionStats = async () => {
  try {
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    // Utiliser le cache pour améliorer les performances
    const stats = await getSessionStats(user.id)

    sessionCount.value = stats.totalSessions || 0
    weeklyAverage.value = stats.weeklyAverage || 0
    
  } catch (e) {
    // Erreur silencieuse pour ne pas perturber l'UX
  } finally {
    loading.value = false
  }
}

onMounted(loadSessionStats)
</script> 
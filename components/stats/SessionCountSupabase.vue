<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center py-4">
      <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
    </div>
    <div v-else class="flex flex-col">
      <p class="text-3xl font-bold text-gray-900">{{ sessionCount }}</p>
      <div class="flex items-center mt-1">
        <p class="text-sm text-muted-foreground">séances complétées</p>
        <div class="ml-auto bg-primary/10 text-primary text-xs px-2 py-1 rounded-full flex items-center gap-1">
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

const supabase = useSupabaseClient()
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

    // Utiliser la fonction SQL pour obtenir les statistiques
    const { data: statsData, error: statsError } = await supabase
      .rpc('get_session_stats', { user_uuid: user.id })

    if (statsError) throw statsError

    sessionCount.value = statsData[0]?.total_sessions || 0
    weeklyAverage.value = statsData[0]?.weekly_average || 0
    
  } catch (e) {
    console.error('Erreur lors du chargement des statistiques de séances:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadSessionStats)
</script> 
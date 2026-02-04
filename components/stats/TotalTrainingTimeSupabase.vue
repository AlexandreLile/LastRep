<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center py-4">
      <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
    </div>
    <div v-else-if="error" class="text-red-500 text-sm py-2">
      {{ error }}
    </div>
    <div v-else class="flex flex-col">
      <p class="text-3xl font-bold text-foreground">{{ formatDuration(totalDuration) }}</p>
      <div class="flex flex-wrap items-center justify-between gap-2 mt-1">
        <p class="text-sm text-muted-foreground">temps d'entraînement</p>
        <div class="bg-primary/10 text-primary text-xs font-medium px-3 py-1.5 rounded-full border border-primary/20 shadow-sm">
          <span>{{ formatDuration(averageDuration) }}/séance</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useSupabaseClient } from '#imports'
import { useUserStats } from '~/composables/useUserStats'

const supabase = useSupabaseClient()
const { getTotalTrainingTime, getSessionCount } = useUserStats()
const totalDuration = ref(0)
const sessionsCount = ref(0)
const loading = ref(true)
const error = ref(null)

const averageDuration = computed(() => {
  if (sessionsCount.value === 0) return 0
  return Math.round(totalDuration.value / sessionsCount.value)
})

const formatDuration = (minutes) => {
  if (!minutes) return '0min'
  
  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60
  
  if (hours > 0) {
    return `${hours}h${remainingMinutes > 0 ? `${remainingMinutes}m` : ''}`
  }
  return `${minutes}min`
}

const loadTotalDuration = async () => {
  try {
    loading.value = true
    error.value = null
    
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    // Utiliser le cache pour améliorer les performances
    const [trainingTime, sessionCountData] = await Promise.all([
      getTotalTrainingTime(user.id),
      getSessionCount(user.id)
    ])

    totalDuration.value = trainingTime.totalMinutes || 0
    sessionsCount.value = sessionCountData.count || 0

    // Fallback si le cache renvoie 0 mais qu'on a un temps total
    if (sessionsCount.value === 0 && totalDuration.value > 0) {
      const { count } = await supabase
        .from('performedsession')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', user.id)
      sessionsCount.value = count || 0
    }

  } catch (e) {
    error.value = 'Erreur lors du chargement des données'
  } finally {
    loading.value = false
  }
}

onMounted(loadTotalDuration)
</script> 
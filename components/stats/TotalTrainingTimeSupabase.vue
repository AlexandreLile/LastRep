<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center py-4">
      <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
    </div>
    <div v-else-if="error" class="text-red-500 text-sm py-2">
      {{ error }}
    </div>
    <div v-else class="flex flex-col">
      <p class="text-3xl font-bold text-gray-900">{{ formatDuration(totalDuration) }}</p>
      <div class="flex items-center mt-1">
        <p class="text-sm text-muted-foreground">temps d'entraînement</p>
        <div class="ml-auto bg-blue-50 text-blue-600 text-xs px-2 py-1 rounded-full">
          <span>{{ formatDuration(averageDuration) }}/séance</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useSupabaseClient } from '#imports'

const supabase = useSupabaseClient()
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

    // Utiliser la fonction SQL pour obtenir la durée totale
    const { data: durationData, error: durationError } = await supabase
      .rpc('get_total_training_time', { user_uuid: user.id })

    if (durationError) throw durationError

    totalDuration.value = durationData[0]?.total_minutes || 0

    // Récupérer le nombre de séances
    const { data: sessionData, error: sessionError } = await supabase
      .from('performedsession')
      .select('id', { count: 'exact' })
      .eq('user_id', user.id)

    if (sessionError) throw sessionError
    
    sessionsCount.value = sessionData.length || 1 // Éviter la division par zéro

  } catch (e) {
    console.error('Erreur lors du chargement de la durée totale:', e)
    error.value = 'Erreur lors du chargement des données'
  } finally {
    loading.value = false
  }
}

onMounted(loadTotalDuration)
</script> 
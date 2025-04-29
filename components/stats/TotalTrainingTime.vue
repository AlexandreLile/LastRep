<template>
  <div class="flex items-center justify-center bg-gray-100 p-4 rounded-lg">
    <div v-if="loading" class="text-center">
      <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary mx-auto"></div>
    </div>
    <div v-else-if="error" class="text-center text-red-500">
      {{ error }}
    </div>
    <div v-else class="text-center">
      <p class="text-2xl font-bold text-primary">{{ formatDuration(totalDuration) }}</p>
      <p class="text-sm text-muted-foreground">Temps d'entraînement</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'

const supabase = useSupabaseClient()
const totalDuration = ref(0)
const loading = ref(true)
const error = ref(null)

const formatDuration = (minutes) => {
  if (!minutes) return '0 min'
  
  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60
  
  if (hours > 0) {
    return `${hours}h${remainingMinutes > 0 ? ` ${remainingMinutes} min` : ''}`
  }
  return `${minutes} min`
}

const loadTotalDuration = async () => {
  try {
    loading.value = true
    error.value = null
    
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    // Récupérer toutes les séances effectuées, même si la workout_session a été supprimée
    const { data, error: fetchError } = await supabase
      .from('performedsession')
      .select('id, started_at, ended_at, workout_session_id')
      .eq('user_id', user.id)
      .order('started_at', { ascending: true })

    if (fetchError) throw fetchError

    if (!data || data.length === 0) {
      totalDuration.value = 0
      return
    }

    // Calculer la durée totale en minutes
    totalDuration.value = data.reduce((total, session) => {
      // Vérifier si la session a des dates valides
      if (!session.started_at || !session.ended_at) return total
      
      const start = new Date(session.started_at)
      const end = new Date(session.ended_at)
      
      // Vérifier que les dates sont valides
      if (isNaN(start.getTime()) || isNaN(end.getTime())) return total
      
      const duration = Math.round((end - start) / (1000 * 60)) // Convertir en minutes
      
      // Ne prendre en compte que les durées positives
      return total + (duration > 0 ? duration : 0)
    }, 0)

  } catch (e) {
    console.error('Erreur lors du chargement de la durée totale:', e)
    error.value = 'Erreur lors du chargement des données'
  } finally {
    loading.value = false
  }
}

onMounted(loadTotalDuration)
</script> 
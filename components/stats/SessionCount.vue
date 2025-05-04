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
          <span>{{ weeklyAverage }}/semaine</span>
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
const sessionsWithDates = ref([])
const loading = ref(true)
const weeklyAverage = ref('0')

const loadSessionCount = async () => {
  try {
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    // Récupérer toutes les sessions avec leurs dates
    const { data, error } = await supabase
      .from('performedsession')
      .select('id, started_at')
      .eq('user_id', user.id)
      .order('started_at', { ascending: false })

    if (error) throw error

    sessionCount.value = data.length
    sessionsWithDates.value = data.filter(s => s.started_at)
    
    // Calculer la moyenne hebdomadaire
    calculateWeeklyAverage()
    
  } catch (e) {
    console.error('Erreur lors du chargement du nombre de séances:', e)
  } finally {
    loading.value = false
  }
}

const calculateWeeklyAverage = () => {
  if (sessionsWithDates.value.length === 0) {
    weeklyAverage.value = '0'
    return
  }
  
  // Récupérer première et dernière date de session
  const dates = sessionsWithDates.value.map(s => new Date(s.started_at))
  
  // Si une seule séance ou séances le même jour
  if (dates.length === 1) {
    weeklyAverage.value = '1'
    return
  }
  
  // Trouver la date la plus récente et la plus ancienne
  const newestDate = new Date(Math.max(...dates.map(d => d.getTime())))
  const oldestDate = new Date(Math.min(...dates.map(d => d.getTime())))
  
  // Calculer le nombre de semaines (en jours / 7)
  const diffTime = Math.abs(newestDate - oldestDate)
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  
  // Nombre de semaines arrondi à 1 minimum
  const weeks = Math.max(1, Math.round(diffDays / 7))
  
  // Calculer la moyenne hebdomadaire
  const average = sessionsWithDates.value.length / weeks
  
  // Formater le résultat
  weeklyAverage.value = average < 10 ? average.toFixed(1) : Math.round(average).toString()
}

onMounted(loadSessionCount)
</script> 
<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center py-4">
      <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
    </div>
    <div v-else class="flex flex-col">
      <p class="text-3xl font-bold text-foreground">{{ formatWeight(totalWeight) }}</p>
      <div class="flex items-center mt-1">
        <p class="text-sm text-muted-foreground">poids total soulevé</p>
        <div class="ml-auto bg-primary/10 text-primary text-xs px-2 py-1 rounded-full">
          <span>{{ formatWeight(averagePerSession) }}/séance</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useSupabaseClient } from '#imports'

const supabase = useSupabaseClient()
const totalWeight = ref(0)
const sessionCount = ref(0)
const loading = ref(true)

const averagePerSession = computed(() => {
  if (sessionCount.value === 0) return 0
  return Math.round(totalWeight.value / sessionCount.value)
})

const formatWeight = (weight) => {
  if (weight >= 1000000) {
    return `${(weight / 1000000).toFixed(1)}T`
  } else if (weight >= 1000) {
    return `${(weight / 1000).toFixed(1)}K`
  }
  return `${Math.round(weight)}kg`
}

const loadData = async () => {
  try {
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    // Récupérer le poids total
    const { data: exerciseData, error: exerciseError } = await supabase
      .from('exerciseset')
      .select('weight_kg, reps')
      .eq('user_id', user.id)

    if (exerciseError) throw exerciseError

    // Calculer le poids total : poids × répétitions pour chaque série
    totalWeight.value = exerciseData.reduce((total, set) => {
      return total + (set.weight_kg * set.reps)
    }, 0)

    // Récupérer le nombre de séances
    const { data: sessionData, error: sessionError } = await supabase
      .from('performedsession')
      .select('id', { count: 'exact' })
      .eq('user_id', user.id)

    if (sessionError) throw sessionError
    
    sessionCount.value = sessionData.length || 1 // Éviter la division par zéro
  } catch (e) {
    console.error('Erreur lors du chargement des données:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script> 
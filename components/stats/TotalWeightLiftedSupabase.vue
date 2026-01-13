<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center py-4">
      <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
    </div>
    <div v-else class="flex flex-col">
      <p class="text-3xl font-bold text-foreground">{{ formatWeight(totalWeight) }}</p>
      <div class="flex flex-wrap items-center justify-between gap-2 mt-1">
        <p class="text-sm text-muted-foreground">poids total soulevé</p>
        <div class="bg-primary/10 text-primary text-xs font-medium px-3 py-1.5 rounded-full border border-primary/20 shadow-sm">
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

    console.log('User ID:', user.id)

    // Utiliser la fonction SQL pour obtenir le poids total
    const { data: weightData, error: weightError } = await supabase
      .rpc('get_total_weight', { user_uuid: user.id })

    console.log('Weight Data:', weightData)
    console.log('Weight Error:', weightError)

    if (weightError) throw weightError

    totalWeight.value = weightData[0]?.total_weight || 0
    console.log('Total Weight:', totalWeight.value)

    // Récupérer le nombre de séances
    const { data: sessionData, error: sessionError } = await supabase
      .from('performedsession')
      .select('id', { count: 'exact' })
      .eq('user_id', user.id)

    console.log('Session Data:', sessionData)
    console.log('Session Error:', sessionError)

    if (sessionError) throw sessionError
    
    sessionCount.value = sessionData.length || 1 // Éviter la division par zéro
    console.log('Session Count:', sessionCount.value)
  } catch (e) {
    console.error('Erreur lors du chargement des données:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script> 
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
import { ref, watch, computed } from 'vue'
import { useSupabaseClient } from '#imports'
import { useUserStats } from '~/composables/useUserStats'

const props = defineProps({
  userId: {
    type: String,
    default: null
  }
})

const supabase = useSupabaseClient()
const { getTotalWeight, getSessionCount } = useUserStats()
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

const loadData = async (userId) => {
  if (!userId) return
  try {
    loading.value = true
    // Utiliser le cache pour améliorer les performances
    const [weightData, sessionCountData] = await Promise.all([
      getTotalWeight(userId),
      getSessionCount(userId)
    ])

    totalWeight.value = weightData.totalWeight || 0
    sessionCount.value = sessionCountData.count || 0

    // Fallback si le cache renvoie 0 mais qu'on a un poids total
    if (sessionCount.value === 0 && totalWeight.value > 0) {
      const { count } = await supabase
        .from('performedsession')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
      sessionCount.value = count || 0
    }
  } catch (e) {
    // Erreur silencieuse pour ne pas perturber l'UX
  } finally {
    loading.value = false
  }
}

watch(() => props.userId, (userId) => {
  if (userId) loadData(userId)
}, { immediate: true })
</script> 
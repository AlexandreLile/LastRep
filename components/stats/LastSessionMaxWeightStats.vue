<template>
  <div class="bg-muted/50 p-4 rounded-xl">
    <p class="text-sm text-muted-foreground">Poids max (dernière séance)</p>
    <div class="flex items-baseline space-x-2">
      <p class="text-2xl font-semibold">
        {{ lastMaxWeight !== null ? lastMaxWeight + ' kg' : '-' }}
      </p>
      <span v-if="weightDifference !== null"
        :class="[
          'flex items-center space-x-1 text-sm font-medium',
          weightDifference > 0 ? 'text-green-500' : weightDifference < 0 ? 'text-red-500' : 'text-muted-foreground'
        ]"
      >
        <svg v-if="weightDifference > 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" /></svg>
        <svg v-if="weightDifference < 0" xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" /></svg>
        <span>{{ Math.abs(weightDifference).toFixed(1) }} kg</span>
      </span>
      <span v-else class="text-muted-foreground text-sm">(pas de comparaison)</span>
    </div>
    <div class="mt-2">
      <p class="text-sm text-muted-foreground">Poids max historique</p>
      <p class="text-2xl font-semibold">{{ maxWeightAllTime }} kg</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useSupabaseClient } from '#imports'

const props = defineProps({
  exerciseId: {
    type: String,
    required: true
  }
})

const supabase = useSupabaseClient()
const lastSessionSets = ref([])
const prevSessionSets = ref([])
const loading = ref(true)

const lastMaxWeight = computed(() => {
  if (!lastSessionSets.value.length) return null
  return Math.max(...lastSessionSets.value.map(set => set.weight_kg))
})

const prevMaxWeight = computed(() => {
  if (!prevSessionSets.value.length) return null
  return Math.max(...prevSessionSets.value.map(set => set.weight_kg))
})

const weightDifference = computed(() => {
  if (lastMaxWeight.value === null || prevMaxWeight.value === null) return null
  return lastMaxWeight.value - prevMaxWeight.value
})

const maxWeightAllTime = computed(() => {
  if (!allSets.value.length) return 0
  return Math.max(...allSets.value.map(set => set.weight_kg))
})

const loadSets = async () => {
  loading.value = true
  try {
    const user = (await supabase.auth.getUser()).data.user
    if (!user) throw new Error('Utilisateur non authentifié')
    // 1. Récupérer toutes les séances de l'utilisateur triées par ended_at décroissant
    const { data: sessions, error: sessionError } = await supabase
      .from('performedsession')
      .select('id, started_at, ended_at')
      .eq('user_id', user.id)
      .not('ended_at', 'is', null)
      .order('ended_at', { ascending: false })
      .limit(20)
    if (sessionError) throw sessionError
    let found = 0
    let lastSets = []
    let prevSets = []
    for (const session of sessions) {
      // 2. Récupérer tous les sets de la séance
      const { data: allSets, error: setsError } = await supabase
        .from('exerciseset')
        .select('id, exercise_id, weight_kg, reps, created_at')
        .eq('performed_session_id', session.id)
        .eq('user_id', user.id)
      if (setsError) throw setsError
      // 3. Filtrer ceux de l'exercice
      const sets = allSets.filter(set => set.exercise_id === props.exerciseId)
      if (sets && sets.length > 0) {
        if (found === 0) {
          lastSets = sets
        } else if (found === 1) {
          prevSets = sets
        }
        found++
        if (found === 2) break
      }
    }
    lastSessionSets.value = lastSets
    prevSessionSets.value = prevSets
  } catch (e) {
    lastSessionSets.value = []
    prevSessionSets.value = []
    console.error('Erreur chargement sets pour max poids:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadSets)
watch(() => props.exerciseId, loadSets)
</script> 
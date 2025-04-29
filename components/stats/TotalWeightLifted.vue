<template>
  <div class="flex items-center justify-center bg-gray-100 p-4 rounded-lg">
    <div class="text-center">
      <p class="text-2xl font-bold text-primary">{{ formatWeight(totalWeight) }}</p>
      <p class="text-sm text-muted-foreground">Poids total soulevé</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'

const supabase = useSupabaseClient()
const totalWeight = ref(0)
const loading = ref(true)

const formatWeight = (weight) => {
  if (weight >= 100000) {
    return `${(weight / 1000).toFixed(1)} T`
  }
  return `${weight} kg`
}

const loadTotalWeight = async () => {
  try {
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    const { data, error } = await supabase
      .from('exerciseset')
      .select('weight_kg, reps')
      .eq('user_id', user.id)

    if (error) throw error

    // Calculer le poids total : poids × répétitions pour chaque série
    totalWeight.value = data.reduce((total, set) => {
      return total + (set.weight_kg * set.reps)
    }, 0)
  } catch (e) {
    console.error('Erreur lors du chargement du poids total:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadTotalWeight)
</script> 
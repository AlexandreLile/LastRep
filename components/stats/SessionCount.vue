<template>
  <div class="flex items-center justify-center bg-gray-100 p-4 rounded-lg">
    <div class="text-center">
      <p class="text-2xl font-bold text-primary">{{ sessionCount }}</p>
      <p class="text-sm text-muted-foreground">Séances effectuées</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'

const supabase = useSupabaseClient()
const sessionCount = ref(0)
const loading = ref(true)

const loadSessionCount = async () => {
  try {
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    const { data, error } = await supabase
      .from('performedsession')
      .select('id', { count: 'exact' })
      .eq('user_id', user.id)

    if (error) throw error

    sessionCount.value = data.length
  } catch (e) {
    console.error('Erreur lors du chargement du nombre de séances:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadSessionCount)
</script> 
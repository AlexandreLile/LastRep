<template>
  <div class="flex items-center justify-center  p-4 rounded-lg">
    <div class="text-center">
      <CalendarCheck class="h-6 w-6 text-primary mx-auto mb-2" />
      <p class="text-sm text-muted-foreground">Séances</p>
      <p class="text-2xl font-bold text-primary">{{ sessionCount }}</p>
      
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'
import { CalendarCheck } from 'lucide-vue-next'

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
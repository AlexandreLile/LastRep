<template>
  <div class="min-h-screen bg-background">
    <div class="container mx-auto px-6 py-4">
      <slot />
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useSupabaseClient } from '#imports'
import { usePerformedSession } from '~/composables/usePerformedSession'

const supabase = useSupabaseClient()
const { setupOfflineSync } = usePerformedSession(supabase)

onMounted(() => {
  setupOfflineSync()
})
defineOptions({
  name: 'StartSessionLayout'
})
</script> 
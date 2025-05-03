<template>
  <div class="space-y-8">
    <div class="flex items-center justify-between">
      <div class="space-y-1">
        <h2 class="text-2xl font-semibold tracking-tight">
          Historique
        </h2>
        <p class="text-sm text-muted-foreground">
          Consultez l'historique de vos séances d'entraînement
        </p>
      </div>
    </div>

    <!-- État de chargement -->
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <!-- Message d'erreur -->
    <div v-else-if="error" class="flex items-center justify-center p-4 text-sm text-red-500 bg-red-50 rounded-lg">
      {{ error }}
    </div>

    <!-- Aucune session -->
    <div v-else-if="sessions.length === 0" class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-muted/50 rounded-lg">
      <Calendar class="w-12 h-12 text-muted-foreground/50" />
      <p class="text-center text-muted-foreground">
        Vous n'avez pas encore d'historique d'entraînement
      </p>
      <Button @click="navigateTo('/seances')">
        Commencer une séance
      </Button>
    </div>

    <!-- Liste des sessions -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <SessionHistoryCard 
        v-for="session in sessions" 
        :key="session.id" 
        :session="session"
        @delete="handleDeleteSession"
      />
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useSessionHistory } from '~/composables/useSessionHistory'
import SessionHistoryCard from '~/components/sessions/SessionHistoryCard.vue'
import { Button } from '@/components/ui/button'
import { Calendar } from 'lucide-vue-next'

const { sessions, loading, error, loadSessions, deleteSession } = useSessionHistory()

const handleDeleteSession = async (sessionId) => {
  try {
    await deleteSession(sessionId)
  } catch (e) {
    console.error("Erreur lors de la suppression:", e)
  }
}

onMounted(loadSessions)
</script> 
<template>
  <div class="bg-card rounded-xl p-6 cursor-pointer relative overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg group">
    <!-- Effet de bordure néon -->
    <div class="absolute inset-0 rounded-xl bg-primary/20 blur-md transition-all duration-300 group-hover:bg-primary/30 group-hover:blur-lg"></div>
    <div class="absolute inset-0 rounded-xl bg-gradient-to-r from-primary/50 via-primary/30 to-primary/50 animate-[pulse_2s_ease-in-out_infinite] group-hover:from-primary/60 group-hover:via-primary/40 group-hover:to-primary/60"></div>
    <div class="absolute inset-0 rounded-xl bg-gradient-to-br from-primary/40 to-transparent animate-[glow_3s_ease-in-out_infinite] group-hover:from-primary/50 group-hover:to-transparent"></div>
    <div class="absolute inset-[1px] rounded-xl bg-card"></div>

    <div class="relative flex flex-col h-full">
      <div class="flex items-start justify-between mb-4">
        <div class="flex items-center space-x-3">
          <div class="p-2 rounded-full bg-primary/20 transition-all duration-300 group-hover:bg-primary/30 group-hover:scale-110">
            <Dumbbell class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12" />
          </div>
          <div>
            <h3 class="text-lg font-medium text-foreground transition-colors duration-300 group-hover:text-primary">{{ session.title }}</h3>
            <p class="text-xs text-muted-foreground">{{ formatDate(session.ended_at) }}</p>
          </div>
        </div>
        
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <Button 
              variant="ghost" 
              size="icon"
              @click.stop
              class="text-red-500 hover:text-red-600 hover:bg-red-50 transition-all duration-300"
            >
              <Trash2 class="h-4 w-4" />
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Êtes-vous sûr de vouloir supprimer cette séance ?</AlertDialogTitle>
              <AlertDialogDescription>
                Cette action est irréversible. Toutes les données de cette séance du {{ formatDate(session.ended_at) }} seront définitivement supprimées.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Annuler</AlertDialogCancel>
              <AlertDialogAction @click="handleDelete" class="bg-red-600 hover:bg-red-700">Supprimer</AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>

      <div class="grid grid-cols-2 gap-4 mb-4">
        <div>
          <p class="text-sm text-muted-foreground">Durée</p>
          <p class="text-base font-medium transition-colors duration-300 group-hover:text-foreground">{{ formatDuration(session.started_at, session.ended_at) }}</p>
        </div>
        <div>
          <p class="text-sm text-muted-foreground">Exercices</p>
          <p class="text-base font-medium transition-colors duration-300 group-hover:text-foreground">{{ session.exercise_count || 0 }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Button } from '@/components/ui/button'
import { Trash2, Dumbbell } from 'lucide-vue-next'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog'

const props = defineProps({
  session: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['delete'])

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long', 
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatDuration = (startDate, endDate) => {
  const start = new Date(startDate)
  const end = new Date(endDate)
  const diffMs = end - start
  
  // Convertir en minutes
  const diffMinutes = Math.floor(diffMs / 60000)
  
  if (diffMinutes < 60) {
    return `${diffMinutes} min`
  } else {
    const hours = Math.floor(diffMinutes / 60)
    const minutes = diffMinutes % 60
    return `${hours}h ${minutes}min`
  }
}

const handleDelete = () => {
  emit('delete', props.session.id)
}
</script>

<style scoped>
@keyframes pulse {
  0%, 100% {
    opacity: 0.3;
  }
  50% {
    opacity: 0.7;
  }
}

@keyframes glow {
  0%, 100% {
    opacity: 0.2;
    transform: scale(1);
  }
  50% {
    opacity: 0.4;
    transform: scale(1.02);
  }
}
</style> 
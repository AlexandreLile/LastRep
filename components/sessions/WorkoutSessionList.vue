<template>
  <div class="space-y-6">
    <!-- Liste des séances -->
    <div v-if="loading" class="flex justify-center">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center">
      {{ error.message }}
    </div>

    <div v-else-if="workoutSessions.length === 0" class="text-center text-muted-foreground">
      Aucune séance trouvée
    </div>

    <div v-else class="space-y-6">
      <div 
        v-for="session in sortedSessions" 
        :key="session.id" 
        class="bg-card rounded-xl p-6 cursor-pointer relative overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg"
        @click="viewSession(session.id)"
      >
        <!-- Effet de bordure néon -->
        <div class="absolute inset-0 rounded-xl bg-primary/20 blur-md transition-all duration-300 group-hover:bg-primary/30 group-hover:blur-lg"></div>
        <div class="absolute inset-0 rounded-xl bg-gradient-to-r from-primary/50 via-primary/30 to-primary/50 animate-[pulse_2s_ease-in-out_infinite] group-hover:from-primary/60 group-hover:via-primary/40 group-hover:to-primary/60"></div>
        <div class="absolute inset-0 rounded-xl bg-gradient-to-br from-primary/40 to-transparent animate-[glow_3s_ease-in-out_infinite] group-hover:from-primary/50 group-hover:to-transparent"></div>
        <div class="absolute inset-[1px] rounded-xl bg-card"></div>

        <div class="relative flex flex-col h-full">
          <div class="flex flex-wrap gap-4 items-start mb-4">
            <div class="flex items-center space-x-3 flex-1 max-w-[300px]">
              <div class="p-2 rounded-full bg-primary/20 transition-all duration-300 group-hover:bg-primary/30 group-hover:scale-110">
                <Dumbbell class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12" />
              </div>
              <div>
                <h3 class="text-lg font-medium text-foreground transition-colors duration-300 group-hover:text-primary">{{ session.title }}</h3>
                <p class="text-xs text-muted-foreground">Dernière modification: {{ formatDate(session.updated_at) }}</p>
              </div>
            </div>
            <div class="hidden sm:flex items-center gap-2">
              <Button 
                variant="default" 
                size="sm" 
                class="flex items-center gap-1.5 bg-primary hover:bg-primary/90 text-primary-foreground" 
                @click.stop="navigateToSession(session.id)"
              >
                <Play class="h-4 w-4" />
                <span class="text-sm font-medium">Démarrer</span>
              </Button>
              <Button 
                variant="ghost" 
                size="sm" 
                class="flex items-center gap-1 text-foreground hover:text-primary hover:bg-primary/10" 
                @click.stop="editSession(session)"
              >
                <Pencil class="h-4 w-4" />
                <span class="text-sm font-medium">Modifier</span>
              </Button>
            </div>
          </div>
          
          <p class="text-muted-foreground mb-4 flex-grow line-clamp-2 transition-colors duration-300 group-hover:text-gray-700">{{ session.notes }}</p>
          
          <div class="space-y-2">
            <div class="flex flex-wrap gap-2">
              <span 
                v-for="exercise in session.exercises" 
                :key="exercise.id" 
                class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full transition-all duration-300 group-hover:bg-primary/10 group-hover:text-primary group-hover:scale-105"
              >
                {{ exercise.exercise.name }}
              </span>
            </div>
          </div>

          <!-- Actions visibles seulement sur mobile -->
          <div class="sm:hidden flex justify-end gap-2 mt-4">
            <Button 
              variant="default" 
              size="sm" 
              class="flex items-center gap-1.5 bg-primary hover:bg-primary/90 text-primary-foreground px-3 py-1 font-medium" 
              @click.stop="navigateToSession(session.id)"
            >
              <Play class="h-3.5 w-3.5" />
              <span class="text-xs">Démarrer</span>
            </Button>
            <Button 
              variant="ghost" 
              size="sm" 
              class="flex items-center gap-1 text-foreground bg-muted hover:bg-primary/20 hover:text-primary px-3 py-1 font-medium" 
              @click.stop="editSession(session)"
            >
              <Pencil class="h-3.5 w-3.5" />
              <span class="text-xs">Éditer</span>
            </Button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Pencil, Dumbbell, Play } from 'lucide-vue-next';
import { useRouter } from 'vue-router';
import { computed, onMounted } from 'vue';


const router = useRouter();
const user = useSupabaseUser();
const supabase = useSupabaseClient();
const { 
  workoutSessions, 
  loading, 
  error, 
  getWorkoutSessions
} = useWorkoutSessions(user);

// Séances triées par date de modification (plus récentes en premier)
const sortedSessions = computed(() => {
  return [...workoutSessions.value].sort((a, b) => {
    return new Date(b.updated_at) - new Date(a.updated_at);
  });
});

// Rafraîchir la liste au montage
onMounted(async () => {
  await getWorkoutSessions();
  console.log('Workout sessions:', workoutSessions.value);
});

const viewSession = (sessionId) => {
  router.push(`/seances/${sessionId}/train`);
};

const navigateToSession = async (sessionId) => {
  try {
    const supabase = useSupabaseClient()
    const { prepareSession } = usePerformedSession(supabase)
    const userId = (await supabase.auth.getUser()).data.user.id
    prepareSession(sessionId, userId)
    router.push(`/seances/${sessionId}/start`)
  } catch (e) {
    console.error('Erreur lors du démarrage de la séance:', e)
  }
};

// Gérer l'édition d'une séance
const editSession = (session) => {
  router.push(`/seances/${session.id}/edit`);
};

const formatDate = (dateString) => {
  const date = new Date(dateString);
  return date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });
};
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

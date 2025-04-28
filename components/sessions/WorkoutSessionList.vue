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

    <div v-else class="grid gap-4">
      <Card v-for="session in sortedSessions" :key="session.id" class="hover:bg-muted/50 transition-colors">
        <div class="cursor-pointer" @click="navigateToSession(session.id)">
          <CardHeader>
            <div class="flex items-center justify-between">
              <CardTitle>{{ session.title }}</CardTitle>
              <div class="flex gap-2">
                <Button variant="ghost" size="icon" @click.stop="editSession(session)">
                  <Pencil class="h-4 w-4" />
                </Button>
              </div>
            </div>
            <CardDescription>
              {{ new Date(session.date).toLocaleDateString('fr-FR') }}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p class="text-sm text-muted-foreground">{{ session.notes }}</p>
          </CardContent>
        </div>
      </Card>
    </div>
  </div>
</template>

<script setup>
import { Pencil } from 'lucide-vue-next';
import { useRouter } from 'vue-router';
import { computed, onMounted } from 'vue';

const router = useRouter();
const user = useSupabaseUser();
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
onMounted(() => {
  getWorkoutSessions();
  console.log('Workout sessions:', workoutSessions.value);
});

const navigateToSession = (sessionId) => {
  console.log('Navigating to session:', sessionId);
  router.push(`/seances/${sessionId}/train`);
};

// Gérer l'édition d'une séance
const editSession = (session) => {
  router.push(`/seances/${session.id}/edit`);
};
</script>

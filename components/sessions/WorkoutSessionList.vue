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
      <Card v-for="session in workoutSessions" :key="session.id" class="hover:bg-muted/50 transition-colors">
        <CardHeader>
          <div class="flex items-center justify-between">
            <CardTitle>{{ session.title }}</CardTitle>
            <div class="flex gap-2">
              <Button variant="ghost" size="icon" @click="editSession(session)">
                <Pencil class="h-4 w-4" />
              </Button>
              <Button variant="ghost" size="icon" @click="deleteSession(session.id)">
                <Trash2 class="h-4 w-4" />
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
      </Card>
    </div>
  </div>
</template>

<script setup>
import { Pencil, Trash2 } from 'lucide-vue-next';


const user = useSupabaseUser();
const { 
  workoutSessions, 
  loading, 
  error, 
  getWorkoutSession, 
  deleteWorkoutSession 
} = useWorkoutSessions(user);

// Rafraîchir la liste au montage
onMounted(() => {
  getWorkoutSession();
});

// Gérer la suppression d'une séance
const deleteSession = async (sessionId) => {
  if (confirm('Êtes-vous sûr de vouloir supprimer cette séance ?')) {
    const result = await deleteWorkoutSession(sessionId);
    if (result.success) {
      // La liste se met à jour automatiquement grâce à la réactivité
    } else {
      console.error('Erreur lors de la suppression:', result.error);
    }
  }
};

// Gérer l'édition d'une séance (à implémenter)
const editSession = (session) => {
  // TODO: Implémenter l'édition
  console.log('Édition de la séance:', session);
};
</script>

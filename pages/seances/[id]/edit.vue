<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="session" class="space-y-8">
      <!-- Header -->
      <div class="mb-8">
        <h2 class="text-2xl font-semibold text-gray-900">{{ formData.title }}</h2>
      </div>

      <!-- Formulaire d'édition -->
      <div class="bg-white rounded-xl p-8">
        <form @submit.prevent="handleSubmit" class="space-y-8">
          <div class="space-y-6">
            <div>
              <h3 class="text-lg font-medium">Informations générales</h3>
              <p class="text-sm text-muted-foreground">Modifiez les informations de votre séance.</p>
            </div>

            <div class="space-y-4">
              <div>
                <Label for="title">Titre</Label>
                <Input
                  id="title"
                  v-model="formData.title"
                  type="text"
                  required
                />
              </div>

              <div>
                <label for="notes">Note</label>
                <Textarea
                  id="notes"
                  v-model="formData.notes"
                  rows="4"
                ></textarea>
              </div>
            </div>
          </div>

          <!-- Section des exercices -->
          <div class="space-y-6">
            <div>
              <h3 class="text-lg font-medium">Exercices</h3>
              <p class="text-sm text-muted-foreground">Gérez les exercices de votre séance.</p>
            </div>

            <div class="flex justify-end">
              <Button
                type="button"
                variant="outline"
                @click="showAddExercise = true"
              >
                Ajouter des exercices
              </Button>
            </div>

            <!-- Liste des exercices avec drag and drop -->
            <div v-if="currentExercises.length > 0" class="space-y-3">
              <draggable
                v-model="currentExercises"
                item-key="id"
                @end="handleDragEnd"
                class="space-y-3"
                :animation="150"
                ghost-class="opacity-50"
              >
                <template #item="{ element }">
                  <div class="relative bg-white rounded-xl p-4 cursor-move group overflow-hidden">
                    <!-- Effet de bordure néon -->
                    <div class="absolute inset-0 rounded-xl bg-primary/20 blur-md transition-all duration-300 group-hover:bg-primary/30 group-hover:blur-lg"></div>
                    <div class="absolute inset-0 rounded-xl bg-gradient-to-r from-primary/50 via-primary/30 to-primary/50 animate-[pulse_2s_ease-in-out_infinite] group-hover:from-primary/60 group-hover:via-primary/40 group-hover:to-primary/60"></div>
                    <div class="absolute inset-0 rounded-xl bg-gradient-to-br from-primary/40 to-transparent animate-[glow_3s_ease-in-out_infinite] group-hover:from-primary/50 group-hover:to-transparent"></div>
                    <div class="absolute inset-[1px] rounded-xl bg-white"></div>

                    <div class="relative flex items-center justify-between">
                      <div class="flex items-center gap-3">
                        <div class="p-2 rounded-full bg-primary/20 transition-all duration-300 group-hover:bg-primary/30">
                          <GripVertical class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12" />
                        </div>
                        <div>
                          <h4 class="text-base font-medium text-gray-900 transition-colors duration-300 group-hover:text-primary">{{ element.exercise?.name }}</h4>
                          <span class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full transition-all duration-300 group-hover:bg-primary/10 group-hover:text-primary">
                            {{ element.exercise?.primary_muscle }}
                          </span>
                        </div>
                      </div>
                      <Button
                        variant="ghost"
                        size="icon"
                        @click.prevent.stop="removeExercise(element.id)"
                      >
                        <Trash2 class="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </template>
              </draggable>
            </div>
            <div v-else class="text-center py-8 text-muted-foreground">
              Aucun exercice ajouté
            </div>
          </div>

          <div class="flex flex-wrap justify-end items-center gap-3 sm:flex-nowrap">
            <div class="w-full sm:w-auto">
              <Button
                type="button"
                variant="outline"
                @click="router.push('/seances')"
                class="w-full sm:w-auto"
              >
                Annuler
              </Button>
            </div>

            <div class="w-full sm:w-auto">
              <Button
                type="submit"
                :disabled="saving"
                class="w-full sm:w-auto"
              >
                <span v-if="saving">Enregistrement...</span>
                <span v-else>Enregistrer</span>
              </Button>
            </div>

            <div class="w-full sm:w-auto">
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <Button 
                    variant="destructive"
                    class="w-full sm:w-auto"
                  >
                    Supprimer
                  </Button>
                </AlertDialogTrigger>
                <AlertDialogContent>
                  <AlertDialogHeader>
                    <AlertDialogTitle>Etes vous sûr de vouloir supprimer cette séance ?</AlertDialogTitle>
                    <AlertDialogDescription>
                      Cette action est irréversible.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>Annuler</AlertDialogCancel>
                    <AlertDialogAction @click="deleteSession" variant="destructive">Supprimer</AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            </div>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal d'ajout d'exercices -->
    <Dialog :open="showAddExercise" @update:open="showAddExercise = false">
      <DialogContent class="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Ajouter des exercices</DialogTitle>
        </DialogHeader>
        <AddExerciseToSession
          :session-id="route.params.id"
          @close="showAddExercise = false"
          @update-exercises="handleExercisesUpdate"
        />
      </DialogContent>
    </Dialog>
  </div>
</template>

<script setup>
import { useWorkoutSessions } from '~/composables/useWorkoutSession';
import { useWorkoutExercise } from '~/composables/useWorkoutExercise';
import { Trash2, GripVertical } from 'lucide-vue-next';
import AddExerciseToSession from '@/components/exercises/AddExerciseToSession.vue';
import draggable from 'vuedraggable';
import { useSupabaseClient } from '#imports';
import { useSupabaseUser } from '#imports';
import { useRoute, useRouter } from 'vue-router';
import { ref, onMounted } from 'vue';

const route = useRoute();
const router = useRouter();
const supabase = useSupabaseClient();
const { getWorkoutSession, editWorkoutSession, deleteWorkoutSession } = useWorkoutSessions(useSupabaseUser());
const { 
  workoutExercises: currentExercises,
  getWorkoutExercises,
  removeWorkoutExercise,
  updateExerciseOrder
} = useWorkoutExercise();

const session = ref(null);
const loading = ref(true);
const saving = ref(false);
const error = ref(null);
const showAddExercise = ref(false);

const formData = ref({
  title: '',
  notes: ''
});

const loadSession = async () => {
  try {
    loading.value = true;
    const { data, error: sessionError } = await getWorkoutSession(route.params.id);
    if (sessionError) throw sessionError;
    session.value = data;
    formData.value = {
      title: data.title,
      notes: data.notes || ''
    };
    // Charger les exercices de la séance
    await getWorkoutExercises(route.params.id);
  } catch (e) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
};

const handleSubmit = async () => {
  try {
    saving.value = true;
    const result = await editWorkoutSession(route.params.id, formData.value);
    if (!result.success) {
      throw new Error(result.error || 'Une erreur est survenue lors de l\'édition de la séance');
    }
    // Rediriger vers la page d'entraînement après l'enregistrement
    router.push(`/seances/${route.params.id}/train`);
  } catch (e) {
    console.error('Erreur lors de l\'édition:', e);
    error.value = e.message;
  } finally {
    saving.value = false;
  }
};

// Gérer la suppression d'un exercice
const removeExercise = async (workoutExerciseId) => {
  try {
    const result = await removeWorkoutExercise(workoutExerciseId);
    if (!result.success) {
      console.error('Erreur lors de la suppression de l\'exercice:', result.error);
      return;
    }
    // Mettre à jour la liste des exercices localement
    currentExercises.value = currentExercises.value.filter(
      exercise => exercise.id !== workoutExerciseId
    );
  } catch (e) {
    console.error('Erreur lors de la suppression de l\'exercice:', e);
  }
};

// Gérer le drag and drop
const handleDragEnd = async () => {
  try {
    // Mettre à jour l'ordre de chaque exercice
    for (let i = 0; i < currentExercises.value.length; i++) {
      const exercise = currentExercises.value[i];
      const result = await updateExerciseOrder(exercise.id, i + 1);
      if (!result.success) {
        throw new Error(result.error);
      }
    }
  } catch (e) {
    console.error('Erreur lors de la mise à jour de l\'ordre:', e);
    error.value = e.message;
  }
};

// Gérer la mise à jour des exercices
const handleExercisesUpdate = async (newExercises) => {
  currentExercises.value = newExercises;
};

const deleteSession = async () => {
  
    try {
      // D'abord, mettre à jour toutes les performedsession associées pour retirer la référence
      const { error: updateError } = await supabase
        .from('performedsession')
        .update({ workout_session_id: null })
        .eq('workout_session_id', route.params.id)

      if (updateError) throw updateError

      // Ensuite, supprimer la workout session
      const { error: deleteError } = await deleteWorkoutSession(route.params.id)
      if (deleteError) throw deleteError

      router.push('/seances')
    } catch (e) {
      console.error('Erreur lors de la suppression de la séance:', e);
      error.value = e.message;
    }
  
};

onMounted(loadSession);
</script> 
<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="session" class="space-y-6">
      <!-- Formulaire d'édition -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <div class="space-y-4">
            <div>
              <Label for="title" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Titre</label>
              <Input
                id="title"
                v-model="formData.title"
                type="text"
                class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-primary focus:ring-primary dark:bg-gray-700 dark:text-white sm:text-sm"
                required
              />
            </div>

            <div>
              <label for="notes" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Note</label>
              <Textarea
                id="notes"
                v-model="formData.notes"
                rows="4"
                class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-primary focus:ring-primary dark:bg-gray-700 dark:text-white sm:text-sm"
              ></textarea>
            </div>
          </div>

          <!-- Section des exercices -->
          <div class="space-y-4">
            <div class="flex items-center justify-between">
              <h3 class="text-lg font-medium">Exercices</h3>
              <Button
                type="button"
                variant="outline"
                @click="showAddExercise = true"
              >
                Ajouter des exercices
              </Button>
            </div>

            <!-- Liste des exercices avec drag and drop -->
            <div v-if="currentExercises.length > 0" class="space-y-2">
              <draggable
                v-model="currentExercises"
                item-key="id"
                @end="handleDragEnd"
                class="space-y-2"
                :animation="150"
                ghost-class="ghost"
              >
                <template #item="{ element }">
                  <div
                    class="flex items-center justify-between p-3 border rounded-lg cursor-move bg-white dark:bg-gray-800"
                  >
                    <div class="flex items-center space-x-3">
                      <GripVertical class="h-5 w-5 text-gray-400" />
                      <div>
                        <h4 class="font-medium">{{ element.exercise?.name }}</h4>
                        <p class="text-sm text-muted-foreground">
                          Muscle principal : {{ element.exercise?.primary_muscle }}
                        </p>
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
                </template>
              </draggable>
            </div>
            <div v-else class="text-center text-muted-foreground py-4">
              Aucun exercice ajouté
            </div>
          </div>

          <div class="flex justify-end gap-4">
            <button
              type="button"
              @click="router.push('/seances')"
              class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
            >
              Annuler
            </button>



   

            
            <button
              type="submit"
              :disabled="saving"
              class="px-4 py-2 text-sm font-medium text-white bg-primary rounded-md shadow-sm hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50"
            >
              <span v-if="saving">Enregistrement...</span>
              <span v-else>Enregistrer</span>
            </button>

            <AlertDialog>
    <AlertDialogTrigger as-child>
      <Button variant="destructive">
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
        <AlertDialogAction class="bg-red-500 text-white hover:bg-red-600" @click="deleteSession"  variant="destructive">supprimer</AlertDialogAction>
             
   
      </AlertDialogFooter>
    </AlertDialogContent>
  </AlertDialog>


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
<template>
  <div class="container mx-auto px-2 sm:px-4 py-8">
    <!-- Loader -->
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <!-- Erreur -->
    <div v-else-if="error" class="bg-card rounded-xl p-6 text-center">
      <div class="w-12 h-12 flex-shrink-0 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <AlertTriangle class="h-6 w-6 text-red-500" />
      </div>
      <h3 class="text-lg font-medium text-red-500 mb-2">Une erreur est survenue</h3>
      <p class="text-muted-foreground">{{ error }}</p>
    </div>

    <!-- Contenu principal -->
    <div v-else-if="session" class="space-y-6">
      <!-- Header amélioré -->
      <div class="mb-6 bg-card rounded-xl p-4 sm:p-6">
        <div class="flex items-center gap-4">
          <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
            <Edit class="h-6 w-6 text-primary" />
          </div>
          <div>
            <h2 class="text-2xl font-bold text-foreground">Modifier la séance</h2>
            <p class="text-sm text-muted-foreground">Personnalisez et réorganisez votre programme d'entraînement</p>
          </div>
        </div>
      </div>

      <!-- Formulaire d'édition -->
      <div class="bg-card rounded-xl p-3 sm:p-6 shadow-sm border border-border100">
        <form @submit.prevent="handleSubmit" class="space-y-5">
          <div class="space-y-4">
            <div class="flex items-center gap-3 mb-3">
              <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                <FileText class="w-5 h-5 text-primary" />
              </div>
              <div>
                <h3 class="text-lg font-semibold">Informations générales</h3>
                <p class="text-sm text-muted-foreground">Modifiez les informations de votre séance</p>
              </div>
            </div>

            <div class="space-y-4">
              <div>
                <Label for="title" class="font-medium">Titre</Label>
                <Input
                  id="title"
                  v-model="formData.title"
                  type="text"
                  required
                  class="w-full"
                />
              </div>

              <div>
                <Label for="notes" class="font-medium">Notes</Label>
                <Textarea
                  id="notes"
                  v-model="formData.notes"
                  rows="3"
                  class="w-full resize-none"
                  placeholder="Ajoutez des informations supplémentaires ici..."
                ></Textarea>
              </div>
            </div>
          </div>

          <!-- Section des exercices -->
          <div class="space-y-4 pt-3">
            <div class="flex items-center flex-wrap gap-3 mb-3">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                  <Dumbbell class="w-5 h-5 text-primary" />
                </div>
                <div>
                  <h3 class="text-lg font-semibold">Exercices</h3>
                  <p class="text-sm text-muted-foreground">Gérez les exercices de votre séance</p>
                </div>
              </div>
              
              <div class="mt-2 sm:mt-0 w-full sm:w-auto ml-auto">
                <Button
                  type="button"
                  class="flex items-center gap-2 shadow-sm hover:shadow transition-all duration-300 w-full sm:w-auto"
                  @click="showAddExercise = true"
                >
                  <Plus class="h-4 w-4" />
                  <span class="hidden sm:inline">Ajouter des exercices</span>
                  <span class="sm:hidden">Ajouter</span>
                </Button>
              </div>
            </div>

            <!-- Instructions de drag and drop -->
            <div v-if="currentExercises.length > 1" class="text-sm text-center p-2 bg-primary/5 rounded-lg mb-2 text-primary/80 flex items-center justify-center gap-2">
              <GripVertical class="h-4 w-4" />
              <span>Maintenez et glissez pour réorganiser les exercices</span>
            </div>

            <!-- Liste des exercices avec drag and drop -->
            <div v-if="currentExercises.length > 0" class="space-y-3">
              <draggable
                v-model="currentExercises"
                item-key="id"
                @start="dragStart"
                @end="handleDragEnd"
                class="space-y-3 min-h-[100px]"
                :animation="250"
                ghost-class="ghost-item"
                chosen-class="dragging-item"
                handle=".drag-handle"
              >
                <template #item="{ element, index }">
                  <div class="relative bg-card rounded-xl p-3 sm:p-4 group overflow-hidden border border-border200 hover:shadow-lg transition-all duration-300 transform-gpu will-change-transform"
                    :class="{'scale-[0.99] z-10': isDragging && draggedItemId === element.id, 'hover:translate-y-[-2px]': !isDragging}">
                    <!-- Effet de bordure néon -->
                    <div class="absolute left-0 top-0 bottom-0 w-1.5 bg-primary/70 rounded-l-xl group-hover:bg-primary transition-all duration-300"></div>
                    
                    <!-- Indicateur d'ordre -->
                    <div class="absolute left-3 top-3 flex items-center justify-center h-5 w-5 rounded-full bg-primary/10 text-xs font-semibold text-primary">
                      {{ index + 1 }}
                    </div>
                    
                    <div class="relative flex flex-col sm:flex-row sm:items-center justify-between gap-3 pl-6">
                      <!-- Informations sur l'exercice et poignée de drag -->
                      <div class="flex items-center gap-3 w-full">
                        <div class="p-2 rounded-full bg-primary/10 transition-all duration-300 group-hover:bg-primary/20 drag-handle cursor-grab active:cursor-grabbing shadow-sm hover:shadow focus:shadow-xl flex items-center justify-center">
                          <GripVertical class="h-5 w-5 text-primary transition-transform duration-300 group-hover:scale-110" />
                        </div>
                        <div class="flex-1">
                          <h4 class="text-base font-semibold text-foreground transition-colors duration-300 group-hover:text-primary">{{ element.exercise?.name }}</h4>
                          <div class="flex items-center justify-between mt-2">
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary">
                              {{ element.exercise?.primary_muscle }}
                            </span>
                            
                            <!-- Bouton supprimer placé à droite de la catégorie musculaire -->
                            <Button
                              variant="ghost"
                              size="sm"
                              class="h-6 w-6 flex items-center justify-center rounded-full hover:bg-red-50 hover:text-red-500 transition-all duration-300"
                              @click.prevent.stop="openDeleteModal(element.id, element.exercise?.name)"
                            >
                              <Trash2 class="h-3.5 w-3.5" />
                            </Button>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    <!-- Effet de brillance au hover -->
                    <div class="absolute inset-0 -z-10 bg-gradient-to-r from-primary/0 via-primary/5 to-primary/0 opacity-0 group-hover:opacity-100 blur-xl transition-opacity duration-700"></div>
                  </div>
                </template>
              </draggable>
            </div>
            <div v-else class="flex flex-col items-center justify-center p-6 sm:p-8 bg-muted rounded-xl border border-dashed border-border">
              <div class="w-16 h-16 bg-muted rounded-full flex items-center justify-center mb-4">
                <Dumbbell class="h-8 w-8 text-muted-foreground" />
              </div>
              <p class="text-muted-foreground text-center">Aucun exercice n'a été ajouté à cette séance</p>
            </div>
          </div>

          <!-- Boutons d'action -->
          <div class="bg-muted -mx-3 sm:-mx-6 -mb-3 sm:-mb-6 p-4 sm:p-6 rounded-b-xl border-t border-border flex flex-col sm:flex-row justify-between items-center gap-3 mt-6">
            <!-- Bouton Supprimer à gauche et visible en premier sur mobile -->
            <div class="w-full sm:w-auto order-1 sm:order-1">
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <Button 
                    variant="destructive"
                    class="w-full sm:w-auto flex items-center justify-center gap-2"
                  >
                    <Trash2 class="h-5 w-5" />
                    <span>Supprimer</span>
                  </Button>
                </AlertDialogTrigger>
                <AlertDialogContent>
                  <AlertDialogHeader>
                    <AlertDialogTitle>Etes vous sûr de vouloir supprimer cette séance ?</AlertDialogTitle>
                    <AlertDialogDescription>
                      Cette action est irréversible et supprimera définitivement cette séance.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>Annuler</AlertDialogCancel>
                    <AlertDialogAction @click="deleteSession" variant="destructive">Supprimer</AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            </div>
            
            <div class="flex flex-col sm:flex-row gap-3 w-full sm:w-auto order-2 sm:order-2">
              <!-- Bouton Annuler -->
              <div class="w-full sm:w-auto">
                <Button
                  type="button"
                  variant="outline"
                  @click="router.push('/seances')"
                  class="w-full sm:w-auto group"
                >
                  <ArrowLeft class="h-4 w-4 mr-2 transition-transform duration-300 group-hover:-translate-x-1" />
                  Annuler
                </Button>
              </div>

              <!-- Bouton Enregistrer -->
              <div class="w-full sm:w-auto">
                <Button
                  type="submit"
                  :disabled="saving"
                  class="w-full sm:w-auto"
                >
                  <Save v-if="!saving" class="h-4 w-4 mr-2" />
                  <Loader2 v-else class="h-4 w-4 mr-2 animate-spin" />
                  {{ saving ? 'Enregistrement...' : 'Enregistrer' }}
                </Button>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal d'ajout d'exercices -->
    <Dialog :open="showAddExercise" @update:open="showAddExercise = false">
      <DialogContent class="sm:max-w-lg max-w-[95vw] w-full overflow-hidden p-4 sm:p-6">
        <DialogHeader>
          <DialogTitle>Ajouter des exercices</DialogTitle>
          <DialogDescription>
            Sélectionnez des exercices à ajouter à votre séance
          </DialogDescription>
        </DialogHeader>
        <AddExerciseToSession
          :session-id="route.params.id"
          @close="showAddExercise = false"
          @update-exercises="handleExercisesUpdate"
        />
      </DialogContent>
    </Dialog>

    <!-- Modale de confirmation pour la suppression d'exercice -->
    <AlertDialog :open="showDeleteExerciseModal" @update:open="showDeleteExerciseModal = false">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Supprimer cet exercice ?</AlertDialogTitle>
          <AlertDialogDescription>
            Êtes-vous sûr de vouloir supprimer "{{ exerciseToDeleteName }}" de cette séance ?
            <br>Cette action est irréversible.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel @click="showDeleteExerciseModal = false">Annuler</AlertDialogCancel>
          <AlertDialogAction @click="confirmDeleteExercise" variant="destructive">Supprimer</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </div>
</template>

<script setup>
import { useWorkoutSessions } from '~/composables/useWorkoutSession';
import { useWorkoutExercise } from '~/composables/useWorkoutExercise';
import { Trash2, GripVertical, Edit, FileText, Dumbbell, Plus, ArrowLeft, Save, Loader2, AlertTriangle } from 'lucide-vue-next';
import AddExerciseToSession from '@/components/exercises/AddExerciseToSession.vue';
import draggable from 'vuedraggable';
import { useSupabaseClient } from '#imports';
import { useSupabaseUser } from '#imports';
import { useRoute, useRouter } from 'vue-router';
import { ref, onMounted, onBeforeUnmount } from 'vue';
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
} from "@/components/ui/alert-dialog";

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
const isDragging = ref(false);
const draggedItemId = ref(null);
const isMobile = ref(false);
const showDeleteExerciseModal = ref(false);
const exerciseToDeleteId = ref(null);
const exerciseToDeleteName = ref('');

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

// Détecter si c'est un mobile
const checkMobile = () => {
  isMobile.value = window.innerWidth < 768;
};

const handleSubmit = async () => {
  try {
    saving.value = true;
    const result = await editWorkoutSession(route.params.id, formData.value);
    if (!result.success) {
      throw new Error(result.error || 'Une erreur est survenue lors de l\'édition de la séance');
    }
    // Vibration tactile sur mobile pour confirmation
    if (isMobile.value && window.navigator && window.navigator.vibrate) {
      window.navigator.vibrate([50, 30, 50]);
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
    
    // Vibration tactile sur mobile pour confirmation
    if (isMobile.value && window.navigator && window.navigator.vibrate) {
      window.navigator.vibrate(100);
    }
  } catch (e) {
    console.error('Erreur lors de la suppression de l\'exercice:', e);
  }
};

// État du drag and drop
const dragStart = (event) => {
  isDragging.value = true;
  draggedItemId.value = event.item.__draggable_context.element.id;
  
  // Vibration tactile sur mobile pour feedback
  if (isMobile.value && window.navigator && window.navigator.vibrate) {
    window.navigator.vibrate(50);
  }
};

// Gérer le drag and drop
const handleDragEnd = async (event) => {
  isDragging.value = false;
  draggedItemId.value = null;
  
  try {
    // Vibration tactile sur mobile pour confirmation
    if (isMobile.value && window.navigator && window.navigator.vibrate) {
      window.navigator.vibrate([30, 20, 30]);
    }
    
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
    
    // Vibration tactile sur mobile pour confirmation
    if (isMobile.value && window.navigator && window.navigator.vibrate) {
      window.navigator.vibrate([100, 50, 100]);
    }

    router.push('/seances')
  } catch (e) {
    console.error('Erreur lors de la suppression de la séance:', e);
    error.value = e.message;
  }
};

const openDeleteModal = (id, name) => {
  exerciseToDeleteId.value = id;
  exerciseToDeleteName.value = name;
  showDeleteExerciseModal.value = true;
};

const confirmDeleteExercise = async () => {
  try {
    const result = await removeWorkoutExercise(exerciseToDeleteId.value);
    if (!result.success) {
      throw new Error(result.error || 'Erreur lors de la suppression de l\'exercice');
    }
    // Mettre à jour la liste des exercices localement
    currentExercises.value = currentExercises.value.filter(
      exercise => exercise.id !== exerciseToDeleteId.value
    );
    
    // Vibration tactile sur mobile pour confirmation
    if (isMobile.value && window.navigator && window.navigator.vibrate) {
      window.navigator.vibrate(100);
    }
    showDeleteExerciseModal.value = false;
  } catch (e) {
    console.error('Erreur lors de la suppression de l\'exercice:', e);
    error.value = e.message;
  }
};

onMounted(() => {
  loadSession();
  checkMobile();
  window.addEventListener('resize', checkMobile);
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', checkMobile);
});
</script>

<style scoped>
.drag-handle {
  touch-action: none;
}

.dragging-item {
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  --tw-ring-offset-shadow: 0 0 #0000;
  --tw-ring-shadow: 0 0 #0000;
  --tw-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  box-shadow: var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow);
  outline: 2px solid hsla(var(--primary), 0.2);
  z-index: 10;
}

.ghost-item {
  opacity: 0.4;
  background-color: hsla(var(--primary), 0.05);
  border: 2px dashed hsla(var(--primary), 0.3);
}
</style> 
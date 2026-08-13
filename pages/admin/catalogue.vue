<template>
  <div class="relative">
    <!-- Header -->
    <div class="mb-8 bg-card rounded-xl p-6">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
          <ShieldCheck class="h-6 w-6 text-primary" />
        </div>
        <div class="flex-1">
          <h2 class="text-2xl font-bold text-foreground">Administration — Catalogue de séances</h2>
          <p class="text-sm text-muted-foreground">Créez et supprimez les séances proposées dans le catalogue</p>
        </div>
        <Button class="bg-primary hover:bg-primary/90" @click="openCreateDialog">
          <Plus class="mr-2 h-4 w-4" /> Créer une séance
        </Button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading && templates.length === 0" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <!-- Vide -->
    <div v-else-if="templates.length === 0" class="text-center text-muted-foreground py-12">
      Aucune séance dans le catalogue pour le moment.
    </div>

    <!-- Liste des séances du catalogue -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div
        v-for="template in templates"
        :key="template.id"
        class="bg-card rounded-xl p-6 flex flex-col hover:shadow-md transition-all duration-300"
      >
        <div class="flex items-start gap-3 mb-3">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
            <Dumbbell class="w-5 h-5 text-primary" />
          </div>
          <div class="flex-1">
            <div class="flex items-center gap-2 flex-wrap">
              <h3 class="text-lg font-semibold">{{ template.title }}</h3>
              <span class="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">{{ template.category }}</span>
            </div>
            <p v-if="template.description" class="text-sm text-muted-foreground mt-1">{{ template.description }}</p>
          </div>
        </div>

        <div class="flex-1 space-y-1.5 mb-4">
          <div
            v-for="templateExercise in template.exercises"
            :key="templateExercise.id"
            class="flex items-center justify-between text-sm bg-muted/50 px-3 py-1.5 rounded-lg"
          >
            <span class="text-foreground">{{ templateExercise.exercise.name }}</span>
            <span v-if="templateExercise.target_sets || templateExercise.target_reps" class="text-xs text-muted-foreground flex-shrink-0 ml-2">
              {{ templateExercise.target_sets ? `${templateExercise.target_sets}×` : '' }}{{ templateExercise.target_reps }}
            </span>
          </div>
        </div>

        <div class="flex items-center justify-end gap-2">
          <Button variant="outline" class="w-full sm:w-auto" @click="openEditDialog(template)">
            <Pencil class="mr-2 h-4 w-4" /> Modifier
          </Button>
          <Button
            variant="outline"
            class="w-full sm:w-auto text-destructive border-destructive/30 hover:bg-destructive/10"
            @click="confirmDelete(template)"
          >
            <Trash2 class="mr-2 h-4 w-4" /> Supprimer
          </Button>
        </div>
      </div>
    </div>

    <!-- Dialog de création / modification -->
    <Dialog :open="showCreateDialog" @update:open="handleCreateDialogClose">
      <DialogContent class="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{{ editingTemplate ? 'Modifier la séance modèle' : 'Créer une séance modèle' }}</DialogTitle>
          <DialogDescription>Cette séance sera visible par tous les utilisateurs dans le catalogue.</DialogDescription>
        </DialogHeader>

        <form class="space-y-4" @submit.prevent="handleSubmit">
          <div class="space-y-2">
            <Label for="template-title">Titre</Label>
            <Input id="template-title" v-model="form.title" placeholder="Ex: Full Body Débutant" required />
          </div>

          <div class="space-y-2">
            <Label for="template-category">Catégorie</Label>
            <Input
              id="template-category"
              v-model="form.category"
              list="template-categories"
              placeholder="Ex: Push, Pull, Jambes, Full Body..."
              required
            />
            <datalist id="template-categories">
              <option v-for="category in existingCategories" :key="category" :value="category" />
            </datalist>
          </div>

          <div class="space-y-2">
            <Label for="template-description">Description</Label>
            <Textarea id="template-description" v-model="form.description" placeholder="Décrivez brièvement cette séance" />
          </div>

          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <Label>Exercices</Label>
              <Button type="button" variant="outline" size="sm" @click="showExercisePicker = true">
                <Plus class="mr-1.5 h-4 w-4" /> Ajouter un exercice
              </Button>
            </div>

            <p v-if="formError && form.exercises.length === 0" class="text-sm text-red-500">
              Ajoutez au moins un exercice.
            </p>

            <div v-if="form.exercises.length > 0" class="space-y-2">
              <div
                v-for="(exercise, index) in form.exercises"
                :key="exercise.exercise_id"
                class="flex items-center gap-2 bg-muted/50 rounded-lg p-2"
              >
                <div class="flex flex-col">
                  <button
                    type="button"
                    class="text-muted-foreground hover:text-foreground disabled:opacity-30"
                    :disabled="index === 0"
                    @click="moveExercise(index, -1)"
                  >
                    <ChevronUp class="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    class="text-muted-foreground hover:text-foreground disabled:opacity-30"
                    :disabled="index === form.exercises.length - 1"
                    @click="moveExercise(index, 1)"
                  >
                    <ChevronDown class="h-4 w-4" />
                  </button>
                </div>
                <span class="flex-1 text-sm font-medium truncate">{{ exercise.name }}</span>
                <Input v-model="exercise.target_sets" type="number" min="1" placeholder="Séries" class="w-20 h-8 text-sm" />
                <Input v-model="exercise.target_reps" type="text" placeholder="Reps" class="w-24 h-8 text-sm" />
                <button type="button" class="text-muted-foreground hover:text-destructive flex-shrink-0" @click="removeExercise(index)">
                  <Trash2 class="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>

          <p v-if="formError" class="text-sm text-red-500">{{ formError }}</p>

          <DialogFooter>
            <Button type="button" variant="outline" @click="showCreateDialog = false">Annuler</Button>
            <Button type="submit" :disabled="saving">
              <span v-if="saving" class="animate-spin mr-2">⌛</span>
              {{ editingTemplate ? 'Enregistrer' : 'Créer la séance' }}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>

    <!-- Dialog de sélection d'exercice -->
    <Dialog :open="showExercisePicker" @update:open="showExercisePicker = $event">
      <DialogContent class="max-h-[80vh] flex flex-col">
        <DialogHeader>
          <DialogTitle>Ajouter un exercice</DialogTitle>
        </DialogHeader>
        <div class="flex-1 min-h-0">
          <ExerciseSearch :added-exercises="form.exercises" @add-exercise="handleAddExercise" />
        </div>
      </DialogContent>
    </Dialog>

    <!-- Confirmation de suppression -->
    <AlertDialog :open="showDeleteDialog" @update:open="showDeleteDialog = $event">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Supprimer cette séance du catalogue ?</AlertDialogTitle>
          <AlertDialogDescription>
            « {{ templateToDelete?.title }} » ne sera plus visible dans le catalogue. Cette action est irréversible et n'affecte pas les séances déjà ajoutées par les utilisateurs.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Annuler</AlertDialogCancel>
          <AlertDialogAction class="bg-destructive text-destructive-foreground hover:bg-destructive/90" @click="handleDelete">
            Supprimer
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { toast } from 'vue-sonner';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle
} from '@/components/ui/alert-dialog';
import { ShieldCheck, Dumbbell, Plus, Trash2, Pencil, ChevronUp, ChevronDown } from 'lucide-vue-next';
import ExerciseSearch from '@/components/exercises/ExerciseSearch.vue';
import { useSessionTemplates } from '~/composables/useSessionTemplates';

definePageMeta({ middleware: 'admin' });

const {
  templates,
  loading,
  getSessionTemplates,
  createSessionTemplate,
  updateSessionTemplate,
  deleteSessionTemplate
} = useSessionTemplates();

const existingCategories = computed(() => [...new Set(templates.value.map(t => t.category))]);

const showCreateDialog = ref(false);
const showExercisePicker = ref(false);
const saving = ref(false);
const formError = ref('');
const templateToDelete = ref(null);
const showDeleteDialog = ref(false);
const editingTemplate = ref(null);

const emptyForm = () => ({ title: '', category: '', description: '', exercises: [] });
const form = ref(emptyForm());

const openCreateDialog = () => {
  editingTemplate.value = null;
  form.value = emptyForm();
  formError.value = '';
  showCreateDialog.value = true;
};

const openEditDialog = (template) => {
  editingTemplate.value = template;
  form.value = {
    title: template.title,
    category: template.category,
    description: template.description || '',
    exercises: template.exercises.map(templateExercise => ({
      exercise_id: templateExercise.exercise.id,
      name: templateExercise.exercise.name,
      target_sets: templateExercise.target_sets ?? '',
      target_reps: templateExercise.target_reps ?? ''
    }))
  };
  formError.value = '';
  showCreateDialog.value = true;
};

const handleCreateDialogClose = (open) => {
  showCreateDialog.value = open;
  if (!open) editingTemplate.value = null;
};

const handleAddExercise = (exercise) => {
  form.value.exercises.push({
    exercise_id: exercise.id,
    name: exercise.name,
    target_sets: '',
    target_reps: ''
  });
};

const removeExercise = (index) => {
  form.value.exercises.splice(index, 1);
};

const moveExercise = (index, direction) => {
  const newIndex = index + direction;
  if (newIndex < 0 || newIndex >= form.value.exercises.length) return;
  const exercises = form.value.exercises;
  [exercises[index], exercises[newIndex]] = [exercises[newIndex], exercises[index]];
};

const handleSubmit = async () => {
  formError.value = '';

  if (!form.value.title.trim() || !form.value.category.trim()) {
    formError.value = 'Le titre et la catégorie sont requis.';
    return;
  }
  if (form.value.exercises.length === 0) {
    formError.value = 'Ajoutez au moins un exercice.';
    return;
  }

  const payload = {
    title: form.value.title.trim(),
    category: form.value.category.trim(),
    description: form.value.description.trim(),
    exercises: form.value.exercises.map(exercise => ({
      exercise_id: exercise.exercise_id,
      target_sets: exercise.target_sets ? Number(exercise.target_sets) : null,
      target_reps: exercise.target_reps || null
    }))
  };

  saving.value = true;
  try {
    const result = editingTemplate.value
      ? await updateSessionTemplate(editingTemplate.value.id, payload)
      : await createSessionTemplate(payload);

    if (result.success) {
      toast.success(editingTemplate.value ? `« ${form.value.title} » a été mise à jour` : `« ${form.value.title} » a été ajoutée au catalogue`);
      showCreateDialog.value = false;
      editingTemplate.value = null;
      await getSessionTemplates();
    } else {
      formError.value = result.error || "Erreur lors de l'enregistrement de la séance";
    }
  } finally {
    saving.value = false;
  }
};

const confirmDelete = (template) => {
  templateToDelete.value = template;
  showDeleteDialog.value = true;
};

const handleDelete = async () => {
  if (!templateToDelete.value) return;
  const result = await deleteSessionTemplate(templateToDelete.value.id);
  if (result.success) {
    toast.success('Séance supprimée du catalogue');
  } else {
    toast.error(result.error || 'Erreur lors de la suppression');
  }
  showDeleteDialog.value = false;
  templateToDelete.value = null;
};

onMounted(() => {
  getSessionTemplates();
});
</script>

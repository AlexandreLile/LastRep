<template>
  <div class="space-y-4 overflow-hidden max-h-[75vh] flex flex-col">
    <!-- Titre et instructions pour mobile -->
    <div class="px-3 pb-1 pt-2 text-center md:hidden">
      <h3 class="text-base font-medium text-primary">Trouvez et ajoutez des exercices</h3>
      <p class="text-xs text-muted-foreground mt-1">
        Recherchez et ajoutez des exercices à votre séance d'entraînement
      </p>
    </div>

    <!-- Composant de recherche avec flex-grow pour occuper l'espace disponible -->
    <div class="flex-grow overflow-hidden">
      <ExerciseSearch
        :exercises="exercises"
        :added-exercises="currentExercises"
        @add-exercise="handleAddExercise"
        @create-custom="showCreateDialog = true"
      />
    </div>

    <!-- Dialog de création d'exercice personnalisé -->
    <CreateCustomExercise
      :open="showCreateDialog"
      @update:open="showCreateDialog = $event"
      @created="handleExerciseCreated"
    />
    
    <!-- Bouton de fermeture optimisé pour mobile -->
    <div class="sticky bottom-0 bg-card border-t border-border p-3 shadow-md">
      <Button 
        variant="default" 
        class="w-full h-12 text-base"
        @click="$emit('close')"
      >
        Terminé
      </Button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { Button } from '@/components/ui/button';
import ExerciseSearch from './ExerciseSearch.vue';
import CreateCustomExercise from './CreateCustomExercise.vue';
import { useWorkoutExercise } from '@/composables/useWorkoutExercise';
import { useExercise } from '@/composables/useExercise';

const props = defineProps({
  sessionId: {
    type: String,
    required: true
  }
});

const emit = defineEmits(['close', 'update-exercises']);

const { 
  workoutExercises: currentExercises,
  loading,
  error,
  getWorkoutExercises,
  addExerciseToSession
} = useWorkoutExercise();

const { exercises, getAllExercises } = useExercise();
const isMobile = ref(false);
const showCreateDialog = ref(false);

// Charger les exercices de la séance et tous les exercices disponibles
onMounted(async () => {
  // Détecter si on est sur mobile
  isMobile.value = window.innerWidth < 768 || ('ontouchstart' in window);
  
  // Charger les données
  try {
    await Promise.all([
      getWorkoutExercises(props.sessionId),
      getAllExercises()
    ]);
  } catch (err) {
    console.error('Erreur lors du chargement des exercices:', err);
  }
  
  // Donner un feedback tactile sur mobile
  if (isMobile.value && window.navigator && window.navigator.vibrate) {
    window.navigator.vibrate(30);
  }
});

// Mettre à jour la liste des exercices quand un exercice est ajouté
watch(currentExercises, (newExercises) => {
  emit('update-exercises', newExercises);
});

// Gérer l'ajout d'un exercice
const handleAddExercise = async (exercise) => {
  try {
    const result = await addExerciseToSession(props.sessionId, exercise.id);
    
    if (result.success) {
      // Feedback tactile sur mobile
      if (isMobile.value && window.navigator && window.navigator.vibrate) {
        window.navigator.vibrate([30, 50, 30]);
      }
      
      // Mettre à jour les exercices
      await getWorkoutExercises(props.sessionId);
      
      // Fermer automatiquement la modal sur mobile après l'ajout 
      if (isMobile.value) {
        setTimeout(() => {
          emit('close');
        }, 300);
      }
    } else {
      throw new Error(result.error);
    }
  } catch (e) {
    console.error('Erreur lors de l\'ajout de l\'exercice:', e);
  }
};

// Gérer la création d'un exercice personnalisé
const handleExerciseCreated = async (newExercise) => {
  try {
    // Recharger la liste des exercices pour inclure le nouvel exercice
    await getAllExercises();
    
    // Optionnellement, ajouter automatiquement l'exercice créé à la séance
    if (newExercise && newExercise.id) {
      await handleAddExercise(newExercise);
    }
  } catch (e) {
    console.error('Erreur lors de la gestion de l\'exercice créé:', e);
  }
};
</script>

<style scoped>
/* Optimisation pour les petits écrans */
@media (max-height: 600px) {
  .max-h-\[75vh\] {
    max-height: 85vh;
  }
}
</style> 
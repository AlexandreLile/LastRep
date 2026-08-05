<template>
  <div class="overflow-hidden h-full flex flex-col px-4 sm:px-0 pt-2 sm:pt-0">
    <div class="flex-1 overflow-hidden">
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
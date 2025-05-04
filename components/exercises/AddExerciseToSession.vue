<template>
  <div class="space-y-6 overflow-hidden">
    <ExerciseSearch
      :exercises="exercises"
      :added-exercises="currentExercises"
      @add-exercise="handleAddExercise"
    />
    
    <!-- Bouton de fermeture en bas pour une meilleure accessibilité mobile -->
    <div class="flex justify-center mt-4 px-2">
      <Button 
        variant="default" 
        class="w-full"
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
  addExerciseToSession,
  removeWorkoutExercise
} = useWorkoutExercise();

const { exercises, getAllExercises } = useExercise();

// Charger les exercices de la séance et tous les exercices disponibles
onMounted(async () => {
  await Promise.all([
    getWorkoutExercises(props.sessionId),
    getAllExercises()
  ]);
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
      // Recharger les exercices de la séance pour avoir les données complètes
      const { data } = await getWorkoutExercises(props.sessionId);
      currentExercises.value = data;
      emit('update-exercises', data);
      // Fermer la modal
      emit('close');
    } else {
      throw new Error(result.error);
    }
  } catch (e) {
    console.error('Erreur lors de l\'ajout de l\'exercice:', e);
  }
};
</script> 
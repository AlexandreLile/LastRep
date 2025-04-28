<template>
  <div class="w-full">
    <CardContent class="p-0">
      <!-- Formulaire de recherche dynamique -->
      <form ref="searchForm" class="space-y-4">
        <FormField name="search">
          <Label for="search">Rechercher un exercice</Label>
          <div class="relative">
            <Input
              id="search"
              v-model="searchQuery"
              type="text"
              placeholder="Rechercher un exercice..."
              @focus="isSearching = true"
              class="w-full"
              autocomplete="off"
            />
          </div>
        </FormField>
      </form>

      <!-- Liste des exercices récupérés -->
      <div
        v-if="isSearching && filteredExercises.length > 0"
        class="mt-4 bg-white dark:bg-gray-800 border rounded-lg shadow-lg max-h-60 overflow-y-auto"
      >
        <div
          v-for="exercise in filteredExercises"
          :key="exercise.id"
          @click="selectExercise(exercise)"
          class="cursor-pointer hover:bg-muted/50 p-3 flex items-center justify-between border-b last:border-b-0"
        >
          <div>
            <div class="font-medium">{{ exercise.name }}</div>
            <div class="text-sm text-muted-foreground">
              Muscle principal : {{ exercise.primary_muscle }}
            </div>
          </div>
          <Button
            variant="outline"
            size="sm"
            :disabled="isExerciseAdded(exercise.id)"
          >
            {{ isExerciseAdded(exercise.id) ? 'Ajouté' : 'Ajouter' }}
          </Button>
        </div>
      </div>

      <!-- Message si aucun exercice trouvé -->
      <div
        v-if="isSearching && searchQuery && filteredExercises.length === 0"
        class="text-center text-muted-foreground py-4"
      >
        Aucun exercice trouvé
      </div>

      <!-- Message d'erreur -->
      <div v-if="error" class="mt-2 text-sm text-red-500">
        {{ error }}
      </div>
    </CardContent>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { onClickOutside } from '@vueuse/core';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { FormField } from '@/components/ui/form';
import { Button } from '@/components/ui/button';
import { useExercise } from '@/composables/useExercise';

const props = defineProps({
  addedExercises: {
    type: Array,
    required: true,
    default: () => []
  }
});

const emit = defineEmits(['add-exercise']);

const searchForm = ref(null);
const searchQuery = ref('');
const isSearching = ref(false);
const { exercises, loading, error, getAllExercises } = useExercise();

// Liste des exercices filtrés
const filteredExercises = computed(() => {
  if (!searchQuery.value) return [];
  
  const query = searchQuery.value.toLowerCase();
  return exercises.value.filter(exercise => 
    exercise.name.toLowerCase().includes(query) ||
    exercise.primary_muscle.toLowerCase().includes(query)
  );
});

// Charger tous les exercices au montage
onMounted(async () => {
  await getAllExercises();
});

// Fermer la recherche lors du clic en dehors
onClickOutside(searchForm, () => {
  isSearching.value = false;
});

// Vérifier si un exercice est déjà ajouté
const isExerciseAdded = (exerciseId) => {
  return props.addedExercises.some(ex => ex.exercise_id === exerciseId);
};

// Sélectionner un exercice
const selectExercise = (exercise) => {
  if (!isExerciseAdded(exercise.id)) {
    emit('add-exercise', exercise);
    searchQuery.value = '';
    isSearching.value = false;
  }
};
</script> 
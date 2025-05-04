<template>
  <div class="w-full">
    <CardContent class="p-0">
      <!-- Formulaire de recherche dynamique -->
      <form ref="searchForm" class="space-y-4">
        <FormField name="search">
          <Label for="search">Rechercher un exercice</Label>
          <div class="relative">
            <div class="flex items-center relative">
              <Search class="absolute left-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="search"
                v-model="searchQuery"
                type="text"
                placeholder="Rechercher un exercice..."
                @input="handleSearchInput"
                @keyup="handleSearchInput"
                @focus="isSearching = true"
                class="w-full pl-10"
                autocomplete="off"
              />
              <button 
                v-if="searchQuery" 
                type="button" 
                @click="clearSearch"
                class="absolute right-3 text-muted-foreground hover:text-foreground"
              >
                <X class="h-4 w-4" />
              </button>
            </div>
          </div>
        </FormField>
      </form>

      <!-- Liste des exercices récupérés -->
      <div
        v-if="isSearching && filteredExercises.length > 0"
        class="mt-4 bg-white dark:bg-gray-800 border rounded-lg shadow-lg overflow-y-auto"
        :class="{ 'max-h-60': !isMobile, 'max-h-[40vh]': isMobile }"
      >
        <div
          v-for="exercise in filteredExercises"
          :key="exercise.id"
          @click.stop="selectExercise(exercise)"
          @touchend.stop="selectExercise(exercise)"
          class="cursor-pointer hover:bg-muted/50 active:bg-muted p-3 flex items-center justify-between border-b last:border-b-0"
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
            @click.stop="selectExercise(exercise)"
            @touchend.stop="selectExercise(exercise)"
          >
            {{ isExerciseAdded(exercise.id) ? 'Ajouté' : 'Ajouter' }}
          </Button>
        </div>
      </div>

      <!-- Message si aucun exercice trouvé -->
      <div
        v-if="isSearching && searchQuery && filteredExercises.length === 0"
        class="mt-4 bg-white dark:bg-gray-800 border rounded-lg shadow-lg p-6 text-center"
      >
        <div class="flex flex-col items-center">
          <SearchX class="h-12 w-12 text-muted-foreground mb-2" />
          <p class="text-muted-foreground">Aucun exercice trouvé</p>
        </div>
      </div>

      <!-- Message d'erreur -->
      <div v-if="error" class="mt-2 text-sm text-red-500">
        {{ error }}
      </div>
    </CardContent>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, onBeforeUnmount } from 'vue';
import { onClickOutside } from '@vueuse/core';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { FormField } from '@/components/ui/form';
import { Button } from '@/components/ui/button';
import { Search, X, SearchX } from 'lucide-vue-next';
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
const isMobile = ref(false);

// Détecter si c'est un mobile
const checkMobile = () => {
  isMobile.value = window.innerWidth < 768;
};

// Gérer l'input de recherche
const handleSearchInput = () => {
  isSearching.value = true;
  // Force la mise à jour du filteredExercises
  forceUpdate();
};

// Force la mise à jour du computed en cas de problème sur mobile
const forceUpdate = () => {
  if (isMobile.value) {
    // Techniquement rien à faire ici car le v-model met déjà à jour searchQuery
    // mais cela force une réévaluation du contexte réactif
    searchQuery.value = searchQuery.value;
  }
};

// Liste des exercices filtrés
const filteredExercises = computed(() => {
  if (!searchQuery.value) return [];
  
  const query = searchQuery.value.toLowerCase().trim();
  if (query.length === 0) return [];
  
  return exercises.value.filter(exercise => 
    exercise.name.toLowerCase().includes(query) ||
    exercise.primary_muscle.toLowerCase().includes(query)
  );
});

// Effacer la recherche
const clearSearch = () => {
  searchQuery.value = '';
  isSearching.value = false;
};

// Charger tous les exercices au montage
onMounted(async () => {
  await getAllExercises();
  checkMobile();
  window.addEventListener('resize', checkMobile);
  
  // Ajouter des gestionnaires d'événements pour les clics sur la page
  document.addEventListener('click', handleDocumentClick);
  document.addEventListener('touchend', handleDocumentClick);
});

// Nettoyer les événements
onBeforeUnmount(() => {
  window.removeEventListener('resize', checkMobile);
  document.removeEventListener('click', handleDocumentClick);
  document.removeEventListener('touchend', handleDocumentClick);
});

// Gérer les clics sur le document
const handleDocumentClick = (event) => {
  const searchElement = searchForm.value;
  if (searchElement && !searchElement.contains(event.target)) {
    isSearching.value = false;
  }
};

// Observer les changements de searchQuery pour mobile
watch(searchQuery, () => {
  if (isMobile.value && searchQuery.value) {
    isSearching.value = true;
  }
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
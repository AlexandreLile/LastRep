<template>
  <div class="w-full overflow-hidden">
    <CardContent class="p-0">
      <!-- Formulaire de recherche dynamique -->
      <form ref="searchForm" class="space-y-4 px-2">
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

      <!-- Liste des exercices récupérés - toujours visible sur mobile si on a des données -->
      <div
        v-if="(isSearching || isMobile) && filteredExercises.length > 0"
        class="mt-4 bg-white dark:bg-gray-800 border rounded-xl shadow-lg overflow-y-auto overflow-x-hidden"
        :class="{ 'max-h-60': !isMobile, 'max-h-[50vh]': isMobile }"
      >
        <div
          v-for="exercise in filteredExercises"
          :key="exercise.id"
          @click.stop="selectExercise(exercise)"
          @touchend.stop="selectExercise(exercise)"
          class="group relative cursor-pointer hover:bg-primary/5 active:bg-primary/10 transition-all duration-200 p-3 flex flex-col sm:flex-row sm:items-center gap-3 border-b last:border-b-0"
        >
          <!-- Indicateur visuel de sélection à gauche -->
          <div class="absolute left-0 top-0 bottom-0 w-1 bg-transparent group-hover:bg-primary/50 transition-all duration-300"></div>
          
          <div class="flex items-start gap-2 w-full">
            <!-- Icône du muscle -->
            <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0 mt-1">
              <Dumbbell class="h-5 w-5 text-primary" />
            </div>
            
            <div class="flex-1 min-w-0">
              <div class="font-medium text-gray-900 group-hover:text-primary transition-colors duration-200 truncate pr-1">{{ exercise.name }}</div>
              <div class="text-sm text-muted-foreground mt-1">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-700 group-hover:bg-primary/10 group-hover:text-primary transition-all duration-200">
                  {{ exercise.primary_muscle }}
                </span>
              </div>
            </div>
          </div>
          
          <Button
            :variant="isExerciseAdded(exercise.id) ? 'outline' : 'default'"
            size="sm"
            :disabled="isExerciseAdded(exercise.id)"
            @click.stop="selectExercise(exercise)"
            @touchend.stop="selectExercise(exercise)"
            class="transition-all duration-200 relative mt-2 sm:mt-0 w-full sm:w-auto"
          >
            <span v-if="isExerciseAdded(exercise.id)" class="flex items-center justify-center gap-1">
              <Check class="h-4 w-4" />
              <span class="whitespace-nowrap">Ajouté</span>
            </span>
            <span v-else class="flex items-center justify-center gap-1">
              <Plus class="h-4 w-4" />
              <span class="whitespace-nowrap">Ajouter</span>
            </span>
          </Button>
        </div>
      </div>
      
      <!-- Message si aucun exercice trouvé -->
      <div
        v-if="isSearching && searchQuery && filteredExercises.length === 0"
        class="mt-4 bg-white dark:bg-gray-800 border rounded-xl shadow-lg p-6 text-center"
      >
        <div class="flex flex-col items-center">
          <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-3">
            <SearchX class="h-8 w-8 text-muted-foreground" />
          </div>
          <p class="text-muted-foreground">Aucun exercice trouvé</p>
        </div>
      </div>

      <!-- Message d'erreur -->
      <div v-if="error" class="mt-2 -mx-1 text-sm text-red-500">
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
import { Search, X, SearchX, Dumbbell, Plus, Check } from 'lucide-vue-next';
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
const debounceTimer = ref(null);

// Détecter si c'est un mobile
const checkMobile = () => {
  isMobile.value = window.innerWidth < 768;
};

// Gérer l'input de recherche avec debounce
const handleSearchInput = () => {
  isSearching.value = true;
  
  // Annuler le timer précédent
  if (debounceTimer.value) {
    clearTimeout(debounceTimer.value);
  }
  
  // Créer un nouveau timer pour le debounce
  debounceTimer.value = setTimeout(() => {
    // Force la mise à jour du filteredExercises
    forceUpdate();
  }, 100); // délai très court pour la réactivité, mais suffisant pour regrouper les événements
};

// Force la mise à jour du computed
const forceUpdate = () => {
  // Technique pour forcer une réévaluation du contexte réactif
  searchQuery.value = searchQuery.value.trim();
};

// Liste des exercices filtrés
const filteredExercises = computed(() => {
  if (!searchQuery.value) {
    // Sur mobile, montre tous les exercices si le champ est vide
    return isMobile.value ? exercises.value : [];
  }
  
  const query = searchQuery.value.toLowerCase().trim();
  if (query.length === 0 && !isMobile.value) return [];
  
  return exercises.value.filter(exercise => 
    exercise.name.toLowerCase().includes(query) ||
    exercise.primary_muscle.toLowerCase().includes(query)
  );
});

// Effacer la recherche
const clearSearch = () => {
  searchQuery.value = '';
  // Sur mobile, garde l'état de recherche actif
  isSearching.value = isMobile.value;
};

// Charger tous les exercices au montage
onMounted(async () => {
  await getAllExercises();
  checkMobile();
  window.addEventListener('resize', checkMobile);
  
  // Ajouter des gestionnaires d'événements pour les clics sur la page
  document.addEventListener('click', handleDocumentClick);
  document.addEventListener('touchend', handleDocumentClick);
  
  // Sur mobile, on active directement la recherche
  if (isMobile.value) {
    isSearching.value = true;
  }
});

// Nettoyer les événements
onBeforeUnmount(() => {
  window.removeEventListener('resize', checkMobile);
  document.removeEventListener('click', handleDocumentClick);
  document.removeEventListener('touchend', handleDocumentClick);
  
  if (debounceTimer.value) {
    clearTimeout(debounceTimer.value);
  }
});

// Gérer les clics sur le document
const handleDocumentClick = (event) => {
  const searchElement = searchForm.value;
  if (searchElement && !searchElement.contains(event.target)) {
    // Sur mobile, on garde toujours l'état de recherche actif
    isSearching.value = isMobile.value;
  }
};

// Observer les changements de searchQuery
watch(searchQuery, () => {
  // Sur mobile, on garde toujours l'état de recherche actif
  if (isMobile.value) {
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
    // Sur mobile, on garde l'interface de recherche ouverte
    isSearching.value = isMobile.value;
  }
};
</script>

<style scoped>
/* Styles pour corriger les problèmes sur mobile */
@media (max-width: 768px) {
  input[type="text"] {
    font-size: 16px; /* Empêche iOS de zoomer sur le focus */
  }
}

/* Ajustements spécifiques pour les très petits écrans */
@media (max-width: 450px) {
  .group {
    padding-left: 10px;
    padding-right: 10px;
  }
  
  /* Assurer que le texte ne déborde pas */
  .truncate {
    max-width: 170px;
  }
  
  /* Ajuster la taille de l'icône pour gagner de l'espace */
  .w-10.h-10 {
    width: 36px;
    height: 36px;
  }
}

/* Animation pour les cartes d'exercices */
.group {
  position: relative;
  z-index: 1;
}

.group:hover {
  z-index: 2;
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}
</style> 
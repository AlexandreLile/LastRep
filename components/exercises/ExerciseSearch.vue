<template>
  <div class="w-full overflow-hidden">
    <CardContent class="p-0">
      <!-- Formulaire de recherche mobile-first -->
      <form ref="searchForm" class="space-y-4 px-2 pb-2">
        <FormField name="search">
          <Label for="search">Rechercher un exercice</Label>
          <div class="relative">
            <div class="flex items-center relative">
              <Search class="absolute left-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="search"
                ref="searchInput"
                v-model="searchQuery"
                type="text"
                inputmode="search"
                autocapitalize="none"
                placeholder="Rechercher un exercice..."
                @keyup="forceUpdate"
                class="w-full pl-10 pr-8 search-input"
                autocomplete="off"
              />
              <button 
                v-if="searchQuery" 
                type="button" 
                @click="clearSearch"
                class="absolute right-3 text-muted-foreground hover:text-foreground"
                aria-label="Effacer la recherche"
              >
                <X class="h-4 w-4" />
              </button>
            </div>
          </div>
        </FormField>
      </form>

      <!-- Liste des exercices - toujours affichée sur mobile -->
      <div
        v-if="exercises.length > 0"
        ref="exerciseList"
        class="mt-2 bg-white border rounded-xl shadow-sm overflow-y-auto overflow-x-hidden transition-all duration-300 exercise-list"
        :class="{ 'max-h-60': !isMobile, 'max-h-[60vh]': isMobile }"
      >
        <div 
          v-if="filteredExercises.length === 0 && searchQuery" 
          class="p-4 text-center text-muted-foreground"
        >
          <div class="flex flex-col items-center">
            <SearchX class="h-6 w-6 mb-2 text-muted-foreground" />
            <p>Aucun exercice trouvé</p>
          </div>
        </div>
        
        <div
          v-for="exercise in filteredExercises.length > 0 ? filteredExercises : exercises"
          :key="exercise.id"
          class="group relative hover:bg-primary/5 active:bg-primary/10 transition-all duration-200 p-3 flex flex-col md:flex-row md:items-center gap-3 border-b last:border-b-0 transform-gpu"
        >
          <!-- Indicateur visuel à gauche -->
          <div class="absolute left-0 top-0 bottom-0 w-1 bg-transparent group-hover:bg-primary/50 transition-all duration-300"></div>
          
          <div class="flex items-start gap-2 w-full">
            <!-- Icône du muscle -->
            <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0 mt-1">
              <Dumbbell class="h-5 w-5 text-primary" />
            </div>
            
            <div class="flex-1 min-w-0">
              <div class="font-medium text-gray-900 truncate pr-1">{{ exercise.name }}</div>
              <div class="text-sm text-muted-foreground mt-1">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-700">
                  {{ exercise.primary_muscle }}
                </span>
              </div>
            </div>
          </div>
          
          <Button
            :variant="isExerciseAdded(exercise.id) ? 'outline' : 'default'"
            size="sm"
            :disabled="isExerciseAdded(exercise.id)"
            @click="selectExercise(exercise)"
            class="transition-all duration-200 mt-2 md:mt-0 w-full md:w-auto"
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

      <!-- Message d'erreur -->
      <div v-if="error" class="mt-2 -mx-1 text-sm text-red-500">
        {{ error }}
      </div>
    </CardContent>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, onBeforeUnmount, nextTick } from 'vue';
import { Card, CardContent } from '@/components/ui/card';
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
const searchInput = ref(null);
const exerciseList = ref(null);
const searchQuery = ref('');
const { exercises, loading, error, getAllExercises } = useExercise();
const isMobile = ref(false);
const searchTimer = ref(null);

// Fonction pour normaliser le texte (enlever les accents)
const normalizeText = (text) => {
  if (!text) return '';
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
};

// Détecter si c'est un mobile - approche mobile-first
const checkMobile = () => {
  isMobile.value = window.innerWidth < 768 || ('ontouchstart' in window);
};

// Force la mise à jour du computed manuellement
const forceUpdate = () => {
  // Créer une copie de la recherche pour forcer la réactivité
  const currentValue = searchQuery.value;
  // Une petite manipulation pour forcer Vue à recalculer le computed
  searchQuery.value = '';
  nextTick(() => {
    searchQuery.value = currentValue;
  });
};

// Ajouter un watcher pour forcer la réactivité
watch(searchQuery, (newVal) => {
  // Cette fonction vide est juste là pour garantir que Vue 
  // réagit immédiatement à tout changement de searchQuery
  // même pour la première lettre
  console.log('Recherche en cours:', newVal);
}, { immediate: true });

// Filtrer les exercices - Démarrer la recherche dès la première lettre
const filteredExercises = computed(() => {
  if (!searchQuery.value) {
    return exercises.value;
  }
  
  const query = normalizeText(searchQuery.value);
  
  return exercises.value.filter(exercise => {
    const name = normalizeText(exercise.name);
    const muscle = normalizeText(exercise.primary_muscle);
    
    // Rechercher dans le nom ou le muscle dès la première lettre
    return name.includes(query) || muscle.includes(query);
  });
});

// Effacer la recherche
const clearSearch = () => {
  searchQuery.value = '';
  // Donner un feedback tactile sur mobile
  if (isMobile.value && window.navigator && window.navigator.vibrate) {
    window.navigator.vibrate(50);
  }
  // Redonner le focus à l'input
  nextTick(() => {
    focusSearchInput();
  });
};

// Mettre le focus sur l'input de recherche
const focusSearchInput = () => {
  if (searchInput.value && searchInput.value.$el) {
    const input = searchInput.value.$el.querySelector('input');
    if (input) input.focus();
  }
};

// Charger tous les exercices au montage
onMounted(async () => {
  await getAllExercises();
  checkMobile();
  window.addEventListener('resize', checkMobile);
  
  // Sur mobile, mettre le focus sur l'input de recherche
  if (isMobile.value) {
    // Délai court pour laisser le DOM se mettre à jour
    setTimeout(focusSearchInput, 100);
  }
});

// Nettoyer les événements
onBeforeUnmount(() => {
  window.removeEventListener('resize', checkMobile);
  if (searchTimer.value) {
    clearTimeout(searchTimer.value);
  }
});

// Vérifier si un exercice est déjà ajouté
const isExerciseAdded = (exerciseId) => {
  return props.addedExercises.some(ex => ex.exercise_id === exerciseId);
};

// Sélectionner un exercice
const selectExercise = (exercise) => {
  if (!isExerciseAdded(exercise.id)) {
    // Feedback tactile sur mobile
    if (isMobile.value && window.navigator && window.navigator.vibrate) {
      window.navigator.vibrate(50);
    }
    
    emit('add-exercise', exercise);
  }
};
</script>

<style scoped>
/* Styles pour mobile-first */
@media (max-width: 768px) {
  /* Empêcher iOS de zoomer sur le focus */
  input[type="text"] {
    font-size: 16px;
  }
  
  /* Optimisations pour le scroll sur mobile */
  .exercise-list {
    -webkit-overflow-scrolling: touch;
    scroll-snap-type: y proximity;
    overscroll-behavior: contain;
  }
  
  /* Rendre les boutons et zones cliquables plus grands pour mobile */
  button {
    min-height: 44px;
  }
}

/* Amélioration de l'espacement */
.group {
  scroll-snap-align: start;
  padding: 12px 16px;
}

/* Réduire la hauteur de la liste sur les petits écrans */
@media (max-height: 600px) {
  .exercise-list.max-h-\[60vh\] {
    max-height: 50vh;
  }
}
</style> 
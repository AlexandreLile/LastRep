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
                ref="searchInput"
                v-model="searchQuery"
                type="text"
                placeholder="Rechercher un exercice..."
                @input="handleSearchInput"
                @keyup="handleSearchInput"
                @focus="handleSearchFocus"
                class="w-full pl-10 search-input"
                autocomplete="off"
              />
              <button 
                v-if="searchQuery" 
                type="button" 
                @click="clearSearch"
                @touchend.prevent="handleClearTouchEnd"
                class="absolute right-3 text-muted-foreground hover:text-foreground"
                aria-label="Effacer la recherche"
              >
                <X class="h-4 w-4" />
              </button>
            </div>
          </div>
        </FormField>
      </form>

      <!-- Liste des exercices avec pull-to-refresh -->
      <div
        v-if="(isSearching || isMobile) && filteredExercises.length > 0"
        ref="exerciseList"
        class="mt-4 bg-white dark:bg-gray-800 border rounded-xl shadow-lg overflow-y-auto overflow-x-hidden transition-all duration-300 exercise-list"
        :class="{ 'max-h-60': !isMobile, 'max-h-[50vh]': isMobile }"
        @touchstart="handleTouchStart"
        @touchmove="handleTouchMove"
        @touchend="handleTouchEnd"
      >
        <div v-if="isRefreshing" class="text-center py-2 text-primary text-sm font-medium flex items-center justify-center gap-2">
          <span class="inline-block animate-spin h-4 w-4 border-2 border-primary border-t-transparent rounded-full"></span>
          Mise à jour...
        </div>
        
        <div
          v-for="exercise in filteredExercises"
          :key="exercise.id"
          class="group relative hover:bg-primary/5 active:bg-primary/10 transition-all duration-200 p-3 flex flex-col sm:flex-row sm:items-center gap-3 border-b last:border-b-0 transform-gpu"
          :class="{'scale-99 opacity-95': touchedExerciseId === exercise.id}"
        >
          <!-- Indicateur visuel de sélection à gauche -->
          <div class="absolute left-0 top-0 bottom-0 w-1 bg-transparent group-hover:bg-primary/50 transition-all duration-300"></div>
          
          <div class="flex items-start gap-2 w-full">
            <!-- Icône du muscle -->
            <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0 mt-1 group-hover:scale-105 transition-transform duration-300">
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
            @touchend.stop.prevent="handleExerciseTouchEnd(exercise)"
            class="transition-all duration-200 relative mt-2 sm:mt-0 w-full sm:w-auto transform-gpu hover:scale-105 active:scale-95"
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
import { ref, computed, onMounted, watch, onBeforeUnmount, nextTick } from 'vue';
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
const searchInput = ref(null);
const exerciseList = ref(null);
const searchQuery = ref('');
const isSearching = ref(false);
const { exercises, loading, error, getAllExercises } = useExercise();
const isMobile = ref(false);
const debounceTimer = ref(null);
const touchStartY = ref(0);
const pullDistance = ref(0);
const isRefreshing = ref(false);
const touchedExerciseId = ref(null);
const touchTimeout = ref(null);
const hasMoved = ref(false);

// Fonction pour normaliser le texte (enlever les accents)
const normalizeText = (text) => {
  return text
    .normalize('NFD')                  // Décomposer les caractères accentués
    .replace(/[\u0300-\u036f]/g, '')   // Supprimer les marques diacritiques
    .toLowerCase()                      // Convertir en minuscules
    .trim();                            // Supprimer les espaces inutiles
};

// Détecter si c'est un mobile
const checkMobile = () => {
  isMobile.value = window.innerWidth < 768;
};

// Gérer l'input de recherche avec debounce
const handleSearchInput = () => {
  isSearching.value = true;
  
  // Activer la recherche immédiatement sur mobile
  if (isMobile.value) {
    forceUpdate();
  }
  
  // Annuler le timer précédent
  if (debounceTimer.value) {
    clearTimeout(debounceTimer.value);
  }
  
  // Créer un nouveau timer pour le debounce avec un délai plus court sur mobile
  debounceTimer.value = setTimeout(() => {
    forceUpdate();
  }, isMobile.value ? 50 : 100); // Délai plus court sur mobile
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
  
  const query = normalizeText(searchQuery.value);
  if (query.length === 0 && !isMobile.value) return [];
  
  return exercises.value.filter(exercise => {
    const name = normalizeText(exercise.name);
    const muscle = normalizeText(exercise.primary_muscle);
    
    // Recherche par parties du mot (pour être plus tolérant)
    return name.includes(query) || muscle.includes(query);
  });
});

// Effacer la recherche
const clearSearch = () => {
  searchQuery.value = '';
  // Sur mobile, garde l'état de recherche actif
  isSearching.value = isMobile.value;
  // Vibration pour feedback tactile sur mobile
  if (isMobile.value && window.navigator && window.navigator.vibrate) {
    window.navigator.vibrate(50);
  }
};

// Gérer le focus sur la recherche
const handleSearchFocus = () => {
  isSearching.value = true;
  // Auto-sélection du texte pour faciliter une nouvelle recherche
  if (searchInput.value && searchInput.value.$el) {
    const input = searchInput.value.$el.querySelector('input');
    if (input) input.select();
  }
};

// Mettre le focus sur l'input de recherche
const focusSearchInput = () => {
  // Attendre que le DOM soit mis à jour
  nextTick(() => {
    try {
      if (searchInput.value && typeof searchInput.value.$el !== 'undefined') {
        // Pour un composant Input personnalisé qui peut encapsuler un input natif
        const inputElement = searchInput.value.$el.querySelector('input');
        if (inputElement && typeof inputElement.focus === 'function') {
          inputElement.focus();
        }
      } else if (searchInput.value && typeof searchInput.value.focus === 'function') {
        // Pour un élément input natif
        searchInput.value.focus();
      } else {
        // Fallback: chercher manuellement l'input
        const inputElement = document.getElementById('search');
        if (inputElement && typeof inputElement.focus === 'function') {
          inputElement.focus();
        }
      }
    } catch (error) {
      console.log('Impossible de mettre le focus sur l\'input:', error);
    }
  });
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
    // Mettre le focus sur l'input de recherche avec un petit délai
    setTimeout(focusSearchInput, 300);
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
  
  if (touchTimeout.value) {
    clearTimeout(touchTimeout.value);
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

// Observer les changements de searchQuery pour déclencher immédiatement la recherche sur mobile
watch(searchQuery, (newValue) => {
  // Sur mobile, on garde toujours l'état de recherche actif et on force la mise à jour
  if (isMobile.value) {
    isSearching.value = true;
    // Mise à jour immédiate si le texte a changé
    if (newValue !== null && newValue !== undefined) {
      forceUpdate();
    }
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
      window.navigator.vibrate(100);
    }
    
    emit('add-exercise', exercise);
    searchQuery.value = '';
    // Sur mobile, on garde l'interface de recherche ouverte
    isSearching.value = isMobile.value;
  }
};

// Gestion des événements tactiles pour le pull-to-refresh
const handleTouchStart = (e) => {
  touchStartY.value = e.touches[0].clientY;
  pullDistance.value = 0;
  hasMoved.value = false;
};

const handleTouchMove = (e) => {
  const touchY = e.touches[0].clientY;
  const scrollTop = exerciseList.value?.scrollTop || 0;
  
  hasMoved.value = true;
  
  // Permettre le pull-to-refresh uniquement quand on est au début de la liste
  if (scrollTop <= 0 && touchY > touchStartY.value) {
    pullDistance.value = (touchY - touchStartY.value) * 0.5; // Facteur de résistance
    
    // Limiter la distance de tirage
    if (pullDistance.value > 80) pullDistance.value = 80;
    
    // Empêcher le scroll natif si on tire vers le bas
    if (pullDistance.value > 10) {
      e.preventDefault();
    }
  }
};

const handleTouchEnd = async () => {
  if (pullDistance.value > 60 && !isRefreshing.value) {
    // Assez tiré pour déclencher le rafraîchissement
    isRefreshing.value = true;
    
    // Feedback tactile
    if (window.navigator && window.navigator.vibrate) {
      window.navigator.vibrate(50);
    }
    
    // Rafraîchir les données
    try {
      await getAllExercises();
    } catch (error) {
      console.error('Erreur lors du rafraîchissement des exercices:', error);
    } finally {
      // Réinitialiser après un court délai pour montrer l'animation
      setTimeout(() => {
        isRefreshing.value = false;
        pullDistance.value = 0;
      }, 800);
    }
  } else {
    pullDistance.value = 0;
  }
};

// Gestion des événements tactiles pour éviter les ajouts accidentels
const handleExerciseTouchEnd = (exercise) => {
  // Ne sélectionner l'exercice que si l'utilisateur n'a pas scrollé
  if (!hasMoved.value) {
    touchedExerciseId.value = exercise.id;
    
    // Animation visuelle de feedback tactile
    setTimeout(() => {
      touchedExerciseId.value = null;
      selectExercise(exercise);
    }, 150);
  }
};

// Gérer le touchend sur le bouton clear avec feedback tactile
const handleClearTouchEnd = (e) => {
  e.preventDefault();
  
  // Feedback tactile sur mobile
  if (isMobile.value && window.navigator && window.navigator.vibrate) {
    window.navigator.vibrate(50);
  }
  
  clearSearch();
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

/* Correction du focus gris pour qu'il soit proportionnel */
.search-input:focus {
  box-shadow: 0 0 0 2px white, 0 0 0 4px hsl(var(--primary));
  outline: none;
  border-radius: var(--radius);
}

.search-input:focus-visible {
  outline: none;
  box-shadow: 0 0 0 2px white, 0 0 0 4px hsl(var(--primary));
  border-radius: var(--radius);
}

/* Animation pour les cartes d'exercices */
.group {
  position: relative;
  z-index: 1;
  will-change: transform, opacity;
}

.group:hover {
  z-index: 2;
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

/* Animation subtile au scroll */
.exercise-list {
  scroll-behavior: smooth;
  overscroll-behavior: contain;
}

/* Effet d'échelle subtile pour le feedback tactile */
.scale-99 {
  transform: scale(0.99);
}
</style> 
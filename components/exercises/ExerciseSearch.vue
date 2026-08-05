<template>
  <div class="w-full h-full flex flex-col gap-3 overflow-hidden">

    <!-- Chips musculaires (priorité 1) -->
    <div class="relative">
      <div
        ref="chipsContainer"
        class="flex gap-2 overflow-x-auto pb-1 scrollbar-none px-0.5"
        style="-webkit-overflow-scrolling: touch; scrollbar-width: none;"
      >
        <button
          v-for="muscle in muscleChips"
          :key="muscle"
          type="button"
          @click="toggleMuscle(muscle)"
          class="flex-shrink-0 px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-150 border"
          :class="selectedMuscle === muscle
            ? 'bg-primary text-primary-foreground border-primary shadow-sm'
            : 'bg-muted/60 text-muted-foreground border-transparent hover:bg-muted active:bg-muted'"
        >
          {{ muscle === 'Tout' ? 'Tout' : muscle }}
        </button>
      </div>
    </div>

    <!-- Barre de recherche (priorité 2) -->
    <div class="relative">
      <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
      <input
        ref="searchInput"
        v-model="searchQuery"
        type="text"
        inputmode="search"
        autocapitalize="none"
        autocorrect="off"
        spellcheck="false"
        autocomplete="off"
        placeholder="Rechercher..."
        class="w-full h-9 rounded-md border border-input bg-transparent pl-9 pr-8 text-sm shadow-sm placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring"
        style="font-size: 16px;"
      />
      <button
        v-if="searchQuery"
        type="button"
        @click="searchQuery = ''"
        class="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground p-0.5"
      >
        <X class="h-3.5 w-3.5" />
      </button>
    </div>

    <!-- Liste des exercices -->
    <div
      class="flex-1 overflow-y-auto overflow-x-hidden rounded-xl border bg-card"
      style="-webkit-overflow-scrolling: touch; overscroll-behavior: contain;"
    >
      <!-- Vide avec filtre actif -->
      <div
        v-if="filteredExercises.length === 0"
        class="flex flex-col items-center justify-center h-full py-12 text-center text-muted-foreground gap-2"
      >
        <SearchX class="h-8 w-8 opacity-40" />
        <p class="text-sm">Aucun exercice trouvé</p>
        <button
          v-if="selectedMuscle !== 'Tout' || searchQuery"
          type="button"
          class="text-xs text-primary underline-offset-2 hover:underline mt-1"
          @click="resetFilters"
        >
          Réinitialiser les filtres
        </button>
      </div>

      <div
        v-for="exercise in filteredExercises"
        :key="exercise.id"
        class="flex items-center gap-3 px-3 py-3 border-b last:border-b-0 active:bg-muted/60 transition-colors"
      >
        <!-- Icône muscle -->
        <div class="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
          <Dumbbell class="h-4 w-4 text-primary" />
        </div>

        <!-- Nom + muscles -->
        <div class="flex-1 min-w-0">
          <p class="font-medium text-sm text-foreground truncate">{{ exercise.name }}</p>
          <div class="flex gap-1 mt-0.5 flex-wrap">
            <span
              v-for="(muscle, i) in (exercise.muscles_names?.length ? exercise.muscles_names : [exercise.primary_muscle]).filter(Boolean).slice(0, 2)"
              :key="i"
              class="text-[11px] px-1.5 py-0.5 rounded-full"
              :class="i === 0 ? 'bg-primary/10 text-primary' : 'bg-muted text-muted-foreground'"
            >
              {{ muscle }}
            </span>
          </div>
        </div>

        <!-- Bouton ajouter -->
        <button
          type="button"
          :disabled="isExerciseAdded(exercise.id)"
          @click="selectExercise(exercise)"
          class="flex-shrink-0 h-8 w-8 rounded-full flex items-center justify-center transition-all duration-150"
          :class="isExerciseAdded(exercise.id)
            ? 'bg-muted text-muted-foreground cursor-default'
            : 'bg-primary text-primary-foreground active:scale-95 hover:bg-primary/90'"
        >
          <Check v-if="isExerciseAdded(exercise.id)" class="h-4 w-4" />
          <Plus v-else class="h-4 w-4" />
        </button>
      </div>
    </div>

    <!-- Créer un exercice custom -->
    <button
      type="button"
      @click="$emit('create-custom')"
      class="flex items-center justify-center gap-2 w-full h-9 rounded-md border border-dashed border-border text-sm text-muted-foreground hover:text-foreground hover:border-foreground/30 transition-colors flex-shrink-0"
    >
      <Plus class="h-4 w-4" />
      Créer un exercice personnalisé
    </button>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { Search, X, SearchX, Dumbbell, Plus, Check } from 'lucide-vue-next'
import { useExercise } from '@/composables/useExercise'

const props = defineProps({
  addedExercises: { type: Array, required: true, default: () => [] },
  exercises: { type: Array, default: null }
})

const emit = defineEmits(['add-exercise', 'create-custom'])

const searchInput = ref(null)
const searchQuery = ref('')
const selectedMuscle = ref('Tout')
const { exercises: localExercises, getAllExercises } = useExercise()

const exercises = computed(() => props.exercises ?? localExercises.value ?? [])

// Chips : "Tout" + muscles uniques extraits des exercices
const muscleChips = computed(() => {
  const muscles = new Set()
  exercises.value.forEach(ex => {
    const list = ex.muscles_names?.length ? ex.muscles_names : [ex.primary_muscle]
    list.filter(Boolean).forEach(m => muscles.add(m))
  })
  return ['Tout', ...Array.from(muscles).sort()]
})

const normalizeText = (t) =>
  (t || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')

const filteredExercises = computed(() => {
  let list = exercises.value

  if (selectedMuscle.value !== 'Tout') {
    list = list.filter(ex => {
      const muscles = ex.muscles_names?.length ? ex.muscles_names : [ex.primary_muscle]
      return muscles.some(m => m === selectedMuscle.value)
    })
  }

  const q = normalizeText(searchQuery.value)
  if (q) {
    list = list.filter(ex => {
      const name = normalizeText(ex.name)
      const muscles = ex.muscles_names?.length ? ex.muscles_names : [ex.primary_muscle]
      return name.includes(q) || muscles.some(m => normalizeText(m).includes(q))
    })
  }

  return list
})

const toggleMuscle = (muscle) => {
  selectedMuscle.value = muscle
}

const resetFilters = () => {
  selectedMuscle.value = 'Tout'
  searchQuery.value = ''
}

const isExerciseAdded = (id) => props.addedExercises.some(ex => ex.exercise_id === id)

const selectExercise = (exercise) => {
  if (isExerciseAdded(exercise.id)) return
  if (window.navigator?.vibrate) window.navigator.vibrate(40)
  emit('add-exercise', exercise)
}

onMounted(async () => {
  if (props.exercises === null) await getAllExercises()
})
</script>

<style scoped>
.scrollbar-none::-webkit-scrollbar { display: none; }
</style>

<template>
  <div class="relative">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8 bg-card rounded-xl p-6">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4 text-red-500" />
      {{ error }}
    </div>

    <div v-else class="space-y-6">
      <!-- En-tête amélioré -->
      <div class="mb-8 bg-card rounded-xl p-6">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
              <Dumbbell class="h-6 w-6 text-primary" />
            </div>
            <div>
              <h2 class="text-2xl font-bold text-foreground">Mes Exercices</h2>
              <p class="text-sm text-muted-foreground">Suivez votre progression sur chaque exercice</p>
            </div>
          </div>
          <Button
            variant="default"
            @click="showCreateDialog = true"
            class="flex items-center gap-2 w-full sm:w-auto"
          >
            <Plus class="h-4 w-4" />
            Créer un exercice
          </Button>
        </div>
      </div>

      <!-- Dialog de création d'exercice personnalisé -->
      <CreateCustomExercise
        :open="showCreateDialog"
        @update:open="showCreateDialog = $event"
        @created="handleExerciseCreated"
      />


      <!-- Layout principal -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Liste des exercices - Colonne principale -->
        <div class="lg:col-span-2">
          <div class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                <ListChecks class="w-5 h-5 text-primary" />
              </div>
              <div>
                <h3 class="text-lg font-semibold">Liste des exercices</h3>
                <p class="text-sm text-muted-foreground">Exercices avec des séries enregistrées</p>
              </div>
            </div>

            <!-- Chips musculaires -->
            <div class="flex gap-2 overflow-x-auto pb-1 -mx-0.5 px-0.5 mb-3" style="-webkit-overflow-scrolling: touch; scrollbar-width: none;">
              <button
                v-for="chip in muscleChips"
                :key="chip"
                type="button"
                @click="selectMuscleChip(chip)"
                class="flex-shrink-0 px-3 py-1.5 rounded-full text-sm font-medium border transition-all duration-150"
                :class="selectedMuscleChip === chip
                  ? 'bg-primary text-primary-foreground border-primary'
                  : 'bg-muted/60 text-muted-foreground border-transparent hover:bg-muted'"
              >
                {{ chip }}
              </button>
            </div>

            <!-- Barre de recherche -->
            <div class="mb-4 relative">
              <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
              <Input
                v-model="searchQuery"
                placeholder="Rechercher un exercice..."
                class="pl-10"
              />
            </div>

            <!-- Grille d'exercices -->
            <div v-if="paginatedExerciseStats.length > 0" class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div
                v-for="stat in paginatedExerciseStats"
                :key="stat.exercise_id"
                class="relative bg-card rounded-xl p-4 cursor-pointer group overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg"
                @click="navigateTo(`/exercices/${stat.exercise_id}`)"
              >
                <div class="absolute inset-0 rounded-xl bg-primary/20 blur-md transition-all duration-300 group-hover:bg-primary/30 group-hover:blur-lg"></div>
                <div class="absolute inset-0 rounded-xl bg-gradient-to-r from-primary/50 via-primary/30 to-primary/50 animate-[pulse_2s_ease-in-out_infinite] group-hover:from-primary/60 group-hover:via-primary/40 group-hover:to-primary/60"></div>
                <div class="absolute inset-0 rounded-xl bg-gradient-to-br from-primary/40 to-transparent animate-[glow_3s_ease-in-out_infinite] group-hover:from-primary/50 group-hover:to-transparent"></div>
                <div class="absolute inset-[1px] rounded-xl bg-card"></div>
                <div class="relative flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <div class="h-10 w-10 shrink-0 rounded-full overflow-hidden bg-primary/20 transition-all duration-300 group-hover:bg-primary/30 group-hover:scale-110 flex items-center justify-center">
                      <img
                        v-if="stat.exercise.image_url"
                        :src="stat.exercise.image_url"
                        :alt="stat.exercise.name"
                        class="h-full w-full object-cover"
                        loading="lazy"
                      />
                      <Dumbbell v-else class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12" />
                    </div>
                    <div>
                      <h4 class="text-base font-medium text-foreground transition-colors duration-300 group-hover:text-primary">{{ stat.exercise.name }}</h4>
                      <span class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full transition-all duration-300 group-hover:bg-primary/10 group-hover:text-primary">
                        {{ stat.exercise.primary_muscle }}
                      </span>
                    </div>
                  </div>
                  <ChevronRight class="w-5 h-5 text-muted-foreground opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                </div>
              </div>
            </div>
            <div v-else class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-muted/70 rounded-lg">
              <ActivitySquare class="w-16 h-16 text-muted-foreground/30" />
              <p class="text-base text-muted-foreground text-center">
                {{ searchQuery || selectedMuscleChip !== 'Tous' ? 'Aucun exercice trouvé' : 'Aucun exercice avec des séries enregistrées' }}
              </p>
              <button
                v-if="searchQuery || selectedMuscleChip !== 'Tous'"
                type="button"
                class="text-sm text-primary underline-offset-2 hover:underline"
                @click="searchQuery = ''; selectedMuscleChip = 'Tous'"
              >
                Réinitialiser les filtres
              </button>
            </div>

            <!-- Pagination -->
            <div v-if="filteredExerciseStats.length > itemsPerPage" class="mt-6 flex items-center justify-between">
              <p class="text-sm text-muted-foreground">
                {{ (currentPage - 1) * itemsPerPage + 1 }}–{{ Math.min(currentPage * itemsPerPage, filteredExerciseStats.length) }} sur {{ filteredExerciseStats.length }}
              </p>
              <div class="flex gap-2">
                <Button variant="outline" size="sm" @click="currentPage--" :disabled="currentPage === 1">Précédent</Button>
                <Button variant="outline" size="sm" @click="currentPage++" :disabled="currentPage >= totalPages">Suivant</Button>
              </div>
            </div>
          </div>
        </div>

        <!-- Colonne secondaire -->
        <div class="space-y-6">
          <!-- Statistiques rapides -->
          <div class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                <BarChart class="w-5 h-5 text-primary" />
              </div>
              <h3 class="text-lg font-semibold">Statistiques</h3>
            </div>

            <div class="space-y-4">
              <div class="flex justify-between items-center p-4 bg-muted rounded-lg">
                <div class="flex items-center gap-3">
                  <div class="p-2 rounded-full bg-primary/10">
                    <Weight class="h-4 w-4 text-primary" />
                  </div>
                  <span class="text-sm font-medium">Exercices pratiqués</span>
                </div>
                <span class="text-xl font-bold text-primary">{{ filteredExerciseStats.length }}</span>
              </div>

              <div class="flex justify-between items-center p-4 bg-muted rounded-lg" v-if="Object.keys(groupedExercises).length > 0">
                <div class="flex items-center gap-3">
                  <div class="p-2 rounded-full bg-primary/10">
                    <ActivitySquare class="h-4 w-4 text-primary" />
                  </div>
                  <span class="text-sm font-medium">Groupes musculaires</span>
                </div>
                <span class="text-xl font-bold text-primary">{{ Object.keys(groupedExercises).length }}</span>
              </div>
            </div>
          </div>

          <!-- Conseils -->
          <div class="bg-primary/10 rounded-xl p-6 hover:shadow-md transition-all duration-300">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
                <Lightbulb class="w-5 h-5 text-primary" />
              </div>
              <h3 class="text-lg font-semibold text-foreground">Conseils</h3>
            </div>
            <div class="space-y-4">
              <p class="text-sm text-muted-foreground">Variez vos exercices pour cibler différents muscles et éviter les plateaux.</p>
              <div class="bg-card p-4 rounded-lg">
                <h4 class="font-medium text-sm mb-2">Pour progresser</h4>
                <ul class="text-xs text-muted-foreground space-y-1.5">
                  <li class="flex items-center">
                    <CheckCircle2 class="h-3.5 w-3.5 mr-2 text-primary" />
                    Augmentez progressivement la charge
                  </li>
                  <li class="flex items-center">
                    <CheckCircle2 class="h-3.5 w-3.5 mr-2 text-primary" />
                    Maintenez une technique correcte
                  </li>
                  <li class="flex items-center">
                    <CheckCircle2 class="h-3.5 w-3.5 mr-2 text-primary" />
                    Notez vos performances
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useExerciseStats } from '~/composables/useExerciseStats'
import { computed, ref, watch } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import CreateCustomExercise from '~/components/exercises/CreateCustomExercise.vue'
import {
  Dumbbell,
  ListChecks,
  AlertTriangle,
  BarChart,
  Lightbulb,
  CheckCircle2,
  ActivitySquare,
  Weight,
  ChevronRight,
  Plus,
  Search
} from 'lucide-vue-next'

const { exerciseStats, error, loading, getExerciseStats } = useExerciseStats()
const showCreateDialog = ref(false)
const searchQuery = ref('')
const selectedMuscleChip = ref('Tous')
const currentPage = ref(1)
const itemsPerPage = 20

// Chips musculaires dynamiques
const muscleChips = computed(() => {
  const muscles = new Set()
  exerciseStats.value.forEach(stat => {
    if (stat.exercise?.primary_muscle) muscles.add(stat.exercise.primary_muscle)
  })
  return ['Tous', ...Array.from(muscles).sort()]
})

const selectMuscleChip = (chip) => {
  selectedMuscleChip.value = chip
  currentPage.value = 1
}

const normalizeText = (t) =>
  (t || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')

// Filtrer par chip + recherche
const filteredExerciseStats = computed(() => {
  let list = exerciseStats.value

  if (selectedMuscleChip.value !== 'Tous') {
    list = list.filter(stat => stat.exercise?.primary_muscle === selectedMuscleChip.value)
  }

  const q = normalizeText(searchQuery.value.trim())
  if (q) {
    list = list.filter(stat => {
      const name = normalizeText(stat.exercise?.name)
      const muscle = normalizeText(stat.exercise?.primary_muscle)
      return name.includes(q) || muscle.includes(q)
    })
  }

  return list
})

// Pagination
const paginatedExerciseStats = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredExerciseStats.value.slice(start, start + itemsPerPage)
})

const totalPages = computed(() =>
  Math.ceil(filteredExerciseStats.value.length / itemsPerPage)
)

watch([searchQuery, selectedMuscleChip], () => { currentPage.value = 1 })

// Groupes pour les stats latérales
const groupedExercises = computed(() => {
  const groups = {}
  exerciseStats.value.forEach(stat => {
    const muscle = stat.exercise.primary_muscle
    if (!groups[muscle]) groups[muscle] = []
    groups[muscle].push(stat)
  })
  return groups
})

const loadStats = async () => {
  try {
    await getExerciseStats()
  } catch (e) {
    error.value = e.message
  }
}

const handleExerciseCreated = async () => {
  // Recharger les stats après création
  await loadStats()
  showCreateDialog.value = false
}

onMounted(loadStats)
</script>

<style scoped>
@keyframes pulse {
  0%, 100% {
    opacity: 0.3;
  }
  50% {
    opacity: 0.7;
  }
}

@keyframes glow {
  0%, 100% {
    opacity: 0.2;
    transform: scale(1);
  }
  50% {
    opacity: 0.4;
    transform: scale(1.02);
  }
}
</style> 
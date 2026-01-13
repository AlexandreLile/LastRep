<template>
  <div class="relative">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8 bg-white rounded-xl p-6">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4 text-red-500" />
      {{ error }}
    </div>

    <div v-else class="space-y-6">
      <!-- En-tête amélioré -->
      <div class="mb-8 bg-white rounded-xl p-6">
        <div class="flex items-center justify-between gap-4">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
              <Dumbbell class="h-6 w-6 text-primary" />
            </div>
            <div>
              <h2 class="text-2xl font-bold text-gray-900">Mes Exercices</h2>
              <p class="text-sm text-muted-foreground">Suivez votre progression sur chaque exercice</p>
            </div>
          </div>
          <Button
            variant="default"
            @click="showCreateDialog = true"
            class="flex items-center gap-2"
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
          <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                <ListChecks class="w-5 h-5 text-primary" />
              </div>
              <div>
                <h3 class="text-lg font-semibold">Liste des exercices</h3>
                <p class="text-sm text-muted-foreground">Exercices avec des séries enregistrées</p>
              </div>
            </div>

            <Tabs default-value="all" class="w-full">
              <div class="overflow-x-auto px-2 pb-2 -mx-2">
                <TabsList class="flex w-full min-w-max space-x-2">
                  <TabsTrigger 
                    value="all" 
                    class="whitespace-nowrap data-[state=active]:bg-primary data-[state=active]:text-white"
                  >
                    Tous
                  </TabsTrigger>
                  <TabsTrigger 
                    v-for="muscle in Object.keys(groupedExercises)" 
                    :key="muscle" 
                    :value="muscle"
                    class="whitespace-nowrap data-[state=active]:bg-primary data-[state=active]:text-white"
                  >
                    {{ muscle }}
                  </TabsTrigger>
                </TabsList>
              </div>

              <TabsContent value="all" class="mt-6">
                <div v-if="exerciseStats.length > 0" class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div 
                    v-for="stat in exerciseStats" 
                    :key="stat.exercise_id" 
                    class="relative bg-white rounded-xl p-4 cursor-pointer group overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg"
                    @click="navigateTo(`/exercices/${stat.exercise_id}`)"
                  >
                    <!-- Effet de bordure néon -->
                    <div class="absolute inset-0 rounded-xl bg-primary/20 blur-md transition-all duration-300 group-hover:bg-primary/30 group-hover:blur-lg"></div>
                    <div class="absolute inset-0 rounded-xl bg-gradient-to-r from-primary/50 via-primary/30 to-primary/50 animate-[pulse_2s_ease-in-out_infinite] group-hover:from-primary/60 group-hover:via-primary/40 group-hover:to-primary/60"></div>
                    <div class="absolute inset-0 rounded-xl bg-gradient-to-br from-primary/40 to-transparent animate-[glow_3s_ease-in-out_infinite] group-hover:from-primary/50 group-hover:to-transparent"></div>
                    <div class="absolute inset-[1px] rounded-xl bg-white"></div>

                    <div class="relative flex items-center justify-between">
                      <div class="flex items-center gap-3">
                        <div class="p-2 rounded-full bg-primary/20 transition-all duration-300 group-hover:bg-primary/30 group-hover:scale-110">
                          <Dumbbell class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12" />
                        </div>
                        <div>
                          <h4 class="text-base font-medium text-gray-900 transition-colors duration-300 group-hover:text-primary">{{ stat.exercise.name }}</h4>
                          <span class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full transition-all duration-300 group-hover:bg-primary/10 group-hover:text-primary">
                            {{ stat.exercise.primary_muscle }}
                          </span>
                        </div>
                      </div>
                      <ChevronRight class="w-5 h-5 text-muted-foreground opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                    </div>
                  </div>
                </div>
                <div v-else class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-gray-50/70 rounded-lg">
                  <ActivitySquare class="w-16 h-16 text-muted-foreground/30" />
                  <p class="text-base text-muted-foreground text-center">
                    Aucun exercice avec des séries enregistrées
                  </p>
                </div>
              </TabsContent>

              <TabsContent 
                v-for="(exercises, muscle) in groupedExercises" 
                :key="muscle" 
                :value="muscle"
                class="mt-6"
              >
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div 
                    v-for="stat in exercises" 
                    :key="stat.exercise_id" 
                    class="relative bg-white rounded-xl p-4 cursor-pointer group overflow-hidden transition-all duration-300 hover:scale-[1.02] hover:shadow-lg"
                    @click="navigateTo(`/exercices/${stat.exercise_id}`)"
                  >
                    <!-- Effet de bordure néon -->
                    <div class="absolute inset-0 rounded-xl bg-primary/20 blur-md transition-all duration-300 group-hover:bg-primary/30 group-hover:blur-lg"></div>
                    <div class="absolute inset-0 rounded-xl bg-gradient-to-r from-primary/50 via-primary/30 to-primary/50 animate-[pulse_2s_ease-in-out_infinite] group-hover:from-primary/60 group-hover:via-primary/40 group-hover:to-primary/60"></div>
                    <div class="absolute inset-0 rounded-xl bg-gradient-to-br from-primary/40 to-transparent animate-[glow_3s_ease-in-out_infinite] group-hover:from-primary/50 group-hover:to-transparent"></div>
                    <div class="absolute inset-[1px] rounded-xl bg-white"></div>

                    <div class="relative flex items-center justify-between">
                      <div class="flex items-center gap-3">
                        <div class="p-2 rounded-full bg-primary/20 transition-all duration-300 group-hover:bg-primary/30 group-hover:scale-110">
                          <Dumbbell class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12" />
                        </div>
                        <div>
                          <h4 class="text-base font-medium text-gray-900 transition-colors duration-300 group-hover:text-primary">{{ stat.exercise.name }}</h4>
                          <span class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full transition-all duration-300 group-hover:bg-primary/10 group-hover:text-primary">
                            {{ stat.exercise.primary_muscle }}
                          </span>
                        </div>
                      </div>
                      <ChevronRight class="w-5 h-5 text-muted-foreground opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                    </div>
                  </div>
                </div>
              </TabsContent>
            </Tabs>
          </div>
        </div>

        <!-- Colonne secondaire -->
        <div class="space-y-6">
          <!-- Statistiques rapides -->
          <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                <BarChart class="w-5 h-5 text-primary" />
              </div>
              <h3 class="text-lg font-semibold">Statistiques</h3>
            </div>

            <div class="space-y-4">
              <div class="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
                <div class="flex items-center gap-3">
                  <div class="p-2 rounded-full bg-primary/10">
                    <Weight class="h-4 w-4 text-primary" />
                  </div>
                  <span class="text-sm font-medium">Exercices pratiqués</span>
                </div>
                <span class="text-xl font-bold text-primary">{{ exerciseStats.length }}</span>
              </div>

              <div class="flex justify-between items-center p-4 bg-gray-50 rounded-lg" v-if="Object.keys(groupedExercises).length > 0">
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
              <h3 class="text-lg font-semibold text-gray-900">Conseils</h3>
            </div>
            <div class="space-y-4">
              <p class="text-sm text-gray-600">Variez vos exercices pour cibler différents muscles et éviter les plateaux.</p>
              <div class="bg-white p-4 rounded-lg">
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
import { computed, ref } from 'vue'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
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
  Plus
} from 'lucide-vue-next'

const { exerciseStats, error, loading, getExerciseStats } = useExerciseStats()
const showCreateDialog = ref(false)

const groupedExercises = computed(() => {
  const groups = {}
  
  exerciseStats.value.forEach(stat => {
    const muscle = stat.exercise.primary_muscle
    if (!groups[muscle]) {
      groups[muscle] = []
    }
    groups[muscle].push(stat)
  })

  // Trier les groupes par ordre alphabétique
  const sortedGroups = Object.keys(groups).sort()
  const result = {}
  sortedGroups.forEach(muscle => {
    result[muscle] = groups[muscle]
  })

  return result
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
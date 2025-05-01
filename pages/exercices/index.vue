<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else class="space-y-8">
      <!-- En-tête -->
      <div class="mb-8">
        <h2 class="text-2xl font-semibold text-gray-900">Mes Exercices</h2>
      </div>

      <!-- Liste des exercices -->
      <div class="bg-white rounded-xl p-8">
        <div class="space-y-6">
          <div>
            <h3 class="text-lg font-medium">Liste des exercices</h3>
            <p class="text-sm text-muted-foreground">Exercices avec des séries enregistrées</p>
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
                  </div>
                </div>
              </div>
              <div v-else class="text-center py-8 text-muted-foreground">
                Aucun exercice avec des séries enregistrées
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
                  </div>
                </div>
              </div>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useExerciseStats } from '~/composables/useExerciseStats'
import { computed } from 'vue'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { Dumbbell } from 'lucide-vue-next'

const { exerciseStats, error, loading, getExerciseStats } = useExerciseStats()

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
<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else class="space-y-6">
      <!-- En-tête -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Mes Exercices</h1>
        <p class="text-gray-500 dark:text-gray-400 mt-2">
          Liste des exercices avec des séries enregistrées
        </p>
      </div>

      <!-- Liste des exercices -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <Tabs default-value="all" class="w-full">
          <div class="overflow-x-auto">
            <TabsList class="flex w-full min-w-max space-x-2">
              <TabsTrigger value="all" class="whitespace-nowrap">Tous</TabsTrigger>
              <TabsTrigger 
                v-for="muscle in Object.keys(groupedExercises)" 
                :key="muscle" 
                :value="muscle"
                class="whitespace-nowrap"
              >
                {{ muscle }}
              </TabsTrigger>
            </TabsList>
          </div>

          <TabsContent value="all" class="mt-4">
            <div v-if="exerciseStats.length > 0" class="space-y-4">
              <div 
                v-for="stat in exerciseStats" 
                :key="stat.exercise_id" 
                class="border dark:border-gray-700 rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
                @click="navigateTo(`/exercices/${stat.exercise_id}`)"
              >
                <div class="flex justify-between items-start">
                  <div>
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{{ stat.exercise.name }}</h3>
                    <p class="text-gray-500 dark:text-gray-400 mt-1">
                      Muscle principal : {{ stat.exercise.primary_muscle }}
                    </p>
                  </div>
                  <div class="text-right">
                    <p class="text-sm text-gray-500 dark:text-gray-400">{{ stat.total_sets }} séries</p>
                  </div>
                </div>
              </div>
            </div>
            <p v-else class="text-center text-gray-500 dark:text-gray-400 py-4">
              Aucun exercice avec des séries enregistrées
            </p>
          </TabsContent>

          <TabsContent 
            v-for="(exercises, muscle) in groupedExercises" 
            :key="muscle" 
            :value="muscle"
            class="mt-4"
          >
            <div class="space-y-4">
              <div 
                v-for="stat in exercises" 
                :key="stat.exercise_id" 
                class="border dark:border-gray-700 rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
                @click="navigateTo(`/exercices/${stat.exercise_id}`)"
              >
                <div class="flex justify-between items-start">
                  <div>
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{{ stat.exercise.name }}</h3>
                  </div>
                  <div class="text-right">
                    <p class="text-sm text-gray-500 dark:text-gray-400">{{ stat.total_sets }} séries</p>
                  </div>
                </div>
              </div>
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useExerciseStats } from '~/composables/useExerciseStats'
import { computed } from 'vue'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'

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
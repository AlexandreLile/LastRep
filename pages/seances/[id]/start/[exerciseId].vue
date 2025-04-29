<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="exercise" class="space-y-6">
      <!-- En-tête de l'exercice -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">{{ exercise.Exercise?.name }}</h1>
            <p class="text-gray-500 dark:text-gray-400 mt-2">
              Muscle principal : {{ exercise.Exercise?.primary_muscle }}
            </p>
          </div>
          <button 
            @click="navigateTo(`/seances/${$route.params.id}/start`)"
            class="bg-gray-500 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition-colors"
          >
            Retour
          </button>
        </div>
      </div>

      <!-- Formulaire pour ajouter une série -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Ajouter une série</h2>
        
        <form @submit.prevent="addSet" class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Poids (kg)
              </label>
              <input
                v-model="newSet.weight_kg"
                type="number"
                step="0.5"
                class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                required
              >
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Répétitions
              </label>
              <input
                v-model="newSet.reps"
                type="number"
                class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                required
              >
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Temps de repos (secondes)
              </label>
              <input
                v-model="newSet.rest_seconds"
                type="number"
                class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                required
              >
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                RPE (1-10)
              </label>
              <input
                v-model="newSet.rpe"
                type="number"
                min="1"
                max="10"
                step="0.5"
                class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
              >
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Notes
            </label>
            <textarea
              v-model="newSet.note"
              class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
              rows="3"
            ></textarea>
          </div>

          <button
            type="submit"
            class="w-full bg-primary text-white px-4 py-2 rounded-lg hover:bg-primary/90 transition-colors"
          >
            Ajouter la série
          </button>
        </form>
      </div>

      <!-- Liste des séries -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Séries effectuées</h2>
        
        <div v-if="sets.length > 0" class="space-y-4">
          <div 
            v-for="set in sets" 
            :key="set.id"
            class="border dark:border-gray-700 rounded-lg p-4"
          >
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <p class="text-sm text-gray-500 dark:text-gray-400">Poids</p>
                <p class="font-semibold">{{ set.weight_kg }} kg</p>
              </div>
              <div>
                <p class="text-sm text-gray-500 dark:text-gray-400">Répétitions</p>
                <p class="font-semibold">{{ set.reps }}</p>
              </div>
              <div>
                <p class="text-sm text-gray-500 dark:text-gray-400">Repos</p>
                <p class="font-semibold">{{ set.rest_seconds }}s</p>
              </div>
              <div>
                <p class="text-sm text-gray-500 dark:text-gray-400">RPE</p>
                <p class="font-semibold">{{ set.rpe || '-' }}</p>
              </div>
            </div>
            <p v-if="set.note" class="mt-2 text-sm text-gray-600 dark:text-gray-300">
              {{ set.note }}
            </p>
          </div>
        </div>

        <div v-else class="text-center py-8 text-gray-500 dark:text-gray-400">
          Aucune série effectuée
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const { $supabase } = useNuxtApp()
const route = useRoute()

const exercise = ref(null)
const sets = ref([])
const loading = ref(true)
const error = ref(null)

const newSet = ref({
  weight_kg: null,
  reps: null,
  rest_seconds: null,
  rpe: null,
  note: ''
})

const loadExercise = async () => {
  try {
    loading.value = true
    const exerciseId = route.params.exerciseId
    console.log('Loading exercise:', exerciseId) // Debug log

    const { data, error: exerciseError } = await $supabase
      .from('workoutexercise')
      .select(`
        id,
        Exercise (
          id,
          name,
          primary_muscle
        )
      `)
      .eq('id', exerciseId)
      .single()

    if (exerciseError) throw exerciseError
    exercise.value = data
    console.log('Exercise loaded:', data) // Debug log

    // Charger les séries existantes
    const { data: setsData, error: setsError } = await $supabase
      .from('exerciseset')
      .select('*')
      .eq('exercise_id', data.Exercise.id)
      .eq('user_id', (await $supabase.auth.getUser()).data.user.id)
      .order('created_at', { ascending: false })

    if (setsError) throw setsError
    sets.value = setsData
  } catch (e) {
    console.error('Error loading exercise:', e) // Debug log
    error.value = e.message
  } finally {
    loading.value = false
  }
}

const addSet = async () => {
  try {
    const { data, error: insertError } = await $supabase
      .from('exerciseset')
      .insert([
        {
          exercise_id: exercise.value.Exercise.id,
          user_id: (await $supabase.auth.getUser()).data.user.id,
          weight_kg: newSet.value.weight_kg,
          reps: newSet.value.reps,
          rest_seconds: newSet.value.rest_seconds,
          rpe: newSet.value.rpe,
          note: newSet.value.note
        }
      ])
      .select()
      .single()

    if (insertError) throw insertError

    // Ajouter la nouvelle série à la liste
    sets.value.unshift(data)

    // Réinitialiser le formulaire
    newSet.value = {
      weight_kg: null,
      reps: null,
      rest_seconds: null,
      rpe: null,
      note: ''
    }
  } catch (e) {
    error.value = e.message
  }
}

onMounted(loadExercise)
</script> 
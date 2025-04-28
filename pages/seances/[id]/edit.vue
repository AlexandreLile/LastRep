<template>
  <div class="container mx-auto px-4 py-8">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center py-8">
      {{ error }}
    </div>

    <div v-else-if="session" class="space-y-6">
      <!-- Formulaire d'édition -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <div class="space-y-4">
            <div>
              <label for="title" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Titre</label>
              <input
                id="title"
                v-model="formData.title"
                type="text"
                class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-primary focus:ring-primary dark:bg-gray-700 dark:text-white sm:text-sm"
                required
              />
            </div>

            <div>
              <label for="notes" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Notes</label>
              <textarea
                id="notes"
                v-model="formData.notes"
                rows="4"
                class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-primary focus:ring-primary dark:bg-gray-700 dark:text-white sm:text-sm"
              ></textarea>
            </div>
          </div>

          <div class="flex justify-end gap-4">
            <button
              type="button"
              @click="router.push(`/seances/${route.params.id}`)"
              class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
            >
              Annuler
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="px-4 py-2 text-sm font-medium text-white bg-primary rounded-md shadow-sm hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50"
            >
              <span v-if="saving">Enregistrement...</span>
              <span v-else>Enregistrer</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useWorkoutSessions } from '~/composables/useWorkoutSession'

const route = useRoute()
const router = useRouter()
const { getWorkoutSession, editWorkoutSession } = useWorkoutSessions(useSupabaseUser())

const session = ref(null)
const loading = ref(true)
const saving = ref(false)
const error = ref(null)

const formData = ref({
  title: '',
  notes: ''
})

const loadSession = async () => {
  try {
    loading.value = true
    const { data, error: sessionError } = await getWorkoutSession(route.params.id)
    if (sessionError) throw sessionError
    session.value = data
    formData.value = {
      title: data.title,
      notes: data.notes || ''
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

const handleSubmit = async () => {
  try {
    saving.value = true
    const result = await editWorkoutSession(route.params.id, formData.value)
    if (!result.success) {
      throw new Error(result.error || 'Une erreur est survenue lors de l\'édition de la séance')
    }
    router.push(`/seances/${route.params.id}/train`)
  } catch (e) {
    console.error('Erreur lors de l\'édition:', e)
    error.value = e.message
  } finally {
    saving.value = false
  }
}

onMounted(loadSession)
</script> 
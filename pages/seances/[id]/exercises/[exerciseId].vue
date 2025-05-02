<template>
  <div class="space-y-6">
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="flex items-center justify-center p-4 text-sm text-red-500 bg-red-50 rounded-lg">
      {{ error }}
    </div>

    <div v-else class="space-y-6 mt-24 md:mt-0">
      <!-- En-tête de l'exercice -->
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div class="space-y-1">
          <h2 class="text-2xl font-semibold tracking-tight">{{ exercise.exercise?.name }}</h2>
          <div class="flex items-center space-x-2 text-sm text-muted-foreground">
            <Dumbbell class="w-4 h-4" />
            <span>{{ exercise.exercise?.primary_muscle }}</span>
          </div>
        </div>
        <Button variant="outline" size="sm" @click="navigateTo(`/seances/${$route.params.id}/start`)" class="w-full md:w-auto">
          Retour
        </Button>
      </div>

      <!-- Formulaire d'ajout de série -->
      <div class="bg-white rounded-xl p-6 space-y-6">
        <div class="flex items-center space-x-2">
          <Plus class="w-5 h-5 text-primary" />
          <h3 class="text-lg font-semibold tracking-tight">Ajouter une série</h3>
        </div>

        <form @submit.prevent="handleAddSet" class="space-y-6">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div class="space-y-2">
              <Label>Poids (kg)</Label>
              <Input 
                v-model="newSet.weight" 
                type="number" 
                step="0.5"
                required
              />
            </div>
            <div class="space-y-2">
              <Label>Répétitions</Label>
              <Input 
                v-model="newSet.reps" 
                type="number"
                required
              />
            </div>
            <div class="space-y-2">
              <Label>Temps de repos (secondes)</Label>
              <Input 
                v-model="newSet.restTime" 
                type="number"
                required
              />
            </div>
            <div class="space-y-2">
              <Label>RPE (1-10)</Label>
              <Input 
                v-model="newSet.rpe" 
                type="number" 
                min="1" 
                max="10"
              />
            </div>
          </div>
          <div class="space-y-2">
            <Label>Note</Label>
            <Textarea 
              v-model="newSet.note" 
              rows="2"
              placeholder="Ajouter une note (optionnel)"
            />
          </div>
          <Button type="submit" :disabled="exerciseSetLoading" class="w-full sm:w-auto">
            <Loader2 v-if="exerciseSetLoading" class="w-4 h-4 mr-2 animate-spin" />
            {{ exerciseSetLoading ? 'Ajout en cours...' : 'Ajouter la série' }}
          </Button>
        </form>
      </div>

      <!-- Liste des séries -->
      <div class="bg-white rounded-xl p-6 space-y-6">
        <div class="flex items-center space-x-2">
          <ListOrdered class="w-5 h-5 text-primary" />
          <h3 class="text-lg font-semibold tracking-tight">Séries effectuées</h3>
        </div>

        <div v-if="exerciseSets.length > 0" class="space-y-4">
          <div 
            v-for="set in exerciseSets" 
            :key="set.id" 
            class="bg-muted/50 rounded-lg p-4 space-y-4"
          >
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
              <div class="space-y-1">
                <span class="text-sm text-muted-foreground">Poids</span>
                <p class="font-medium">{{ set.weight_kg }} kg</p>
              </div>
              <div class="space-y-1">
                <span class="text-sm text-muted-foreground">Répétitions</span>
                <p class="font-medium">{{ set.reps }}</p>
              </div>
              <div class="space-y-1">
                <span class="text-sm text-muted-foreground">Repos</span>
                <p class="font-medium">{{ set.rest_seconds }}s</p>
              </div>
              <div class="space-y-1">
                <span class="text-sm text-muted-foreground">RPE</span>
                <p class="font-medium">{{ set.rpe || '-' }}</p>
              </div>
            </div>
            
            <div v-if="set.note" class="text-sm text-muted-foreground">
              {{ set.note }}
            </div>

            <div class="flex justify-end">
              <Button 
                variant="ghost" 
                size="icon"
                @click="deleteSet(set.id)"
                class="text-red-500 hover:text-red-600 hover:bg-red-50"
              >
                <Trash2 class="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
        
        <div v-else class="flex flex-col items-center justify-center py-8 px-4 space-y-4 bg-muted/50 rounded-lg">
          <ListX class="w-12 h-12 text-muted-foreground/50" />
          <p class="text-sm text-muted-foreground text-center">
            Aucune série effectuée pour le moment
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useWorkoutExercise } from '~/composables/useWorkoutExercise'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { useExerciseSet } from '~/composables/useExerciseSet'
import { useSupabaseClient } from '#imports'
import { useSupabaseUser } from '#imports'
import { Trash2, Dumbbell, Plus, ListOrdered, ListX, Loader2 } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

definePageMeta({
  layout: 'start-session'
})

const route = useRoute()
const supabase = useSupabaseClient()
const { getWorkoutExercise } = useWorkoutExercise()
const { getCurrentSession } = usePerformedSession(supabase)
const { exerciseSets, error: exerciseSetError, loading: exerciseSetLoading, addExerciseSet, getExerciseSets } = useExerciseSet()

const exercise = ref(null)
const loading = ref(true)
const error = ref(null)

const newSet = ref({
  weight: '',
  reps: '',
  restTime: '',
  rpe: '',
  note: ''
})

const handleAddSet = async () => {
  try {
    const { error: addError } = await addExerciseSet(exercise.value.exercise.id, newSet.value)
    if (addError) throw addError
    
    // Recharger les séries
    await loadExerciseSets()

    // Préremplir le formulaire avec la dernière série (celle qu'on vient d'ajouter)
    if (exerciseSets.value && exerciseSets.value.length > 0) {
      const lastSet = exerciseSets.value[0]
      newSet.value = {
        weight: lastSet.weight_kg,
        reps: lastSet.reps,
        restTime: lastSet.rest_seconds,
        rpe: lastSet.rpe || '',
        note: lastSet.note || ''
      }
    }
  } catch (e) {
    error.value = e.message
  }
}

const loadExerciseSets = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error: setsError } = await supabase
      .from('exerciseset')
      .select('*')
      .eq('exercise_id', exercise.value.exercise.id)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(10)

    if (setsError) throw setsError
    exerciseSets.value = data || []
  } catch (e) {
    error.value = e.message
  }
}

const loadExercise = async () => {
  try {
    loading.value = true
    // Vérifier si une session est en cours
    const currentSession = getCurrentSession()
    if (!currentSession) {
      navigateTo(`/seances/${route.params.id}/train`)
      return
    }

    const { data, error: exerciseError } = await getWorkoutExercise(route.params.exerciseId)
    if (exerciseError) throw exerciseError
    exercise.value = data

    // Charger les séries de l'exercice
    await loadExerciseSets()

    // Préremplir le formulaire avec la dernière série
    if (exerciseSets.value && exerciseSets.value.length > 0) {
      const lastSet = exerciseSets.value[0]
      newSet.value = {
        weight: lastSet.weight_kg,
        reps: lastSet.reps,
        restTime: lastSet.rest_seconds,
        rpe: lastSet.rpe || '',
        note: lastSet.note || ''
      }
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

const deleteSet = async (setId) => {
  try {
    const { error: deleteError } = await supabase
      .from('exerciseset')
      .delete()
      .eq('id', setId)

    if (deleteError) throw deleteError

    // Recharger les séries après la suppression
    await loadExerciseSets()
  } catch (e) {
    error.value = e.message
  }
}

onMounted(loadExercise)
</script> 
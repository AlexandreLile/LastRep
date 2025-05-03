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
      <div class="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="text-2xl font-semibold text-gray-900">{{ exercise.name }}</h2>
          <div class="mt-2">
            <span class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full">
              {{ exercise.primary_muscle }}
            </span>
          </div>
        </div>
        <Button 
          variant="outline"
          @click="navigateTo('/exercices')"
        >
          Retour
        </Button>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6 mb-8">
        <div class="bg-white rounded-xl p-6">
          <LastSetRMStats :exercise-id="route.params.id" />
        </div>
        <div class="bg-white rounded-xl p-6">
          <LastExerciseSessionStats :exercise-id="route.params.id" />
        </div>
        <div class="bg-white rounded-xl p-6">
          <TotalVolumeStats :exercise-id="route.params.id" />
        </div>
      </div>

      <!-- Graphiques -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-white rounded-xl p-6 flex flex-col h-full">
          <div class="mb-4">
            <h3 class="text-lg font-medium mb-2">Poids vs Répétitions</h3>
            <p class="text-sm text-muted-foreground">Maximum de répétitions pour chaque poids</p>
          </div>
          <div class="flex-1">
            <WeightRepsChart :exercise-id="route.params.id" />
          </div>
        </div>
        <div class="bg-white rounded-xl p-6 flex flex-col h-full">
          <div class="mb-4">
            <h3 class="text-lg font-medium mb-2">Progression du poids</h3>
            <p class="text-sm text-muted-foreground">Poids maximum par jour d'entraînement</p>
          </div>
          <div class="flex-1">
            <WeightProgressionChart :exercise-id="route.params.id" />
          </div>
        </div>
      </div>

      <div class="mt-6 bg-white rounded-xl p-6">
        <div class="mb-4">
          <h3 class="text-lg font-medium mb-2">1RM estimé</h3>
          <p class="text-sm text-muted-foreground">Répétition maximale estimée</p>
        </div>
        <div class="text-2xl font-semibold">
          <RMCalculator :exercise-id="route.params.id" />
        </div>
      </div>

      <!-- Historique des séries -->
      <div class="bg-white rounded-xl p-6">
        <div class="space-y-6">
          <div>
            <h3 class="text-lg font-medium">Historique des séries</h3>
            <p class="text-sm text-muted-foreground">Liste de toutes vos séries</p>
          </div>
          
          <div v-if="sets.length > 0" class="space-y-4">
            <div 
              v-for="set in sets" 
              :key="set.id"
              class="relative bg-white border border-muted rounded-xl p-4 hover:shadow-md transition-all duration-200"
            >
              <div class="flex justify-between items-start">
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 flex-1">
                  <div>
                    <p class="text-sm text-muted-foreground">Poids</p>
                    <p class="text-lg font-medium">{{ set.weight_kg }} kg</p>
                  </div>
                  <div>
                    <p class="text-sm text-muted-foreground">Répétitions</p>
                    <p class="text-lg font-medium">{{ set.reps }}</p>
                  </div>
                  <div>
                    <p class="text-sm text-muted-foreground">Date</p>
                    <p class="text-lg font-medium">{{ formatDate(set.created_at) }}</p>
                  </div>
                </div>
                <Button 
                  variant="ghost"
                  size="icon"
                  @click="openEditModal(set)"
                >
                  <Pencil class="h-4 w-4" />
                </Button>
              </div>
              <div v-if="set.note" class="mt-2 text-sm text-muted-foreground">
                {{ set.note }}
              </div>
            </div>
          </div>
          <div v-else class="text-center py-8 text-muted-foreground">
            Aucune série enregistrée pour cet exercice
          </div>
        </div>
      </div>
    </div>

    <!-- Modal d'édition -->
    <Dialog :open="!!editingSet" @update:open="closeEditModal">
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Modifier la série</DialogTitle>
        </DialogHeader>
        
        <form @submit.prevent="handleEditSet" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label>Poids (kg)</Label>
              <Input 
                v-model="editForm.weight_kg" 
                type="number" 
                step="0.5" 
                required
              />
            </div>
            <div class="space-y-2">
              <Label>Répétitions</Label>
              <Input 
                v-model="editForm.reps" 
                type="number" 
                required
              />
            </div>
            <div class="space-y-2">
              <Label>Temps de repos (s)</Label>
              <Input 
                v-model="editForm.rest_seconds" 
                type="number" 
                required
              />
            </div>
            <div class="space-y-2">
              <Label>RPE (1-10)</Label>
              <Input 
                v-model="editForm.rpe" 
                type="number" 
                min="1" 
                max="10"
              />
            </div>
          </div>
          <div class="space-y-2">
            <Label>Note</Label>
            <Textarea 
              v-model="editForm.note" 
              rows="2"
            />
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              @click="closeEditModal"
            >
              Annuler
            </Button>
            <Button type="submit">
              Enregistrer
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'
import WeightRepsChart from '~/components/charts/WeightRepsChart.vue'
import WeightProgressionChart from '~/components/charts/WeightProgressionChart.vue'
import RMCalculator from '~/components/charts/RMCalculator.vue'
import LastSetRMStats from '~/components/stats/LastSetRMStats.vue'
import LastExerciseSessionStats from '~/components/stats/LastExerciseSessionStats.vue'
import TotalVolumeStats from '~/components/stats/TotalVolumeStats.vue'
import { Pencil } from 'lucide-vue-next'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

const route = useRoute()
const supabase = useSupabaseClient()

const exercise = ref(null)
const sets = ref([])
const loading = ref(true)
const error = ref(null)
const editingSet = ref(null)
const editForm = ref({
  weight_kg: '',
  reps: '',
  rest_seconds: '',
  rpe: '',
  note: ''
})

const loadExerciseData = async () => {
  try {
    loading.value = true
    const user = (await supabase.auth.getUser()).data.user
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    // Récupérer l'exercice
    const { data: exerciseData, error: exerciseError } = await supabase
      .from('exercise')
      .select('*')
      .eq('id', route.params.id)
      .single()

    if (exerciseError) throw exerciseError
    exercise.value = exerciseData

    // Récupérer les séries
    const { data: setsData, error: setsError } = await supabase
      .from('exerciseset')
      .select(`
        id,
        weight_kg,
        reps,
        rest_seconds,
        rpe,
        note,
        created_at
      `)
      .eq('exercise_id', route.params.id)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })

    if (setsError) throw setsError
    sets.value = setsData

    // Les statistiques sont maintenant gérées par les composants dédiés
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

const openEditModal = (set) => {
  editingSet.value = set
  editForm.value = {
    weight_kg: set.weight_kg,
    reps: set.reps,
    rest_seconds: set.rest_seconds,
    rpe: set.rpe,
    note: set.note
  }
}

const closeEditModal = () => {
  editingSet.value = null
  editForm.value = {
    weight_kg: '',
    reps: '',
    rest_seconds: '',
    rpe: '',
    note: ''
  }
}

const handleEditSet = async () => {
  try {
    const { error: updateError } = await supabase
      .from('exerciseset')
      .update({
        weight_kg: editForm.value.weight_kg,
        reps: editForm.value.reps,
        rest_seconds: editForm.value.rest_seconds,
        rpe: editForm.value.rpe,
        note: editForm.value.note
      })
      .eq('id', editingSet.value.id)

    if (updateError) throw updateError

    // Recharger les données
    await loadExerciseData()
    closeEditModal()
  } catch (e) {
    error.value = e.message
  }
}

onMounted(loadExerciseData)
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
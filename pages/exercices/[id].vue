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
        <div class="flex flex-col sm:flex-row gap-4 sm:items-center sm:justify-between">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
              <Dumbbell class="h-6 w-6 text-primary" />
            </div>
            <div>
              <h2 class="text-2xl font-bold text-gray-900">{{ exercise.name }}</h2>
              <div class="mt-2">
                <span class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full">
                  {{ exercise.primary_muscle }}
                </span>
              </div>
            </div>
          </div>
          <Button 
            variant="outline"
            @click="navigateTo('/exercices')"
            class="flex items-center gap-2"
          >
            <ArrowLeft class="h-4 w-4" />
            Retour aux exercices
          </Button>
        </div>
      </div>

      <!-- Stats Grid avec styles améliorés -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6 mb-6">
        <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-3">
            <div class="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center">
              <Trophy class="h-5 w-5 text-primary" />
            </div>
            <h3 class="text-sm font-medium text-muted-foreground">1RM max</h3>
          </div>
          <LastSetRMStats :exercise-id="route.params.id" />
        </div>
        <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-3">
            <div class="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center">
              <Calendar class="h-5 w-5 text-primary" />
            </div>
            <h3 class="text-sm font-medium text-muted-foreground">Dernière séance</h3>
          </div>
          <LastExerciseSessionStats :exercise-id="route.params.id" />
        </div>
        <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-3">
            <div class="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center">
              <Weight class="h-5 w-5 text-primary" />
            </div>
            <h3 class="text-sm font-medium text-muted-foreground">Volume total</h3>
          </div>
          <TotalVolumeStats :exercise-id="route.params.id" />
        </div>
      </div>

      <!-- Graphiques avec en-têtes améliorés -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-white rounded-xl p-6 flex flex-col h-full hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <BarChart class="w-5 h-5 text-primary" />
            </div>
            <div>
              <h3 class="text-lg font-semibold">Poids vs Répétitions</h3>
              <p class="text-sm text-muted-foreground">Maximum de répétitions pour chaque poids</p>
            </div>
          </div>
          <div class="flex-1">
            <WeightRepsChart :exercise-id="route.params.id" />
          </div>
        </div>
        <div class="bg-white rounded-xl p-6 flex flex-col h-full hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <LineChart class="w-5 h-5 text-primary" />
            </div>
            <div>
              <h3 class="text-lg font-semibold">Progression du poids</h3>
              <p class="text-sm text-muted-foreground">Poids maximum par jour d'entraînement</p>
            </div>
          </div>
          <div class="flex-1">
            <WeightProgressionChart :exercise-id="route.params.id" />
          </div>
        </div>
      </div>

      <!-- 1RM estimé -->
      <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Target class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">1RM estimé</h3>
            <p class="text-sm text-muted-foreground">Répétition maximale estimée</p>
          </div>
        </div>
        <div class="text-2xl font-semibold text-primary pl-2">
          <RMCalculator :exercise-id="route.params.id" />
        </div>
      </div>

      <!-- Historique des séries -->
      <div class="bg-white rounded-xl p-6 hover:shadow-md transition-all duration-300">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <History class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Historique des séries</h3>
            <p class="text-sm text-muted-foreground">Liste de toutes vos séries</p>
          </div>
        </div>
        
        <Tabs default-value="week" class="w-full">
          <div class="overflow-x-auto px-2 pb-2 -mx-2">
            <TabsList class="flex w-full min-w-max space-x-2">
              <TabsTrigger 
                value="week" 
                class="whitespace-nowrap data-[state=active]:bg-primary data-[state=active]:text-white"
              >
                Cette semaine
              </TabsTrigger>
              <TabsTrigger 
                value="month" 
                class="whitespace-nowrap data-[state=active]:bg-primary data-[state=active]:text-white"
              >
                Ce mois
              </TabsTrigger>
              <TabsTrigger 
                value="year" 
                class="whitespace-nowrap data-[state=active]:bg-primary data-[state=active]:text-white"
              >
                Cette année
              </TabsTrigger>
            </TabsList>
          </div>

          <TabsContent v-for="period in ['week', 'month', 'year']" :key="period" :value="period" class="mt-6">
            <div v-if="filteredSets(period).length > 0" class="space-y-4">
              <div 
                v-for="set in filteredSets(period)" 
                :key="set.id"
                class="relative bg-white border border-primary/30 rounded-xl p-4 hover:shadow-md hover:border-primary transition-all duration-200 group"
              >
                <div class="flex justify-between items-start">
                  <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 flex-1">
                    <div>
                      <div class="flex items-center gap-2 mb-1">
                        <Weight class="h-4 w-4 text-primary" />
                        <p class="text-sm text-muted-foreground">Poids</p>
                      </div>
                      <p class="text-lg font-medium">{{ set.weight_kg }} kg</p>
                    </div>
                    <div>
                      <div class="flex items-center gap-2 mb-1">
                        <Repeat class="h-4 w-4 text-primary" />
                        <p class="text-sm text-muted-foreground">Répétitions</p>
                      </div>
                      <p class="text-lg font-medium">{{ set.reps }}</p>
                    </div>
                    <div>
                      <div class="flex items-center gap-2 mb-1">
                        <CalendarDays class="h-4 w-4 text-primary" />
                        <p class="text-sm text-muted-foreground">Date</p>
                      </div>
                      <p class="text-lg font-medium">{{ formatDate(set.created_at) }}</p>
                    </div>
                  </div>
                  <Button 
                    variant="ghost"
                    size="icon"
                    @click="openEditModal(set)"
                    class="text-primary hover:bg-primary/10"
                  >
                    <Pencil class="h-4 w-4" />
                  </Button>
                </div>
                <div v-if="set.note" class="mt-3 text-sm text-muted-foreground bg-muted/30 p-2 rounded-lg">
                  <div class="flex items-center gap-2 mb-1">
                    <MessageSquare class="h-4 w-4 text-primary" />
                    <span class="font-medium text-primary/80">Note:</span>
                  </div>
                  {{ set.note }}
                </div>
              </div>
            </div>
            <div v-else class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-gray-50/70 rounded-lg">
              <History class="w-16 h-16 text-muted-foreground/30" />
              <p class="text-base text-muted-foreground text-center">
                Aucune série enregistrée pour cette période
              </p>
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </div>

    <!-- Modal d'édition amélioré -->
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
import { 
  Dumbbell, 
  Pencil,
  AlertTriangle,
  Trophy,
  Calendar,
  Weight,
  BarChart,
  LineChart,
  Target,
  History,
  Repeat,
  CalendarDays,
  MessageSquare,
  ArrowLeft
} from 'lucide-vue-next'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'

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

const filteredSets = (period) => {
  const now = new Date()
  let startDate = new Date()
  
  switch (period) {
    case 'week':
      // Get first day of current week (Sunday = 0, Monday = 1, etc.)
      const firstDayOfWeek = 1 // Monday
      const dayOfWeek = now.getDay() || 7 // Convert Sunday from 0 to 7
      const diff = dayOfWeek >= firstDayOfWeek ? dayOfWeek - firstDayOfWeek : 6 - firstDayOfWeek + dayOfWeek
      startDate.setDate(now.getDate() - diff)
      break
    case 'month':
      // First day of current month
      startDate.setDate(1)
      break
    case 'year':
      // First day of current year
      startDate.setMonth(0, 1)
      break
  }
  
  // Set to beginning of the day
  startDate.setHours(0, 0, 0, 0)
  
  return sets.value.filter(set => {
    const setDate = new Date(set.created_at)
    return setDate >= startDate
  })
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
<template>
  <div class="space-y-6">
    <Toaster />
    <Dialog :open="showRestModal" @update:open="showRestModal = $event">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Temps de repos</DialogTitle>
          <DialogDescription>
            Reposez-vous avant votre prochaine série
          </DialogDescription>
        </DialogHeader>
        <div class="flex flex-col items-center justify-center py-6">
          <div class="text-4xl font-bold text-primary mb-4">{{ formatTime(restTimeRemaining) }}</div>
          <div class="text-sm text-muted-foreground mb-6">Temps restant</div>
          <div class="flex gap-4">
            <Button variant="outline" @click="cancelRest">
              Annuler
            </Button>
            <Button variant="default" @click="skipRest">
              Passer
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>

    <Dialog :open="showEditModal" @update:open="showEditModal = $event">
      <DialogContent class="sm:max-w-md w-[95vw] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Modifier la série</DialogTitle>
          <DialogDescription>
            Modifiez les détails de votre série ou supprimez-la
          </DialogDescription>
        </DialogHeader>
        <form @submit.prevent="handleUpdateSet" class="space-y-6">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label class="font-medium">Poids (kg)</Label>
              <Input 
                v-model="editingSet.weight_kg" 
                type="number" 
                step="0.5"
                class="focus:border-primary focus:ring-primary w-full"
                required
              />
            </div>
            <div class="space-y-2">
              <Label class="font-medium">Répétitions</Label>
              <Input 
                v-model="editingSet.reps" 
                type="number"
                class="focus:border-primary focus:ring-primary w-full"
                required
              />
            </div>
            <div class="space-y-2">
              <Label class="font-medium">Temps de repos (secondes)</Label>
              <Input 
                v-model="editingSet.rest_seconds" 
                type="number"
                class="focus:border-primary focus:ring-primary w-full"
                required
              />
            </div>
            <div class="space-y-2">
              <Label class="font-medium">RPE (1-10)</Label>
              <Input 
                v-model="editingSet.rpe" 
                type="number" 
                min="1" 
                max="10"
                class="focus:border-primary focus:ring-primary w-full"
              />
            </div>
          </div>
          <div class="space-y-2">
            <Label class="font-medium">Note</Label>
            <Textarea 
              v-model="editingSet.note" 
              rows="2"
              placeholder="Ajouter une note (optionnel)"
              class="focus:border-primary focus:ring-primary w-full"
            />
          </div>
          <div class="flex flex-col sm:flex-row justify-between gap-4">
            <Button 
              type="button" 
              variant="destructive" 
              @click="confirmDelete"
              class="flex items-center justify-center gap-2 w-full sm:w-auto"
            >
              <Trash2 class="w-4 h-4" />
              Supprimer
            </Button>
            <div class="flex flex-col sm:flex-row gap-2 w-full sm:w-auto">
              <Button 
                type="button" 
                variant="outline" 
                @click="showEditModal = false"
                class="w-full sm:w-auto"
              >
                Annuler
              </Button>
              <Button 
                type="submit" 
                :disabled="updating"
                class="w-full sm:w-auto"
              >
                <Loader2 v-if="updating" class="w-4 h-4 mr-2 animate-spin" />
                {{ updating ? 'Mise à jour...' : 'Enregistrer' }}
              </Button>
            </div>
          </div>
        </form>
      </DialogContent>
    </Dialog>

    <Dialog :open="showDeleteModal" @update:open="showDeleteModal = $event">
      <DialogContent class="sm:max-w-md w-[95vw]">
        <DialogHeader>
          <DialogTitle>Supprimer la série</DialogTitle>
          <DialogDescription>
            Êtes-vous sûr de vouloir supprimer cette série ? Cette action est irréversible.
          </DialogDescription>
        </DialogHeader>
        <div class="flex flex-col sm:flex-row justify-end gap-3 mt-4">
          <Button 
            variant="outline" 
            @click="showDeleteModal = false"
            class="w-full sm:w-auto"
          >
            Annuler
          </Button>
          <Button 
            variant="destructive" 
            @click="handleDelete"
            :disabled="deleting"
            class="w-full sm:w-auto"
          >
            <Loader2 v-if="deleting" class="w-4 h-4 mr-2 animate-spin" />
            {{ deleting ? 'Suppression...' : 'Supprimer' }}
          </Button>
        </div>
      </DialogContent>
    </Dialog>

    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="flex items-center justify-center p-4 text-sm text-red-500 bg-red-50 rounded-lg">
      {{ error }}
    </div>
    <div v-else class="space-y-6 mt-24 md:mt-0">
      <!-- En-tête de l'exercice -->
      <div class="bg-white rounded-xl p-6">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex items-start gap-4">
            <div class="p-3 rounded-full bg-primary/10 flex-shrink-0">
              <Dumbbell class="h-6 w-6 text-primary" />
            </div>
            <div>
              <h2 class="text-2xl font-bold text-gray-900">{{ exercise.exercise?.name }}</h2>
              <div class="flex items-center mt-1.5">
                <span class="text-xs font-medium bg-gray-100 text-gray-700 px-2 py-1 rounded-full">{{ exercise.exercise?.primary_muscle }}</span>
              </div>
            </div>
          </div>
          
          <div class="flex items-center gap-3">
            <div class="text-sm text-muted-foreground bg-gray-50/70 px-3 py-1.5 rounded-md">
              <span v-if="localExerciseSets.length === 0">Aucune série</span>
              <span v-else>{{ localExerciseSets.length }} série{{ localExerciseSets.length > 1 ? 's' : '' }}</span>
            </div>
            <Button variant="outline" size="sm" @click="handleReturn" class="flex items-center gap-2">
              <ArrowLeft class="w-4 h-4" />
              Retour
            </Button>
          </div>
        </div>
      </div>

      <!-- Record personnel -->
      <div class="bg-white rounded-xl p-6 border-2 border-primary/20">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Trophy class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Record personnel</h3>
            <p class="text-sm text-muted-foreground">Essayez de battre votre meilleure performance</p>
          </div>
        </div>
        
        <div v-if="bestSet" class="bg-primary/5 rounded-lg p-4">
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-4">
            <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Poids max</span>
              <p class="font-bold text-lg text-primary">{{ bestSet.weight_kg }} kg</p>
            </div>
            <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Répétitions</span>
              <p class="font-bold text-lg">{{ bestSet.reps }}</p>
            </div>
            <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Date</span>
              <p class="text-sm">{{ formatDate(bestSet.created_at) }}</p>
            </div>
          </div>
        </div>
        
        <div v-else class="flex flex-col items-center justify-center py-6 px-4 space-y-2 bg-gray-50/70 rounded-lg">
          <Trophy class="w-8 h-8 text-muted-foreground/30" />
          <p class="text-sm text-muted-foreground text-center">
            Pas encore de record sur cet exercice
          </p>
        </div>
      </div>

      <!-- Formulaire d'ajout de série -->
      <div class="bg-white rounded-xl p-6">
        <div class="flex items-center gap-3 mb-6">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Plus class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Ajouter une série</h3>
            <p class="text-sm text-muted-foreground">Renseignez les détails de votre série</p>
          </div>
        </div>

        <form @submit.prevent="handleAddSet" class="space-y-6">
          <AdaptSetInput
            v-if="exercise && exercise.exercise && exercise.exercise.measurement_type"
            :exercise="exercise.exercise"
            v-model="newSet"
          />
          <div v-else-if="exercise && exercise.exercise && !exercise.exercise.measurement_type" class="text-sm text-muted-foreground p-4 bg-yellow-50 rounded-lg">
            ⚠️ Type de mesure non défini pour cet exercice. Utilisation du type par défaut (Poids + Répétitions).
          </div>
          <div v-else class="text-sm text-muted-foreground p-4">
            Chargement de l'exercice...
          </div>
          <Button type="submit" :disabled="exerciseSetLoading" class="w-full sm:w-auto">
            <Loader2 v-if="exerciseSetLoading" class="w-4 h-4 mr-2 animate-spin" />
            {{ exerciseSetLoading ? 'Ajout en cours...' : 'Ajouter la série' }}
          </Button>
        </form>
      </div>

      <!-- Liste des séries -->
      <div class="bg-white rounded-xl p-6">
        <div class="flex items-center gap-3 mb-6">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <ListOrdered class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Séries effectuées</h3>
            <p class="text-sm text-muted-foreground">Historique de vos performances</p>
          </div>
        </div>

        <div v-if="localExerciseSets.length > 0" class="space-y-4">
          <div 
            v-for="(set, index) in localExerciseSets" 
            :key="set.id" 
            class="bg-gray-50/70 rounded-lg p-4 space-y-4 transition-all duration-300 hover:bg-gray-50"
            :style="{animationDelay: `${index * 0.1}s`}"
            :class="{'animate-fade-in': true}"
          >
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
              <!-- Affichage adaptatif selon le type d'exercice -->
              <template v-if="exercise && exercise.exercise && exercise.exercise.measurement_type === 'weight_reps'">
                <div class="space-y-1">
                  <span class="text-xs text-muted-foreground uppercase">Poids</span>
                  <p class="font-medium text-primary">{{ set.weight_kg || 0 }} kg</p>
                </div>
                <div class="space-y-1">
                  <span class="text-xs text-muted-foreground uppercase">Répétitions</span>
                  <p class="font-medium">{{ set.reps }}</p>
                </div>
              </template>
              <template v-else-if="exercise && exercise.exercise && exercise.exercise.measurement_type === 'reps'">
                <div class="space-y-1">
                  <span class="text-xs text-muted-foreground uppercase">Répétitions</span>
                  <p class="font-medium">{{ set.reps }}</p>
                  <p v-if="set.weight_kg && parseFloat(set.weight_kg) > 0" class="text-xs text-primary">
                    (lesté +{{ set.weight_kg }}kg)
                  </p>
                </div>
              </template>
              <template v-else-if="exercise && exercise.exercise && exercise.exercise.measurement_type === 'time'">
                <div class="space-y-1">
                  <span class="text-xs text-muted-foreground uppercase">Durée</span>
                  <p class="font-medium">{{ formatDuration(set.duration_seconds) }}</p>
                </div>
                <div v-if="set.reps" class="space-y-1">
                  <span class="text-xs text-muted-foreground uppercase">Séries</span>
                  <p class="font-medium">{{ set.reps }}</p>
                </div>
              </template>
              <template v-else-if="exercise && exercise.exercise && exercise.exercise.measurement_type === 'time_distance'">
                <div class="space-y-1">
                  <span class="text-xs text-muted-foreground uppercase">Durée</span>
                  <p class="font-medium">{{ formatDuration(set.duration_seconds) }}</p>
                </div>
                <div class="space-y-1">
                  <span class="text-xs text-muted-foreground uppercase">Distance</span>
                  <p class="font-medium">{{ (set.distance_meters / 1000).toFixed(2) }} km</p>
                </div>
              </template>
              <template v-else-if="exercise && exercise.exercise && exercise.exercise.measurement_type === 'distance'">
                <div class="space-y-1">
                  <span class="text-xs text-muted-foreground uppercase">Distance</span>
                  <p class="font-medium">{{ (set.distance_meters / 1000).toFixed(2) }} km</p>
                </div>
              </template>
              <template v-else-if="exercise && exercise.exercise && exercise.exercise.measurement_type === 'weight_only'">
                <div class="space-y-1">
                  <span class="text-xs text-muted-foreground uppercase">Poids</span>
                  <p class="font-medium text-primary">{{ set.weight_kg }} kg</p>
                </div>
              </template>
              <div class="space-y-1">
                <span class="text-xs text-muted-foreground uppercase">Repos</span>
                <p class="font-medium">{{ set.rest_seconds || '-' }}s</p>
              </div>
              <div class="space-y-1">
                <span class="text-xs text-muted-foreground uppercase">RPE</span>
                <p class="font-medium">{{ set.rpe || '-' }}</p>
              </div>
            </div>
            
            <div v-if="set.note" class="p-2 bg-gray-100/70 rounded text-sm text-muted-foreground italic">
              {{ set.note }}
            </div>

            <div class="flex justify-end">
              <Button 
                variant="ghost" 
                size="icon"
                @click="openEditModal(set)"
                class="text-gray-500 hover:text-primary hover:bg-primary/10 h-8 w-8"
              >
                <Pencil class="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
        
        <div v-else class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-gray-50/70 rounded-lg">
          <ListX class="w-12 h-12 text-muted-foreground/30" />
          <p class="text-base text-muted-foreground text-center">
            Aucune série effectuée pour le moment
          </p>
        </div>
      </div>
      
      <!-- Conseils d'exercice -->
      <div class="bg-white rounded-xl p-6">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Lightbulb class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Conseils d'exécution</h3>
            <p class="text-sm text-muted-foreground">Pour optimiser votre entraînement</p>
          </div>
        </div>
        
        <div class="bg-gray-50/70 rounded-lg p-4">
          <div class="flex items-start gap-3">
            <CheckSquare class="w-5 h-5 text-primary mt-0.5" />
            <p class="text-sm">Maintenez une bonne posture et contrôlez votre mouvement tout au long de l'exercice.</p>
          </div>
          <div class="flex items-start gap-3 mt-3">
            <CheckSquare class="w-5 h-5 text-primary mt-0.5" />
            <p class="text-sm">Respirez correctement : expirez pendant l'effort, inspirez pendant la phase de retour.</p>
          </div>
          <div class="flex items-start gap-3 mt-3">
            <CheckSquare class="w-5 h-5 text-primary mt-0.5" />
            <p class="text-sm">Privilégiez la qualité des répétitions plutôt que la quantité ou le poids.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useWorkoutExercise } from '~/composables/useWorkoutExercise'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { useExerciseSet } from '~/composables/useExerciseSet'
import AdaptSetInput from '~/components/exercises/AdaptSetInput.vue'
import { toast } from 'vue-sonner'
import { Toaster } from '@/components/ui/sonner'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Pencil } from 'lucide-vue-next'

import { 
  Trash2, 
  Dumbbell, 
  Plus, 
  ListOrdered, 
  ListX, 
  Loader2,
  ArrowLeft,
  CheckSquare,
  Lightbulb,
  Trophy
} from 'lucide-vue-next'


definePageMeta({
  layout: 'start-session'
})

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient()
const { getWorkoutExercise } = useWorkoutExercise()
const { getCurrentSession } = usePerformedSession(supabase)
const { exerciseSets, error: exerciseSetError, loading: exerciseSetLoading, addExerciseSet } = useExerciseSet()

const exercise = ref(null)
const loading = ref(true)
const error = ref(null)
const sessionId = ref(null)
const isLeavingPage = ref(false)
const bestSet = ref(null)
// Créer un ref local pour les séries
const localExerciseSets = ref([])

const newSet = ref({
  weight_kg: null,
  reps: null,
  duration_seconds: null,
  distance_meters: null,
  rest_seconds: null,
  rpe: null,
  note: null
})

// Variables pour la modale de repos
const showRestModal = ref(false)
const restTimeRemaining = ref(0)
const restTimer = ref(null)

// Variables pour la modale d'édition
const showEditModal = ref(false)
const editingSet = ref(null)
const updating = ref(false)

// Variables pour la modale de suppression
const showDeleteModal = ref(false)
const deleting = ref(false)

// Format date for display
const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

// Fonction pour empêcher la navigation sans confirmation
const beforeUnloadHandler = (e) => {
  if (localExerciseSets.value?.length > 0 && !isLeavingPage.value) {
    const message = 'Vous avez des séries enregistrées. Êtes-vous sûr de vouloir quitter cette page ? Pensez à terminer votre séance pour sauvegarder vos données.'
    e.returnValue = message
    return message
  }
}

// Intercepteur de navigation pour les routes Vue
const routeLeaveGuard = (to, from, next) => {
  // Autoriser toujours la navigation vers la page principale de la séance
  if (to.path === `/seances/${route.params.id}/start`) {
    isLeavingPage.value = true
    next()
    return
  }
  
  // Demander confirmation uniquement si on quitte l'exercice vers une page autre que start
  if (localExerciseSets.value?.length > 0 && !isLeavingPage.value) {
    if (window.confirm('Vous avez des séries enregistrées. Êtes-vous sûr de vouloir quitter cette page ? Pensez à terminer votre séance pour sauvegarder vos données.')) {
      isLeavingPage.value = true
      next()
    } else {
      next(false)
    }
  } else {
    next()
  }
}

const loadBestSet = async () => {
  try {
    // Vérifier que les données de l'exercice sont disponibles
    if (!exercise.value || !exercise.value.exercise || !exercise.value.exercise.id) {
      console.warn('Impossible de charger le meilleur set: données de l\'exercice non disponibles')
      return
    }
    
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    
    // Récupérer le set avec le poids le plus élevé pour cet exercice
    const { data, error: bestSetError } = await supabase
      .from('exerciseset')
      .select('*')
      .eq('exercise_id', exercise.value.exercise.id)
      .eq('user_id', user.id)
      .order('weight_kg', { ascending: false })
      .order('reps', { ascending: false })
      .limit(1)

    if (bestSetError) throw bestSetError
    bestSet.value = data && data.length > 0 ? data[0] : null
    console.log('Meilleur set chargé:', bestSet.value)
  } catch (e) {
    console.error('Erreur lors du chargement du meilleur set:', e.message)
  }
}

// Fonction pour comparer deux sets et déterminer si le nouveau est meilleur
const isBetterSet = (newSet, currentBest) => {
  if (!currentBest) return true
  if (newSet.weight_kg > currentBest.weight_kg) return true
  if (newSet.weight_kg === currentBest.weight_kg && newSet.reps > currentBest.reps) return true
  return false
}

// Fonction pour formater le temps en minutes:secondes
const formatTime = (seconds) => {
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
}

// Fonction pour formater la durée
const formatDuration = (seconds) => {
  if (!seconds) return ''
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  if (mins > 0) {
    return `${mins}min ${secs}s`
  }
  return `${secs}s`
}

// Fonction pour démarrer le timer de repos
const startRestTimer = (seconds) => {
  restTimeRemaining.value = seconds
  showRestModal.value = true
  
  restTimer.value = setInterval(() => {
    if (restTimeRemaining.value > 0) {
      restTimeRemaining.value--
    } else {
      clearInterval(restTimer.value)
      showRestModal.value = false
      toast.success('Temps de repos terminé !', {
        description: 'Vous pouvez commencer votre prochaine série'
      })
    }
  }, 1000)
}

// Fonction pour annuler le repos
const cancelRest = () => {
  clearInterval(restTimer.value)
  showRestModal.value = false
  restTimeRemaining.value = 0
}

// Fonction pour passer le repos
const skipRest = () => {
  clearInterval(restTimer.value)
  showRestModal.value = false
  restTimeRemaining.value = 0
  toast.info('Temps de repos ignoré')
}

const handleAddSet = async () => {
  try {
    // Créer la donnée de la série à envoyer à la base de données
    const setData = {
      exercise_id: exercise.value.exercise.id,
      weight_kg: newSet.value.weight_kg ? parseFloat(newSet.value.weight_kg) : null,
      reps: newSet.value.reps ? parseInt(newSet.value.reps) : null,
      duration_seconds: newSet.value.duration_seconds ? parseInt(newSet.value.duration_seconds) : null,
      distance_meters: newSet.value.distance_meters ? parseFloat(newSet.value.distance_meters) : null,
      rest_seconds: newSet.value.rest_seconds ? parseInt(newSet.value.rest_seconds) : null,
      rpe: newSet.value.rpe ? parseFloat(newSet.value.rpe) : null,
      note: newSet.value.note || null
    }
    
    // Faire l'appel directement à Supabase pour un meilleur contrôle
    const { data: { user } } = await supabase.auth.getUser()
    
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }
    
    // Ajouter l'utilisateur à setData
    setData.user_id = user.id
    
    // Insérer dans la base de données
    const { data: addedSet, error: insertError } = await supabase
      .from('exerciseset')
      .insert([setData])
      .select()
      .single()
    
    if (insertError) throw insertError
    
    console.log('Série ajoutée avec succès:', addedSet)
    
    // Ajouter la série à localExerciseSets pour une mise à jour immédiate
    localExerciseSets.value = [addedSet, ...localExerciseSets.value]
    
    // Mettre à jour la liste des tempSessionSets dans le localStorage
    if (typeof window !== 'undefined' && addedSet && addedSet.id) {
      const storedSets = localStorage.getItem('tempSessionSets')
      const tempSets = storedSets ? JSON.parse(storedSets) : []
      tempSets.push(addedSet.id)
      localStorage.setItem('tempSessionSets', JSON.stringify(tempSets))
    }
    
    // Vérifier si c'est un meilleur set en utilisant la nouvelle fonction de comparaison
    if (isBetterSet(addedSet, bestSet.value)) {
      bestSet.value = addedSet
      console.log('Nouveau record personnel!')
      
      toast.success('Félicitations ! 🏆', {
        description: `Vous avez battu votre ancien record avec ${addedSet.weight_kg}kg x ${addedSet.reps} répétitions`
      })
    } else {
      toast.success('Série ajoutée avec succès!', {
        description: `${addedSet.weight_kg}kg x ${addedSet.reps} répétitions`
      })
    }
    
    // Préremplir le formulaire avec la dernière série (celle qu'on vient d'ajouter)
    if (addedSet) {
      newSet.value = {
        weight_kg: addedSet.weight_kg,
        reps: addedSet.reps,
        duration_seconds: addedSet.duration_seconds,
        distance_meters: addedSet.distance_meters,
        rest_seconds: addedSet.rest_seconds,
        rpe: addedSet.rpe || null,
        note: addedSet.note || null
      }
    }

    // Démarrer le timer de repos
    startRestTimer(parseInt(newSet.value.restTime))
  } catch (e) {
    error.value = e.message
    console.error('Erreur lors de l\'ajout d\'une série:', e)
    toast.error('Erreur', {
      description: `Impossible d'ajouter la série: ${e.message}`
    })
  }
}

const loadExerciseSets = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    
    // Récupérer la session en cours
    const currentSession = getCurrentSession()
    if (!currentSession) return
    
    // S'assurer que exercise.value existe et contient exercise.id
    if (!exercise.value || !exercise.value.exercise || !exercise.value.exercise.id) {
      console.error('Exercise data is not available yet')
      return
    }
    
    // Charger uniquement les séries de la session en cours
    const { data, error: setsError } = await supabase
      .from('exerciseset')
      .select('*')
      .eq('exercise_id', exercise.value.exercise.id)
      .eq('user_id', user.id)
      .gte('created_at', currentSession.started_at)
      .lte('created_at', currentSession.ended_at || new Date().toISOString())
      .order('created_at', { ascending: false })

    if (setsError) throw setsError
    
    // Mettre à jour directement la référence locale pour déclencher la réactivité
    localExerciseSets.value = data || []
    console.log('Séries chargées:', localExerciseSets.value)
  } catch (e) {
    console.error('Erreur lors du chargement des séries:', e)
    error.value = e.message
  }
}

const loadExercise = async () => {
  try {
    loading.value = true
    error.value = null
    
    // Vérifier si une session est en cours
    const currentSession = getCurrentSession()
    if (!currentSession) {
      isLeavingPage.value = true
      router.push(`/seances/${route.params.id}/train`)
      return
    }

    // Charger les données de l'exercice
    const { data, error: exerciseError } = await getWorkoutExercise(route.params.exerciseId)
    if (exerciseError) throw exerciseError
    
    if (!data) {
      throw new Error("Les données de l'exercice n'ont pas pu être chargées")
    }
    
    exercise.value = data
    console.log('Exercice chargé:', exercise.value)

    // Charger les séries de l'exercice uniquement si l'exercise a été chargé
    if (exercise.value && exercise.value.exercise && exercise.value.exercise.id) {
      await loadExerciseSets()
    
      // Charger le meilleur set (record personnel)
      await loadBestSet()

      // Préremplir le formulaire avec la dernière série
      if (localExerciseSets.value && localExerciseSets.value.length > 0) {
        const lastSet = localExerciseSets.value[0]
        newSet.value = {
          weight_kg: lastSet.weight_kg,
          reps: lastSet.reps,
          duration_seconds: lastSet.duration_seconds,
          distance_meters: lastSet.distance_meters,
          rest_seconds: lastSet.rest_seconds,
          rpe: lastSet.rpe || null,
          note: lastSet.note || null
        }
      }
    }
  } catch (e) {
    console.error('Erreur lors du chargement de l\'exercice:', e)
    error.value = e.message
  } finally {
    loading.value = false
  }
}

const deleteSet = async (setId) => {
  try {
    // Supprimer localement la série de l'interface avant même la requête serveur pour une réactivité immédiate
    localExerciseSets.value = localExerciseSets.value.filter(set => set.id !== setId)
    
    // Supprimer la série de la base de données
    const { error: deleteError } = await supabase
      .from('exerciseset')
      .delete()
      .eq('id', setId)

    if (deleteError) throw deleteError

    console.log('Série supprimée avec succès')
    toast.info('Série supprimée', {
      description: 'La série a été supprimée avec succès'
    })
    
    // Mettre à jour la liste des tempSessionSets dans le localStorage
    if (typeof window !== 'undefined') {
      const storedSets = localStorage.getItem('tempSessionSets')
      if (storedSets) {
        const tempSets = JSON.parse(storedSets)
        const updatedSets = tempSets.filter(id => id !== setId)
        localStorage.setItem('tempSessionSets', JSON.stringify(updatedSets))
      }
    }
    
    // Recharger le meilleur set si nécessaire
    if (bestSet.value && bestSet.value.id === setId) {
      await loadBestSet()
    }
  } catch (e) {
    error.value = e.message
    console.error('Erreur lors de la suppression d\'une série:', e)
    toast.error('Erreur', {
      description: `Impossible de supprimer la série: ${e.message}`
    })
    // En cas d'erreur, recharger les séries pour rétablir l'état correct
    await loadExerciseSets()
  }
}

// Fonction pour gérer le retour à la page de démarrage
const handleReturn = () => {
  isLeavingPage.value = true
  // Utiliser router.push au lieu de navigateTo pour éviter les problèmes de navigation
  router.push(`/seances/${route.params.id}/start`)
}

// Fonction pour ouvrir la modale d'édition
const openEditModal = (set) => {
  editingSet.value = { ...set }
  showEditModal.value = true
}

// Fonction pour mettre à jour une série
const handleUpdateSet = async () => {
  try {
    updating.value = true
    
    const { data: updatedSet, error: updateError } = await supabase
      .from('exerciseset')
      .update({
        weight_kg: parseFloat(editingSet.value.weight_kg),
        reps: parseInt(editingSet.value.reps),
        rest_seconds: parseInt(editingSet.value.rest_seconds),
        rpe: editingSet.value.rpe ? parseFloat(editingSet.value.rpe) : null,
        note: editingSet.value.note || null
      })
      .eq('id', editingSet.value.id)
      .select()
      .single()

    if (updateError) throw updateError

    // Mettre à jour la liste locale
    const index = localExerciseSets.value.findIndex(set => set.id === editingSet.value.id)
    if (index !== -1) {
      localExerciseSets.value[index] = updatedSet
    }

    // Vérifier si c'est un nouveau record
    if (isBetterSet(updatedSet, bestSet.value)) {
      bestSet.value = updatedSet
      toast.success('Félicitations ! 🏆', {
        description: `Vous avez battu votre ancien record avec ${updatedSet.weight_kg}kg x ${updatedSet.reps} répétitions`
      })
    } else {
      toast.success('Série mise à jour avec succès!')
    }

    showEditModal.value = false
  } catch (e) {
    console.error('Erreur lors de la mise à jour de la série:', e)
    toast.error('Erreur', {
      description: `Impossible de mettre à jour la série: ${e.message}`
    })
  } finally {
    updating.value = false
  }
}

// Fonction pour confirmer la suppression
const confirmDelete = () => {
  showDeleteModal.value = true
}

// Nouvelle fonction pour gérer la suppression
const handleDelete = async () => {
  try {
    deleting.value = true
    
    const { error: deleteError } = await supabase
      .from('exerciseset')
      .delete()
      .eq('id', editingSet.value.id)

    if (deleteError) throw deleteError

    // Mettre à jour la liste locale
    localExerciseSets.value = localExerciseSets.value.filter(set => set.id !== editingSet.value.id)
    
    // Mettre à jour la liste des tempSessionSets dans le localStorage
    if (typeof window !== 'undefined') {
      const storedSets = localStorage.getItem('tempSessionSets')
      if (storedSets) {
        const tempSets = JSON.parse(storedSets)
        const updatedSets = tempSets.filter(id => id !== editingSet.value.id)
        localStorage.setItem('tempSessionSets', JSON.stringify(updatedSets))
      }
    }

    // Recharger le meilleur set si nécessaire
    if (bestSet.value && bestSet.value.id === editingSet.value.id) {
      await loadBestSet()
    }

    // Fermer les deux modales
    showDeleteModal.value = false
    showEditModal.value = false
    
    toast.success('Série supprimée avec succès')
  } catch (e) {
    console.error('Erreur lors de la suppression de la série:', e)
    toast.error('Erreur', {
      description: `Impossible de supprimer la série: ${e.message}`
    })
  } finally {
    deleting.value = false
  }
}

onMounted(() => {
  loadExercise()
  
  // Ajouter l'écouteur d'événement pour la fermeture du navigateur/onglet
  if (typeof window !== 'undefined') {
    window.addEventListener('beforeunload', beforeUnloadHandler)
    
    // Configurer le garde de route
    const unbindRoute = router.beforeEach(routeLeaveGuard)
    
    // Stocker la fonction pour désactiver l'écouteur
    onBeforeUnmount(() => {
      window.removeEventListener('beforeunload', beforeUnloadHandler)
      // Supprimer le garde de route
      unbindRoute()
    })
  }
})

// Watch pour déboguer les changements dans localExerciseSets
watch(localExerciseSets, (newSets, oldSets) => {
  console.log('localExerciseSets a changé!', 
    'Ancienne longueur:', oldSets.length, 
    'Nouvelle longueur:', newSets.length, 
    'Contenu:', newSets
  )
}, { deep: true })

// Nettoyer le timer lors du démontage du composant
onBeforeUnmount(() => {
  if (restTimer.value) {
    clearInterval(restTimer.value)
  }
})
</script>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.5s ease-out forwards;
  opacity: 0;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style> 
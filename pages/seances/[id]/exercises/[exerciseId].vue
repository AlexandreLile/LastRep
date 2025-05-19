<template>
  <div class="space-y-6">
    <Toaster />
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
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div class="space-y-2">
              <Label class="font-medium">Poids (kg)</Label>
              <Input 
                v-model="newSet.weight" 
                type="number" 
                step="0.5"
                class="focus:border-primary focus:ring-primary"
                required
              />
            </div>
            <div class="space-y-2">
              <Label class="font-medium">Répétitions</Label>
              <Input 
                v-model="newSet.reps" 
                type="number"
                class="focus:border-primary focus:ring-primary"
                required
              />
            </div>
            <div class="space-y-2">
              <Label class="font-medium">Temps de repos (secondes)</Label>
              <Input 
                v-model="newSet.restTime" 
                type="number"
                class="focus:border-primary focus:ring-primary"
                required
              />
            </div>
            <div class="space-y-2">
              <Label class="font-medium">RPE (1-10)</Label>
              <Input 
                v-model="newSet.rpe" 
                type="number" 
                min="1" 
                max="10"
                class="focus:border-primary focus:ring-primary"
              />
              <div class="text-xs text-muted-foreground">
                Rate of Perceived Exertion - Intensité ressentie
              </div>
            </div>
          </div>
          <div class="space-y-2">
            <Label class="font-medium">Note</Label>
            <Textarea 
              v-model="newSet.note" 
              rows="2"
              placeholder="Ajouter une note (optionnel)"
              class="focus:border-primary focus:ring-primary"
            />
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
              <div class="space-y-1">
                <span class="text-xs text-muted-foreground uppercase">Poids</span>
                <p class="font-medium text-primary">{{ set.weight_kg }} kg</p>
              </div>
              <div class="space-y-1">
                <span class="text-xs text-muted-foreground uppercase">Répétitions</span>
                <p class="font-medium">{{ set.reps }}</p>
              </div>
              <div class="space-y-1">
                <span class="text-xs text-muted-foreground uppercase">Repos</span>
                <p class="font-medium">{{ set.rest_seconds }}s</p>
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
                @click="deleteSet(set.id)"
                class="text-red-500 hover:text-red-600 hover:bg-red-50 h-8 w-8"
              >
                <Trash2 class="h-4 w-4" />
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
import { toast } from 'vue-sonner'
import { Toaster } from '@/components/ui/sonner'

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
  weight: '',
  reps: '',
  restTime: '',
  rpe: '',
  note: ''
})

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

const handleAddSet = async () => {
  try {
    // Créer la donnée de la série à envoyer à la base de données
    const setData = {
      exercise_id: exercise.value.exercise.id,
      weight_kg: parseFloat(newSet.value.weight),
      reps: parseInt(newSet.value.reps),
      rest_seconds: parseInt(newSet.value.restTime),
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
        weight: addedSet.weight_kg,
        reps: addedSet.reps,
        restTime: addedSet.rest_seconds,
        rpe: addedSet.rpe || '',
        note: addedSet.note || ''
      }
    }
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
          weight: lastSet.weight_kg,
          reps: lastSet.reps,
          restTime: lastSet.rest_seconds,
          rpe: lastSet.rpe || '',
          note: lastSet.note || ''
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
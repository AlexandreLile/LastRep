<template>
  <div class="space-y-6">
    <!-- Bouton retour fixe en haut à gauche -->
    <Button 
      variant="default" 
      size="sm" 
      @click="handleReturn" 
      class="fixed top-4 left-4 z-50 flex items-center gap-2 shadow-lg bg-primary hover:bg-primary/90 backdrop-blur-sm"
    >
      <ArrowLeft class="w-4 h-4" />
      Retour
    </Button>
    
    <Toaster />
    <Dialog :open="showRestModal" @update:open="handleRestModalChange">
      <DialogContent class="sm:max-w-md" @pointer-down-outside.prevent @escape-key-down.prevent>
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
          <!-- Champs adaptatifs selon le type d'exercice -->
          <div v-if="exercise && exercise.exercise && exercise.exercise.measurement_type === 'time'" class="space-y-4">
            <div class="space-y-2">
              <Label class="font-medium">Durée (secondes)</Label>
              <Input 
                v-model="editingSet.duration_seconds" 
                type="number"
                class="focus:border-primary focus:ring-primary w-full"
                required
              />
            </div>
          </div>
          <div v-else-if="exercise && exercise.exercise && exercise.exercise.measurement_type === 'time_reps'" class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label class="font-medium">Durée (secondes)</Label>
              <Input 
                v-model="editingSet.duration_seconds" 
                type="number"
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
          </div>
          <div v-else-if="exercise && exercise.exercise && exercise.exercise.measurement_type === 'reps'" class="space-y-4">
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
              <Label class="font-medium">Poids (optionnel)</Label>
              <Input 
                v-model="editingSet.weight_kg" 
                type="number" 
                step="0.5"
                class="focus:border-primary focus:ring-primary w-full"
              />
            </div>
          </div>
          <div v-else class="grid grid-cols-1 sm:grid-cols-2 gap-4">
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
          </div>
          
          <!-- Champs communs -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
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

    <Dialog :open="showMissingFieldsModal" @update:open="showMissingFieldsModal = $event">
      <DialogContent class="sm:max-w-md w-[95vw]">
        <DialogHeader>
          <DialogTitle>Champs manquants</DialogTitle>
          <DialogDescription>
            <span v-if="missingFields.length > 0">
              Attention, vous n'avez pas rempli certains champs obligatoires :
            </span>
            <span v-else-if="missingOptionalFields.length > 0">
              Attention, vous n'avez pas rempli certains champs optionnels :
            </span>
          </DialogDescription>
        </DialogHeader>
        <div class="py-4">
          <!-- Champs obligatoires manquants -->
          <div v-if="missingFields.length > 0">
            <ul class="list-disc list-inside space-y-2 text-sm text-muted-foreground">
              <li v-for="field in missingFields" :key="field" class="text-red-600 font-medium">
                {{ field }}
              </li>
            </ul>
          </div>
          
          <!-- Champs optionnels manquants -->
          <div v-if="missingOptionalFields.length > 0 && missingFields.length === 0">
            <ul class="list-disc list-inside space-y-2 text-sm text-muted-foreground">
              <li v-for="field in missingOptionalFields" :key="field" class="text-foreground">
                {{ field }}
              </li>
            </ul>
          </div>
        </div>
        <div class="flex flex-col sm:flex-row justify-end gap-3 mt-4">
          <Button 
            variant="default" 
            @click="fillMissingFields"
            class="w-full sm:w-auto"
          >
            Remplir
          </Button>
          <!-- Afficher "Enregistrer quand même" seulement si ce sont des champs optionnels qui manquent -->
          <Button 
            v-if="missingFields.length === 0 && missingOptionalFields.length > 0"
            variant="secondary" 
            @click="confirmAddSet"
            class="w-full sm:w-auto"
          >
            Enregistrer quand même
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
    <div v-else class="space-y-6 mt-16 md:mt-0">
      <!-- En-tête de l'exercice -->
      <div class="bg-card rounded-xl p-6">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex items-start gap-4">
            <div class="p-3 rounded-full bg-primary/10 flex-shrink-0">
              <Dumbbell class="h-6 w-6 text-primary" />
            </div>
            <div>
              <h2 class="text-2xl font-bold text-foreground">{{ exercise.exercise?.name }}</h2>
              <div class="flex items-center mt-1.5">
                <span class="text-xs font-medium bg-muted text-foreground px-2 py-1 rounded-full">{{ exercise.exercise?.primary_muscle }}</span>
              </div>
            </div>
          </div>
          
          <div class="flex items-center gap-3">
            <div class="text-sm text-muted-foreground bg-muted/70 px-3 py-1.5 rounded-md">
              <span v-if="localExerciseSets.length === 0">Aucune série</span>
              <span v-else>{{ localExerciseSets.length }} série{{ localExerciseSets.length > 1 ? 's' : '' }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Record personnel -->
      <div class="bg-card rounded-xl p-6 border-2 border-primary/20">
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
          <!-- Affichage pour exercices en temps (isométrie) -->
          <div v-if="exercise?.exercise?.measurement_type === 'time' && bestSet.isTimeExercise" class="grid grid-cols-2 sm:grid-cols-3 gap-4">
            <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Temps max</span>
              <p class="font-bold text-lg text-primary">{{ formatDuration(bestSet.maxTime) }}</p>
            </div>
            <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Séries max dans une séance</span>
              <p class="font-bold text-lg">{{ bestSet.maxSetsInSession }}</p>
            </div>
            <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Date</span>
              <p class="text-sm">{{ formatDate(bestSet.created_at) }}</p>
            </div>
          </div>
          
          <!-- Affichage pour exercices en répétitions -->
          <div v-else-if="exercise?.exercise?.measurement_type === 'reps' && bestSet.isRepsExercise" class="grid grid-cols-2 sm:grid-cols-3 gap-4">
            <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Max reps en une série</span>
              <p class="font-bold text-lg text-primary">{{ bestSet.maxReps }}</p>
            </div>
            <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Meilleur total dans une séance</span>
              <p class="font-bold text-lg">{{ bestSet.maxTotalRepsInSession }} reps</p>
            </div>
            <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Date</span>
              <p class="text-sm">{{ formatDate(bestSet.created_at) }}</p>
            </div>
          </div>
          
          <!-- Affichage pour autres types d'exercices -->
          <div v-else class="grid grid-cols-2 sm:grid-cols-3 gap-4">
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
        
        <div v-else class="flex flex-col items-center justify-center py-6 px-4 space-y-2 bg-muted/70 rounded-lg">
          <Trophy class="w-8 h-8 text-muted-foreground/30" />
          <p class="text-sm text-muted-foreground text-center">
            Pas encore de record sur cet exercice
          </p>
        </div>
      </div>

      <!-- Formulaire d'ajout de série -->
      <div ref="formContainer" class="bg-card rounded-xl p-6" :class="{ 'ring-2 ring-red-500': hasFormErrors }">
        <div class="flex items-center gap-3 mb-6">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Plus class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Ajouter une série</h3>
            <p class="text-sm text-muted-foreground">Renseignez les détails de votre série</p>
          </div>
        </div>
        
        <div v-if="hasFormErrors" class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
          <p class="text-sm text-red-700 font-medium">⚠️ Veuillez corriger les champs suivants :</p>
          <ul class="mt-2 list-disc list-inside text-sm text-red-600">
            <li v-for="field in formErrors" :key="field">{{ field }}</li>
          </ul>
        </div>

        <form @submit.prevent="handleAddSet" class="space-y-6">
          <AdaptSetInput
            v-if="exercise && exercise.exercise && exercise.exercise.measurement_type"
            :exercise="exercise.exercise"
            v-model="newSet"
            :field-errors="formFieldErrors"
          />
          <div v-else-if="exercise && exercise.exercise && !exercise.exercise.measurement_type" class="text-sm text-muted-foreground p-4 bg-primary/10 border border-primary/20 rounded-lg">
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
      <div class="bg-card rounded-xl p-6">
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
            class="bg-muted/70 rounded-lg p-4 space-y-4 transition-all duration-300 hover:bg-muted"
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
            
            <div v-if="set.note" class="p-2 bg-muted/70 rounded text-sm text-muted-foreground italic">
              {{ set.note }}
            </div>

            <div class="flex justify-end">
              <Button 
                variant="ghost" 
                size="icon"
                @click="openEditModal(set)"
                class="text-muted-foreground hover:text-primary hover:bg-primary/10 h-8 w-8"
              >
                <Pencil class="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
        
        <div v-else class="flex flex-col items-center justify-center py-12 px-4 space-y-4 bg-muted/70 rounded-lg">
          <ListX class="w-12 h-12 text-muted-foreground/30" />
          <p class="text-base text-muted-foreground text-center">
            Aucune série effectuée pour le moment
          </p>
        </div>
      </div>
      
      <!-- Conseils d'exercice -->
      <div class="bg-card rounded-xl p-6">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Lightbulb class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Conseils d'exécution</h3>
            <p class="text-sm text-muted-foreground">Pour optimiser votre entraînement</p>
          </div>
        </div>
        
        <div class="bg-muted/70 rounded-lg p-4">
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
const restTimerStartTime = ref(null) // Timestamp de début du timer
const restTimerDuration = ref(0) // Durée totale du timer en secondes

// Variables pour la modale d'édition
const showEditModal = ref(false)
const editingSet = ref(null)
const updating = ref(false)

// Variables pour la modale de suppression
const showDeleteModal = ref(false)
const deleting = ref(false)

// Variables pour la modale de champs manquants
const showMissingFieldsModal = ref(false)
const missingFields = ref([])
const missingOptionalFields = ref([])
const pendingSetData = ref(null)

// Variables pour la gestion des erreurs de formulaire
const formContainer = ref(null)
const hasFormErrors = ref(false)
const formErrors = ref([])
const formFieldErrors = ref({})

// Format date for display
const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

// Fonction pour extraire les champs manquants depuis un message d'erreur
const extractMissingFields = (errorMessage) => {
  if (!errorMessage) return { fields: [], fieldErrors: {} }
  
  const errorLower = errorMessage.toLowerCase()
  const fields = []
  const fieldErrors = {}
  
  // Erreurs de validation des exercices
  if (errorLower.includes('time requires duration_seconds') || (errorLower.includes('null value') && errorLower.includes('duration_seconds'))) {
    fields.push('Durée (secondes)')
    fieldErrors.duration_seconds = true
  }
  if (errorLower.includes('weight_reps requires reps') || errorLower.includes('reps type requires reps') || (errorLower.includes('null value') && errorLower.includes('reps'))) {
    fields.push('Répétitions')
    fieldErrors.reps = true
  }
  if (errorLower.includes('time_reps requires reps')) {
    fields.push('Répétitions')
    fieldErrors.reps = true
  }
  if (errorLower.includes('time_reps requires duration_seconds')) {
    if (!fields.includes('Durée (secondes)')) {
      fields.push('Durée (secondes)')
      fieldErrors.duration_seconds = true
    }
  }
  if (errorLower.includes('distance requires distance_meters')) {
    fields.push('Distance (mètres)')
    fieldErrors.distance_meters = true
  }
  if (errorLower.includes('weight_only requires weight_kg') || (errorLower.includes('null value') && errorLower.includes('weight_kg'))) {
    fields.push('Poids (kg)')
    fieldErrors.weight_kg = true
  }
  if (errorLower.includes('time_distance requires both duration_seconds and distance_meters')) {
    fields.push('Durée (secondes)')
    fields.push('Distance (mètres)')
    fieldErrors.duration_seconds = true
    fieldErrors.distance_meters = true
  }
  
  return { fields, fieldErrors }
}

// Fonction pour traduire les erreurs techniques en messages user-friendly
const getUserFriendlyError = (errorMessage) => {
  if (!errorMessage) return 'Une erreur est survenue'
  
  const errorLower = errorMessage.toLowerCase()
  
  // Erreurs de validation des exercices
  if (errorLower.includes('time requires duration_seconds')) {
    return 'Veuillez renseigner la durée de l\'exercice (en secondes)'
  }
  if (errorLower.includes('weight_reps requires reps')) {
    return 'Veuillez renseigner le nombre de répétitions'
  }
  if (errorLower.includes('reps type requires reps')) {
    return 'Veuillez renseigner le nombre de répétitions'
  }
  if (errorLower.includes('distance requires distance_meters')) {
    return 'Veuillez renseigner la distance parcourue (en mètres)'
  }
  if (errorLower.includes('weight_only requires weight_kg')) {
    return 'Veuillez renseigner le poids soulevé (en kg)'
  }
  if (errorLower.includes('time_distance requires both duration_seconds and distance_meters')) {
    return 'Veuillez renseigner la durée et la distance'
  }
  if (errorLower.includes('time_reps requires duration_seconds')) {
    return 'Veuillez renseigner la durée de l\'exercice (en secondes)'
  }
  if (errorLower.includes('time_reps requires reps')) {
    return 'Veuillez renseigner le nombre de répétitions'
  }
  
  // Erreurs de contrainte de base de données
  if (errorLower.includes('null value') && errorLower.includes('reps')) {
    return 'Le nombre de répétitions est requis'
  }
  if (errorLower.includes('null value') && errorLower.includes('duration_seconds')) {
    return 'La durée de l\'exercice est requise'
  }
  if (errorLower.includes('null value') && errorLower.includes('weight_kg')) {
    return 'Le poids est requis'
  }
  
  // Erreurs d'authentification
  if (errorLower.includes('non authentifié') || errorLower.includes('not authenticated')) {
    return 'Vous devez être connecté pour effectuer cette action'
  }
  
  // Erreurs de permission
  if (errorLower.includes('permission') || errorLower.includes('row-level security')) {
    return 'Vous n\'avez pas la permission d\'effectuer cette action'
  }
  
  // Erreurs de connexion
  if (errorLower.includes('network') || errorLower.includes('fetch')) {
    return 'Erreur de connexion. Vérifiez votre connexion internet'
  }
  
  // Par défaut, retourner le message d'erreur original si on ne le reconnaît pas
  return errorMessage
}

// Fonction pour scroller vers le formulaire et mettre en évidence les erreurs
const scrollToFormAndHighlightErrors = (errorMessage) => {
  const { fields, fieldErrors } = extractMissingFields(errorMessage)
  
  if (fields.length > 0) {
    hasFormErrors.value = true
    formErrors.value = fields
    formFieldErrors.value = fieldErrors
    
    // Scroller vers le formulaire avec un petit délai pour s'assurer que le DOM est mis à jour
    setTimeout(() => {
      if (formContainer.value) {
        formContainer.value.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }
    }, 100)
  } else {
    hasFormErrors.value = false
    formErrors.value = []
    formFieldErrors.value = {}
  }
}

// Fonction pour réinitialiser les erreurs du formulaire
const resetFormErrors = () => {
  hasFormErrors.value = false
  formErrors.value = []
  formFieldErrors.value = {}
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
    
    const measurementType = exercise.value.exercise.measurement_type || 'weight_reps'
    
    // Pour les exercices en temps (isométrie), charger le meilleur temps et le nombre max de séries dans une séance
    if (measurementType === 'time') {
      // Récupérer toutes les séries de cet exercice
      const { data: allSets, error: allSetsError } = await supabase
        .from('exerciseset')
        .select('duration_seconds, created_at')
        .eq('exercise_id', exercise.value.exercise.id)
        .eq('user_id', user.id)
        .not('duration_seconds', 'is', null)
        .order('duration_seconds', { ascending: false })

      if (allSetsError) throw allSetsError
      
      if (allSets && allSets.length > 0) {
        // Trouver le meilleur temps (max duration_seconds)
        const bestTimeSet = allSets[0] // Déjà trié par duration_seconds desc
        
        // Grouper par date pour trouver le nombre max de séries dans une séance
        const setsByDate = {}
        allSets.forEach(set => {
          const date = new Date(set.created_at).toLocaleDateString('fr-FR')
          if (!setsByDate[date]) {
            setsByDate[date] = 0
          }
          setsByDate[date]++
        })
        
        const maxSetsInSession = Math.max(...Object.values(setsByDate))
        const dateWithMaxSets = Object.keys(setsByDate).find(date => setsByDate[date] === maxSetsInSession)
        
        bestSet.value = {
          ...bestTimeSet,
          maxTime: bestTimeSet.duration_seconds,
          maxSetsInSession: maxSetsInSession,
          dateWithMaxSets: dateWithMaxSets,
          isTimeExercise: true
        }
      } else {
        bestSet.value = null
      }
    } else if (measurementType === 'reps') {
      // Pour les exercices en répétitions, charger le max reps en une série et le meilleur total de reps dans une séance
      const { data: allSets, error: allSetsError } = await supabase
        .from('exerciseset')
        .select('reps, created_at')
        .eq('exercise_id', exercise.value.exercise.id)
        .eq('user_id', user.id)
        .not('reps', 'is', null)
        .order('reps', { ascending: false })

      if (allSetsError) throw allSetsError
      
      if (allSets && allSets.length > 0) {
        // Trouver le max reps en une série
        const bestRepsSet = allSets[0] // Déjà trié par reps desc
        
        // Grouper par date pour trouver le meilleur total de répétitions dans une séance
        const repsByDate = {}
        allSets.forEach(set => {
          const date = new Date(set.created_at).toLocaleDateString('fr-FR')
          if (!repsByDate[date]) {
            repsByDate[date] = 0
          }
          repsByDate[date] += set.reps || 0
        })
        
        const maxTotalRepsInSession = Math.max(...Object.values(repsByDate))
        const dateWithMaxReps = Object.keys(repsByDate).find(date => repsByDate[date] === maxTotalRepsInSession)
        
        bestSet.value = {
          ...bestRepsSet,
          maxReps: bestRepsSet.reps,
          maxTotalRepsInSession: maxTotalRepsInSession,
          dateWithMaxReps: dateWithMaxReps,
          isRepsExercise: true
        }
      } else {
        bestSet.value = null
      }
    } else {
      // Pour les autres types d'exercices, logique classique
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
    }
    
    console.log('Meilleur set chargé:', bestSet.value)
  } catch (e) {
    console.error('Erreur lors du chargement du meilleur set:', e.message)
  }
}

// Fonction pour comparer deux sets et déterminer si le nouveau est meilleur
const isBetterSet = (newSet, currentBest) => {
  if (!currentBest) return true
  
  const measurementType = exercise.value?.exercise?.measurement_type || 'weight_reps'
  
  // Pour les exercices en temps, comparer le temps
  if (measurementType === 'time') {
    const newTime = newSet.duration_seconds || 0
    const bestTime = currentBest.isTimeExercise ? currentBest.maxTime : (currentBest.duration_seconds || 0)
    return newTime > bestTime
  }
  
  // Pour les exercices en répétitions, comparer les reps
  if (measurementType === 'reps') {
    const newReps = newSet.reps || 0
    const bestReps = currentBest.isRepsExercise ? currentBest.maxReps : (currentBest.reps || 0)
    return newReps > bestReps
  }
  
  // Pour les autres types, logique classique
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
  // Nettoyer le timer existant s'il y en a un
  if (restTimer.value) {
    clearInterval(restTimer.value)
    restTimer.value = null
  }
  
  // Stocker le timestamp de début et la durée totale
  restTimerStartTime.value = Date.now()
  restTimerDuration.value = seconds
  restTimeRemaining.value = seconds
  showRestModal.value = true
  
  // Fonction pour mettre à jour le temps restant basé sur le temps réel écoulé
  const updateRestTime = () => {
    if (!restTimerStartTime.value) return
    
    const elapsed = Math.floor((Date.now() - restTimerStartTime.value) / 1000)
    const remaining = Math.max(0, restTimerDuration.value - elapsed)
    
    restTimeRemaining.value = remaining
    
    if (remaining <= 0) {
      clearInterval(restTimer.value)
      restTimer.value = null
      restTimerStartTime.value = null
      restTimerDuration.value = 0
      showRestModal.value = false
      toast.success('Temps de repos terminé !', {
        description: 'Vous pouvez commencer votre prochaine série'
      })
    }
  }
  
  // Mettre à jour immédiatement
  updateRestTime()
  
  // Mettre à jour toutes les secondes
  restTimer.value = setInterval(updateRestTime, 1000)
}

// Fonction pour passer le repos
const skipRest = () => {
  if (restTimer.value) {
    clearInterval(restTimer.value)
    restTimer.value = null
  }
  restTimerStartTime.value = null
  restTimerDuration.value = 0
  showRestModal.value = false
  restTimeRemaining.value = 0
  toast.info('Temps de repos ignoré')
}

// Fonction pour gérer les changements de la modale de repos
const handleRestModalChange = (isOpen) => {
  showRestModal.value = isOpen
  // Le watcher sur showRestModal s'occupera du nettoyage du timer
}

// Fonction pour vérifier les champs manquants
const checkMissingFields = () => {
  const required = [] // Champs obligatoires
  const optional = [] // Champs optionnels
  
  const measurementType = exercise.value?.exercise?.measurement_type || 'weight_reps'
  
  // Vérifier selon le type d'exercice - CHAMPS OBLIGATOIRES
  if (measurementType === 'weight_reps' || !measurementType) {
    if (!newSet.value.weight_kg || parseFloat(newSet.value.weight_kg) <= 0) {
      required.push('Poids')
    }
    if (!newSet.value.reps || parseInt(newSet.value.reps) <= 0) {
      required.push('Répétitions')
    }
  } else if (measurementType === 'reps') {
    if (!newSet.value.reps || parseInt(newSet.value.reps) <= 0) {
      required.push('Répétitions')
    }
  } else if (measurementType === 'time') {
    if (!newSet.value.duration_seconds || parseInt(newSet.value.duration_seconds) <= 0) {
      required.push('Durée')
    }
  } else if (measurementType === 'time_reps') {
    if (!newSet.value.duration_seconds || parseInt(newSet.value.duration_seconds) <= 0) {
      required.push('Durée')
    }
    if (!newSet.value.reps || parseInt(newSet.value.reps) <= 0) {
      required.push('Répétitions')
    }
  } else if (measurementType === 'time_distance') {
    if (!newSet.value.duration_seconds || parseInt(newSet.value.duration_seconds) <= 0) {
      required.push('Durée')
    }
    if (!newSet.value.distance_meters || parseFloat(newSet.value.distance_meters) <= 0) {
      required.push('Distance')
    }
  } else if (measurementType === 'distance') {
    if (!newSet.value.distance_meters || parseFloat(newSet.value.distance_meters) <= 0) {
      required.push('Distance')
    }
  } else if (measurementType === 'weight_only') {
    if (!newSet.value.weight_kg || parseFloat(newSet.value.weight_kg) <= 0) {
      required.push('Poids')
    }
  }
  
  // Vérifier les champs optionnels (temps de repos)
  // Le temps de repos a une valeur par défaut de 0, mais on informe l'utilisateur s'il n'est pas rempli
  if (!newSet.value.rest_seconds || parseInt(newSet.value.rest_seconds) <= 0) {
    optional.push('Temps de repos')
  }
  
  return { required, optional }
}

// Fonction pour enregistrer réellement la série
const confirmAddSet = async () => {
  showMissingFieldsModal.value = false
  await actuallyAddSet()
}

// Fonction pour fermer la modale et scroller vers le formulaire
const fillMissingFields = () => {
  showMissingFieldsModal.value = false
  
  // Mettre en évidence UNIQUEMENT les champs obligatoires manquants dans le formulaire
  const { required, optional } = checkMissingFields()
  
  // Créer un objet d'erreurs pour mettre en évidence les champs obligatoires uniquement
  const fieldErrors = {}
  
  if (required.includes('Poids')) fieldErrors.weight_kg = true
  if (required.includes('Répétitions')) fieldErrors.reps = true
  if (required.includes('Durée')) fieldErrors.duration_seconds = true
  if (required.includes('Distance')) fieldErrors.distance_meters = true
  
  // Ne mettre en évidence que les champs obligatoires (pas les optionnels)
  hasFormErrors.value = required.length > 0
  formErrors.value = required // Seulement les champs obligatoires
  formFieldErrors.value = fieldErrors
  
  // Scroller vers le formulaire
  setTimeout(() => {
    if (formContainer.value) {
      formContainer.value.scrollIntoView({ behavior: 'smooth', block: 'center' })
    }
  }, 100)
}

// Fonction qui fait réellement l'enregistrement
const actuallyAddSet = async () => {
  try {
    const measurementType = exercise.value?.exercise?.measurement_type || 'weight_reps'
    
    const setData = pendingSetData.value || {
      exercise_id: exercise.value.exercise.id,
      weight_kg: newSet.value.weight_kg ? parseFloat(newSet.value.weight_kg) : 0, // Valeur par défaut 0 si non rempli
      reps: newSet.value.reps ? parseInt(newSet.value.reps) : (measurementType === 'weight_reps' || measurementType === 'reps' || measurementType === 'time_reps' ? 1 : 0), // Valeur par défaut 1 pour les types qui nécessitent reps, 0 pour time
      duration_seconds: newSet.value.duration_seconds ? parseInt(newSet.value.duration_seconds) : null,
      distance_meters: newSet.value.distance_meters ? parseFloat(newSet.value.distance_meters) : null,
      rest_seconds: newSet.value.rest_seconds ? parseInt(newSet.value.rest_seconds) : 0, // Valeur par défaut 0 si non rempli
      rpe: newSet.value.rpe ? parseFloat(newSet.value.rpe) : null,
      note: newSet.value.note || null
    }
    
    // S'assurer que rest_seconds n'est jamais null (même si pendingSetData était défini)
    if (setData.rest_seconds === null || setData.rest_seconds === undefined) {
      setData.rest_seconds = 0
    }
    
    // S'assurer que weight_kg n'est jamais null (même si pendingSetData était défini)
    if (setData.weight_kg === null || setData.weight_kg === undefined) {
      setData.weight_kg = 0
    }
    
    // S'assurer que reps n'est jamais null (même si pendingSetData était défini)
    // Pour les exercices time, on met 0 au lieu de null
    if (setData.reps === null || setData.reps === undefined) {
      const requiresReps = ['weight_reps', 'reps', 'time_reps'].includes(measurementType)
      setData.reps = requiresReps ? 1 : 0
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
      // Pour les exercices en temps et en répétitions, recharger les données pour avoir les stats complètes
      if (exercise.value.exercise.measurement_type === 'time' || exercise.value.exercise.measurement_type === 'reps') {
        await loadBestSet()
      } else {
        bestSet.value = addedSet
      }
      console.log('Nouveau record personnel!')
      
      // Message adaptatif selon le type d'exercice
      let description = ''
      if (exercise.value.exercise.measurement_type === 'weight_reps' || !exercise.value.exercise.measurement_type) {
        description = `Vous avez battu votre ancien record avec ${addedSet.weight_kg || 0}kg x ${addedSet.reps || 0} répétitions`
      } else if (exercise.value.exercise.measurement_type === 'reps') {
        const weightText = addedSet.weight_kg && parseFloat(addedSet.weight_kg) > 0 ? ` (lesté +${addedSet.weight_kg}kg)` : ''
        description = `Vous avez battu votre ancien record avec ${addedSet.reps || 0} répétitions${weightText}`
      } else if (exercise.value.exercise.measurement_type === 'time') {
        description = `Vous avez battu votre ancien record avec ${formatDuration(addedSet.duration_seconds || 0)}`
      } else if (exercise.value.exercise.measurement_type === 'time_distance') {
        description = `Vous avez battu votre ancien record avec ${formatDuration(addedSet.duration_seconds || 0)} sur ${((addedSet.distance_meters || 0) / 1000).toFixed(2)} km`
      } else {
        description = 'Nouveau record personnel !'
      }
      
      toast.success('Félicitations ! 🏆', { description })
    } else {
      // Message adaptatif selon le type d'exercice
      let description = ''
      if (exercise.value.exercise.measurement_type === 'weight_reps' || !exercise.value.exercise.measurement_type) {
        description = `${addedSet.weight_kg || 0}kg x ${addedSet.reps || 0} répétitions`
      } else if (exercise.value.exercise.measurement_type === 'reps') {
        const weightText = addedSet.weight_kg && parseFloat(addedSet.weight_kg) > 0 ? ` (lesté +${addedSet.weight_kg}kg)` : ''
        description = `${addedSet.reps || 0} répétitions${weightText}`
      } else if (exercise.value.exercise.measurement_type === 'time') {
        description = `${formatDuration(addedSet.duration_seconds || 0)}`
      } else if (exercise.value.exercise.measurement_type === 'time_distance') {
        description = `${formatDuration(addedSet.duration_seconds || 0)} sur ${((addedSet.distance_meters || 0) / 1000).toFixed(2)} km`
      } else {
        description = 'Série ajoutée'
      }
      
      toast.success('Série ajoutée avec succès!', { description })
    }
    
    // Réinitialiser les erreurs du formulaire en cas de succès
    resetFormErrors()
    
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
    if (newSet.value.rest_seconds && parseInt(newSet.value.rest_seconds) > 0) {
      startRestTimer(parseInt(newSet.value.rest_seconds))
    }
    
    // Réinitialiser pendingSetData
    pendingSetData.value = null
  } catch (e) {
    const friendlyMessage = getUserFriendlyError(e.message)
    error.value = friendlyMessage
    console.error('Erreur lors de l\'ajout d\'une série:', e)
    
    // Détecter si c'est une erreur de validation et mettre en évidence le formulaire
    scrollToFormAndHighlightErrors(e.message)
    
    toast.error('Erreur', {
      description: friendlyMessage
    })
    pendingSetData.value = null
  }
}

const handleAddSet = async () => {
  try {
    // Créer la donnée de la série à envoyer à la base de données
    const measurementType = exercise.value?.exercise?.measurement_type || 'weight_reps'
    
    const setData = {
      exercise_id: exercise.value.exercise.id,
      weight_kg: newSet.value.weight_kg ? parseFloat(newSet.value.weight_kg) : 0, // Valeur par défaut 0 si non rempli
      reps: newSet.value.reps ? parseInt(newSet.value.reps) : (measurementType === 'weight_reps' || measurementType === 'reps' || measurementType === 'time_reps' ? 1 : 0), // Valeur par défaut 1 pour les types qui nécessitent reps, 0 pour time
      duration_seconds: newSet.value.duration_seconds ? parseInt(newSet.value.duration_seconds) : null,
      distance_meters: newSet.value.distance_meters ? parseFloat(newSet.value.distance_meters) : null,
      rest_seconds: newSet.value.rest_seconds ? parseInt(newSet.value.rest_seconds) : 0, // Valeur par défaut 0 si non rempli
      rpe: newSet.value.rpe ? parseFloat(newSet.value.rpe) : null,
      note: newSet.value.note || null
    }
    
    // S'assurer que rest_seconds n'est jamais null
    if (setData.rest_seconds === null || setData.rest_seconds === undefined) {
      setData.rest_seconds = 0
    }
    
    // S'assurer que weight_kg n'est jamais null
    if (setData.weight_kg === null || setData.weight_kg === undefined) {
      setData.weight_kg = 0
    }
    
    // S'assurer que reps n'est jamais null
    // Pour les exercices time, on met 0 au lieu de null
    if (setData.reps === null || setData.reps === undefined) {
      const requiresReps = ['weight_reps', 'reps', 'time_reps'].includes(measurementType)
      setData.reps = requiresReps ? 1 : 0
    }
    
    // Réinitialiser les erreurs du formulaire avant la validation
    resetFormErrors()
    
    // Vérifier les champs manquants (obligatoires et optionnels)
    const { required, optional } = checkMissingFields()
    
    // Si des champs obligatoires manquent, empêcher la soumission et afficher la modale
    if (required.length > 0) {
      missingFields.value = required
      missingOptionalFields.value = optional
      pendingSetData.value = setData
      showMissingFieldsModal.value = true
      
      // Scroller vers le formulaire et mettre en évidence les erreurs
      setTimeout(() => {
        if (formContainer.value) {
          formContainer.value.scrollIntoView({ behavior: 'smooth', block: 'center' })
        }
      }, 100)
      
      return
    }
    
    // Si seulement des champs optionnels manquent, proposer "Enregistrer quand même"
    if (optional.length > 0) {
      missingFields.value = []
      missingOptionalFields.value = optional
      pendingSetData.value = setData
      showMissingFieldsModal.value = true
      return
    }
    
    // Si aucun champ manquant, enregistrer directement
    pendingSetData.value = setData
    await actuallyAddSet()
  } catch (e) {
    const friendlyMessage = getUserFriendlyError(e.message)
    error.value = friendlyMessage
    console.error('Erreur lors de l\'ajout d\'une série:', e)
    
    // Détecter si c'est une erreur de validation et mettre en évidence le formulaire
    scrollToFormAndHighlightErrors(e.message)
    
    toast.error('Erreur', {
      description: friendlyMessage
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
    const friendlyMessage = getUserFriendlyError(e.message)
    console.error('Erreur lors du chargement des séries:', e)
    error.value = friendlyMessage
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
    const friendlyMessage = getUserFriendlyError(e.message)
    console.error('Erreur lors du chargement de l\'exercice:', e)
    error.value = friendlyMessage
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
    const friendlyMessage = getUserFriendlyError(e.message)
    error.value = friendlyMessage
    console.error('Erreur lors de la suppression d\'une série:', e)
    toast.error('Erreur', {
      description: friendlyMessage
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
    
    const measurementType = exercise.value?.exercise?.measurement_type || 'weight_reps'
    const updateData = {
      rest_seconds: editingSet.value.rest_seconds ? parseInt(editingSet.value.rest_seconds) : 0,
      rpe: editingSet.value.rpe ? parseFloat(editingSet.value.rpe) : null,
      note: editingSet.value.note || null
    }
    
    // Ajouter les champs selon le type d'exercice
    if (measurementType === 'time' || measurementType === 'time_reps' || measurementType === 'time_distance') {
      updateData.duration_seconds = editingSet.value.duration_seconds ? parseInt(editingSet.value.duration_seconds) : null
    }
    
    // Pour reps : toujours définir une valeur (0 pour time, la valeur pour les autres)
    if (measurementType === 'time') {
      updateData.reps = 0 // Pour les exercices time, on met 0 car il n'y a pas de répétitions
    } else if (measurementType === 'time_reps' || measurementType === 'weight_reps' || measurementType === 'reps') {
      updateData.reps = editingSet.value.reps ? parseInt(editingSet.value.reps) : (measurementType === 'time_reps' || measurementType === 'weight_reps' || measurementType === 'reps' ? 1 : 0)
    } else {
      updateData.reps = 0 // Par défaut pour les autres types
    }
    
    if (measurementType === 'weight_reps' || measurementType === 'weight_only' || measurementType === 'reps') {
      updateData.weight_kg = editingSet.value.weight_kg ? parseFloat(editingSet.value.weight_kg) : 0
    }
    
    const { data: updatedSet, error: updateError } = await supabase
      .from('exerciseset')
      .update(updateData)
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
      // Pour les exercices en temps et en répétitions, recharger les données pour avoir les stats complètes
      if (measurementType === 'time' || measurementType === 'reps') {
        await loadBestSet()
      } else {
        bestSet.value = updatedSet
      }
      
      let description = ''
      if (measurementType === 'weight_reps' || !measurementType) {
        description = `Vous avez battu votre ancien record avec ${updatedSet.weight_kg}kg x ${updatedSet.reps} répétitions`
      } else if (measurementType === 'time') {
        description = `Vous avez battu votre ancien record avec ${formatDuration(updatedSet.duration_seconds || 0)}`
      } else if (measurementType === 'reps') {
        description = `Vous avez battu votre ancien record avec ${updatedSet.reps} répétitions`
      } else {
        description = 'Nouveau record personnel !'
      }
      
      toast.success('Félicitations ! 🏆', { description })
    } else {
      // Pour les exercices en temps et en répétitions, recharger quand même pour mettre à jour les stats
      if (measurementType === 'time' || measurementType === 'reps') {
        await loadBestSet()
      }
      toast.success('Série mise à jour avec succès!')
    }

    showEditModal.value = false
  } catch (e) {
    const friendlyMessage = getUserFriendlyError(e.message)
    console.error('Erreur lors de la mise à jour de la série:', e)
    toast.error('Erreur', {
      description: friendlyMessage
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
    const friendlyMessage = getUserFriendlyError(e.message)
    console.error('Erreur lors de la suppression de la série:', e)
    toast.error('Erreur', {
      description: friendlyMessage
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

// Watch pour nettoyer le timer si la modale de repos est fermée autrement
watch(showRestModal, (isOpen) => {
  // Si la modale est fermée sans passer par skipRest, nettoyer le timer
  if (!isOpen && restTimer.value) {
    clearInterval(restTimer.value)
    restTimer.value = null
    restTimerStartTime.value = null
    restTimerDuration.value = 0
    restTimeRemaining.value = 0
  }
})

// Watcher pour réinitialiser les erreurs quand l'utilisateur modifie les champs
watch([() => newSet.value.weight_kg, () => newSet.value.reps, () => newSet.value.duration_seconds, () => newSet.value.distance_meters, () => newSet.value.rest_seconds], () => {
  // Si l'utilisateur modifie les champs, vérifier si les erreurs sont toujours valides
  if (hasFormErrors.value) {
    const { required } = checkMissingFields()
    // Si plus de champs obligatoires manquants, réinitialiser les erreurs
    if (required.length === 0) {
      resetFormErrors()
    }
  }
}, { deep: true })

// Gérer la visibilité de la page pour recalculer le timer quand l'utilisateur revient
if (process.client) {
  const handleVisibilityChange = () => {
    // Si la page redevient visible et qu'un timer de repos est actif, recalculer le temps restant
    if (!document.hidden && restTimer.value && restTimerStartTime.value) {
      const elapsed = Math.floor((Date.now() - restTimerStartTime.value) / 1000)
      const remaining = Math.max(0, restTimerDuration.value - elapsed)
      restTimeRemaining.value = remaining
      
      // Si le temps est écoulé pendant que l'app était en arrière-plan
      if (remaining <= 0) {
        clearInterval(restTimer.value)
        restTimer.value = null
        restTimerStartTime.value = null
        restTimerDuration.value = 0
        showRestModal.value = false
        // Pas de toast, le timer continue silencieusement
      }
    }
  }
  
  document.addEventListener('visibilitychange', handleVisibilityChange)
  
  // Nettoyer l'écouteur lors du démontage
  onBeforeUnmount(() => {
    document.removeEventListener('visibilitychange', handleVisibilityChange)
  })
}

// Nettoyer le timer lors du démontage du composant
onBeforeUnmount(() => {
  if (restTimer.value) {
    clearInterval(restTimer.value)
    restTimer.value = null
  }
  restTimerStartTime.value = null
  restTimerDuration.value = 0
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
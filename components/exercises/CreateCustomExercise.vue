<template>
  <Dialog :open="isOpen" @update:open="$emit('update:open', $event)">
    <DialogContent class="sm:max-w-md max-h-[90vh] !flex !flex-col">
      <DialogHeader class="flex-shrink-0">
        <DialogTitle>Créer un exercice personnalisé</DialogTitle>
        <DialogDescription>
          Créez votre propre exercice avec le type de mesure qui vous convient
        </DialogDescription>
      </DialogHeader>

      <form @submit.prevent="handleSubmit" class="flex-1 flex flex-col min-h-0 overflow-hidden">
        <div class="flex-1 overflow-y-auto space-y-4 pr-2 -mr-2">
        <!-- Nom de l'exercice -->
        <div class="space-y-2">
          <Label for="name">Nom de l'exercice *</Label>
          <Input
            id="name"
            v-model="form.name"
            type="text"
            placeholder="Ex: Gainage, Pompes lestées..."
            required
            :disabled="loading"
          />
        </div>

        <!-- Muscle principal -->
        <div class="space-y-2">
          <Label for="muscle">Muscle principal *</Label>
          <select
            id="muscle"
            v-model="form.primary_muscle"
            class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            required
            :disabled="loading"
          >
            <option value="">Sélectionnez un muscle</option>
            <option value="Pectoraux">Pectoraux</option>
            <option value="Dorsaux">Dorsaux</option>
            <option value="Épaules">Épaules</option>
            <option value="Biceps">Biceps</option>
            <option value="Triceps">Triceps</option>
            <option value="Jambes">Jambes</option>
            <option value="Fessiers">Fessiers</option>
            <option value="Mollets">Mollets</option>
            <option value="Abdominaux">Abdominaux</option>
            <option value="Cardio">Cardio</option>
            <option value="Autre">Autre</option>
          </select>
        </div>

        <!-- Type de mesure -->
        <div class="space-y-2">
          <Label>Type de mesure *</Label>
          <div class="space-y-2">
            <label
              v-for="type in measurementTypes"
              :key="type.value"
              class="flex items-center space-x-2 p-3 border rounded-lg cursor-pointer hover:bg-muted/50 transition-colors"
              :class="{ 'border-primary bg-primary/5': form.measurement_type === type.value }"
            >
              <input
                type="radio"
                :value="type.value"
                v-model="form.measurement_type"
                class="text-primary focus:ring-primary"
                :disabled="loading"
              />
              <div class="flex-1">
                <div class="font-medium">{{ type.label }}</div>
                <div class="text-xs text-muted-foreground">{{ type.description }}</div>
              </div>
            </label>
          </div>
        </div>

        <!-- Message informatif -->
        <div class="bg-primary/10 border border-primary/20 rounded-lg p-4">
          <div class="flex items-start gap-3">
            <Info class="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
            <div class="flex-1">
              <p class="text-sm font-medium text-foreground mb-2">
                Pour ajouter cet exercice à une séance :
              </p>
              <ul class="text-xs text-muted-foreground space-y-1.5 list-disc list-inside">
                <li>Allez dans une séance d'entraînement</li>
                <li>Cliquez sur "Ajouter un exercice"</li>
                <li>Recherchez votre exercice dans la liste</li>
                <li>Ajoutez-le à votre séance</li>
              </ul>
            </div>
          </div>
        </div>

          <!-- Message d'erreur -->
          <div v-if="error" class="text-sm text-destructive bg-destructive/10 p-3 rounded-lg">
            {{ error }}
          </div>
        </div>

        <DialogFooter class="flex-shrink-0 pt-4 border-t mt-4">
          <Button
            type="button"
            variant="outline"
            @click="$emit('update:open', false)"
            :disabled="loading"
          >
            Annuler
          </Button>
          <Button type="submit" :disabled="loading">
            <Loader2 v-if="loading" class="w-4 h-4 mr-2 animate-spin" />
            {{ loading ? 'Création...' : 'Créer' }}
          </Button>
        </DialogFooter>
      </form>
    </DialogContent>
  </Dialog>

</template>

<script setup>
import { ref, watch, computed, nextTick } from 'vue'
import { useSupabaseClient } from '#imports'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Loader2, Info } from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const props = defineProps({
  open: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:open', 'created'])

const supabase = useSupabaseClient()
const loading = ref(false)
const error = ref('')

const form = ref({
  name: '',
  primary_muscle: '',
  measurement_type: 'weight_reps'
})

const measurementTypes = [
  {
    value: 'weight_reps',
    label: 'Poids + Répétitions',
    description: 'Ex: Squat, Bench Press (poids généralement requis)'
  },
  {
    value: 'reps',
    label: 'Répétitions (poids optionnel)',
    description: 'Ex: Pompes, Tractions (peut être lesté)'
  },
  {
    value: 'time',
    label: 'Temps',
    description: 'Ex: Gainage, Planche'
  },
  {
    value: 'time_reps',
    label: 'Temps + Répétitions',
    description: 'Ex: Gainage 3x 30s'
  },
  {
    value: 'time_distance',
    label: 'Temps + Distance',
    description: 'Ex: Course, Vélo'
  },
  {
    value: 'distance',
    label: 'Distance uniquement',
    description: 'Ex: Marche'
  },
  {
    value: 'weight_only',
    label: 'Poids uniquement',
    description: 'Ex: Charge maximale (1RM)'
  }
]

const isOpen = computed(() => props.open)

// Réinitialiser le formulaire quand le dialog s'ouvre
watch(isOpen, (newValue) => {
  if (newValue) {
    form.value = {
      name: '',
      primary_muscle: '',
      measurement_type: 'weight_reps'
    }
    error.value = ''
  }
})

const handleSubmit = async () => {
  if (!form.value.name || !form.value.primary_muscle) {
    error.value = 'Veuillez remplir tous les champs obligatoires'
    return
  }

  loading.value = true
  error.value = ''

  try {
    const user = (await supabase.auth.getUser()).data.user
    if (!user) {
      throw new Error('Utilisateur non authentifié')
    }

    const { data, error: insertError } = await supabase
      .from('exercise')
      .insert({
        name: form.value.name,
        primary_muscle: form.value.primary_muscle,
        measurement_type: form.value.measurement_type,
        is_custom: true,
        user_id: user.id
      })
      .select()
      .single()

    if (insertError) throw insertError

    toast.success('Exercice créé avec succès !')
    emit('created', data)
    emit('update:open', false)
  } catch (e) {
    console.error('Erreur lors de la création de l\'exercice:', e)
    error.value = e.message || 'Une erreur est survenue lors de la création'
    toast.error('Erreur lors de la création de l\'exercice')
  } finally {
    loading.value = false
  }
}
</script>

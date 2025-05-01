<template>
  <div class="space-y-6">
    <div class="space-y-2">
      <h3 class="text-lg font-medium">Créer une nouvelle séance</h3>
      <p class="text-sm text-muted-foreground">Définissez les détails de votre séance d'entraînement.</p>
    </div>

    <form
      class="space-y-4"
      @submit.prevent="handleSubmit"
    >
      <div class="space-y-2">
        <Label for="title">Titre de la séance</Label>
        <Input 
          id="title" 
          v-model="formData.title" 
          type="text" 
          placeholder="Ex: Séance haut du corps"
          class="w-full"
          :class="{ 'border-red-500 focus:ring-red-500': showError && !formData.title.trim() }"
          required
        />
        <p v-if="showError && !formData.title.trim()" class="text-sm text-red-500 mt-1">
          Le titre de la séance est requis
        </p>
      </div>

      <div class="space-y-2">
        <Label for="notes">Description</Label>
        <Textarea 
          id="notes" 
          v-model="formData.notes" 
          placeholder="Ajoutez des notes ou des instructions pour votre séance"
          class="w-full"
        />
      </div>

      <div class="flex justify-end">
        <Button 
          type="submit" 
          :disabled="loading || !formData.title.trim()"
          :class="{ 'opacity-50 cursor-not-allowed': !formData.title.trim() }"
        >
          <span v-if="loading" class="animate-spin mr-2">⌛</span>
          Créer la séance
        </Button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { useWorkoutSessions } from '~/composables/useWorkoutSession';
import { useRouter } from 'vue-router';

const router = useRouter();
const user = useSupabaseUser();
const { createWorkoutSession, loading, error } = useWorkoutSessions(user);
const showError = ref(false);

const formData = ref({
  title: '',
  notes: '',
  date: new Date().toISOString().split('T')[0] // Date du jour par défaut
});

const handleSubmit = async () => {
  showError.value = true;
  
  if (!formData.value.title.trim()) {
    return;
  }

  try {
    const result = await createWorkoutSession(formData.value);
    if (result.success) {
      showError.value = false;
      // Réinitialiser le formulaire
      formData.value = {
        title: '',
        notes: '',
        date: new Date().toISOString().split('T')[0]
      };
      // Émettre un événement pour informer le parent
      emit('session-created', result.data);
      // Rediriger vers la page de détails de la séance
      router.push(`/seances/${result.data.id}/train`);
    } else {
      console.error('Erreur lors de la création de la séance:', result.error);
    }
  } catch (err) {
    console.error('Erreur lors de la création de la séance:', err);
  }
};

const emit = defineEmits(['session-created']);
</script>
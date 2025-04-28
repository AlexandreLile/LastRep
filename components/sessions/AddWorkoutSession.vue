<template>
    <div class="flex items-center justify-center">
      <Card class="w-full max-w-sm mx-2">
        <CardHeader>
          <CardTitle>Ajouter une séance</CardTitle>
        </CardHeader>
        <CardContent>
          <form
            class="space-y-4 flex flex-col gap-1 max-w-lg"
            @submit.prevent="handleSubmit"
          >
            <FormField name="title">
              <Label for="title">Titre de la séance</Label>
              <Input id="title" v-model="formData.title" type="text" />
            </FormField>
  
            <FormField name="notes">
              <Label for="notes">Description</Label>
              <Textarea id="notes" v-model="formData.notes" type="text" />
            </FormField>
  
            <Button type="submit" :disabled="loading">Créer la séance</Button>
          </form>
        </CardContent>
      </Card>
    </div>
  </template>

<script setup>

import { useWorkoutSessions } from '~/composables/useWorkoutSession';



const user = useSupabaseUser();
const { createWorkoutSession, loading, error } = useWorkoutSessions(user);

const formData = ref({
  title: '',
  notes: '',
  date: new Date().toISOString().split('T')[0] // Date du jour par défaut
});

const handleSubmit = async () => {
  try {
    const result = await createWorkoutSession(formData.value);
    if (result.success) {
      // Réinitialiser le formulaire
      formData.value = {
        title: '',
        notes: '',
        date: new Date().toISOString().split('T')[0]
      };
      // Émettre un événement pour informer le parent
      emit('session-created', result.data);
    } else {
      console.error('Erreur lors de la création de la séance:', result.error);
    }
  } catch (err) {
    console.error('Erreur lors de la création de la séance:', err);
  }
};

const emit = defineEmits(['session-created']);
</script>
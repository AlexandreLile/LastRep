import { ref } from 'vue';

export function useExercise() {
  const exercises = ref([]);
  const loading = ref(false);
  const error = ref(null);

  // Récupérer tous les exercices
  const getAllExercises = async () => {
    try {
      loading.value = true;
      const { data, error: supabaseError } = await useSupabaseClient()
        .from('exercise')
        .select('*')
        .order('name');

      if (supabaseError) throw supabaseError;

      exercises.value = data;
    } catch (e) {
      error.value = e.message;
      console.error('Erreur lors de la récupération des exercices:', e);
    } finally {
      loading.value = false;
    }
  };

  return {
    exercises,
    loading,
    error,
    getAllExercises
  };
} 
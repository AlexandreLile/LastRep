import { ref } from 'vue';

export function useExercise() {
  const exercises = ref([]);
  const loading = ref(false);
  const error = ref(null);

  // Récupérer tous les exercices (globaux + personnalisés de l'utilisateur)
  const getAllExercises = async () => {
    try {
      loading.value = true;
      const supabase = useSupabaseClient();
      const user = (await supabase.auth.getUser()).data.user;

      // Récupérer les exercices globaux (is_custom = false) + les exercices personnalisés de l'utilisateur
      let query = supabase
        .from('exercise')
        .select('*')
        .or(`is_custom.eq.false${user ? ',and(is_custom.eq.true,user_id.eq.' + user.id + ')' : ''}`)
        .order('is_custom', { ascending: true }) // Exercices globaux en premier
        .order('name', { ascending: true });

      const { data, error: supabaseError } = await query;

      if (supabaseError) throw supabaseError;

      exercises.value = data || [];
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
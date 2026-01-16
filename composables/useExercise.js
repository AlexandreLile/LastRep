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

      // Essayer d'abord avec la nouvelle structure (muscles multiples)
      // Si ça échoue, fallback sur l'ancienne structure
      let query = supabase
        .from('exercise')
        .select(`
          *,
          exercise_muscles:exercise_muscle (
            is_primary,
            muscle:muscle_id (
              id,
              name
            )
          )
        `)
        .or(`is_custom.eq.false${user ? ',and(is_custom.eq.true,user_id.eq.' + user.id + ')' : ''}`)
        .order('is_custom', { ascending: true }) // Exercices globaux en premier
        .order('name', { ascending: true });

      let { data, error: supabaseError } = await query;

      // Si erreur liée à la table exercise_muscle qui n'existe pas, essayer sans
      if (supabaseError && (supabaseError.message?.includes('exercise_muscle') || supabaseError.code === '42P01')) {
        console.warn('Table exercise_muscle non trouvée, utilisation de la structure simple');
        query = supabase
          .from('exercise')
          .select('*')
          .or(`is_custom.eq.false${user ? ',and(is_custom.eq.true,user_id.eq.' + user.id + ')' : ''}`)
          .order('is_custom', { ascending: true })
          .order('name', { ascending: true });
        
        const result = await query;
        data = result.data;
        supabaseError = result.error;
      }

      if (supabaseError) throw supabaseError;

      // Transformer les données pour faciliter l'utilisation
      exercises.value = (data || []).map(exercise => {
        // Si exercise_muscles existe, utiliser la nouvelle structure
        if (exercise.exercise_muscles && Array.isArray(exercise.exercise_muscles)) {
          const muscles = exercise.exercise_muscles
            .map(em => em.muscle)
            .filter(Boolean)
            .sort((a, b) => {
              // Trier : muscle principal en premier
              const aIsPrimary = exercise.exercise_muscles.find(em => em.muscle?.id === a.id)?.is_primary || false;
              const bIsPrimary = exercise.exercise_muscles.find(em => em.muscle?.id === b.id)?.is_primary || false;
              return bIsPrimary - aIsPrimary;
            });

          return {
            ...exercise,
            muscles: muscles,
            muscles_names: muscles.map(m => m.name),
            primary_muscle: exercise.primary_muscle || (muscles[0]?.name || '')
          };
        }
        
        // Sinon, utiliser l'ancienne structure avec primary_muscle uniquement
        return {
          ...exercise,
          muscles: exercise.primary_muscle ? [{ name: exercise.primary_muscle }] : [],
          muscles_names: exercise.primary_muscle ? [exercise.primary_muscle] : [],
          primary_muscle: exercise.primary_muscle || ''
        };
      });
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
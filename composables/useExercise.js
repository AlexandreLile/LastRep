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

      // get_visible_exercises() retourne : les exercices persos de l'utilisateur,
      // les nouveaux exercices globaux, et les anciens exercices globaux (legacy)
      // uniquement si l'utilisateur les a déjà utilisés (séances/séries passées).
      // Le catalogue dépasse la limite par défaut de 1000 lignes de PostgREST,
      // donc on paginé avec .range() jusqu'à récupérer toutes les lignes.
      const PAGE_SIZE = 1000;
      const fetchPage = (from, withMuscles) => {
        let query = supabase.rpc('get_visible_exercises');
        query = withMuscles
          ? query.select(`
              *,
              exercise_muscles:exercise_muscle (
                is_primary,
                muscle:muscle_id (
                  id,
                  name
                )
              )
            `)
          : query.select('*');
        return query
          .order('is_custom', { ascending: true }) // Exercices globaux en premier
          .order('name', { ascending: true })
          .range(from, from + PAGE_SIZE - 1);
      };

      const fetchAllPages = async (withMuscles) => {
        let all = [];
        let from = 0;
        while (true) {
          const { data: page, error: pageError } = await fetchPage(from, withMuscles);
          if (pageError) return { data: null, error: pageError };
          all = all.concat(page || []);
          if (!page || page.length < PAGE_SIZE) break;
          from += PAGE_SIZE;
        }
        return { data: all, error: null };
      };

      let { data, error: supabaseError } = await fetchAllPages(true);

      // Si erreur liée à la table exercise_muscle qui n'existe pas, essayer sans
      if (supabaseError && (supabaseError.message?.includes('exercise_muscle') || supabaseError.code === '42P01')) {
        console.warn('Table exercise_muscle non trouvée, utilisation de la structure simple');
        const result = await fetchAllPages(false);
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
import { ref } from 'vue';
import { cacheWorkoutExercise, cacheWorkoutExercises, getCachedWorkoutExercise, getCachedWorkoutExercises, isOnline } from '~/utils/offlineTraining';

export const useWorkoutExercise = () => {
  const workoutExercises = ref([]);
  const error = ref(null);
  const loading = ref(false);

  // Récupérer tous les exercices d'une séance
  const fetchWorkoutExercises = async (sessionId) => {
    const { data, error: fetchError } = await useSupabaseClient()
      .from('workoutexercise')
      .select(`
        *,
        exercise:exercise_id (
          id,
          name,
          primary_muscle,
          measurement_type,
          is_custom
        )
      `)
      .eq('session_id', sessionId)
      .order('order', { ascending: true });

    if (fetchError) throw fetchError;

    workoutExercises.value = data;
    cacheWorkoutExercises(sessionId, data);
    if (Array.isArray(data)) {
      data.forEach((exercise) => {
        if (exercise?.id) {
          cacheWorkoutExercise(exercise.id, exercise);
        }
      });
    }
    return data;
  };

  const getWorkoutExercises = async (sessionId) => {
    try {
      loading.value = true;
      error.value = null;

      const cachedExercises = getCachedWorkoutExercises(sessionId);
      if (cachedExercises && cachedExercises.length > 0) {
        workoutExercises.value = cachedExercises;
        if (isOnline()) {
          fetchWorkoutExercises(sessionId).catch((err) => {
            console.error('Erreur lors du refresh des exercices:', err);
          });
        }
        return { data: workoutExercises.value, error: null };
      }

      if (!isOnline()) {
        workoutExercises.value = [];
        return { data: workoutExercises.value, error: null };
      }

      const data = await fetchWorkoutExercises(sessionId);
      return { data, error: null };
    } catch (e) {
      const cachedExercises = getCachedWorkoutExercises(sessionId);
      if (cachedExercises && cachedExercises.length > 0) {
        workoutExercises.value = cachedExercises;
        return { data: workoutExercises.value, error: null };
      }
      error.value = e.message;
      return { data: null, error: e };
    } finally {
      loading.value = false;
    }
  };

  // Ajouter un exercice à une séance
  const addExerciseToSession = async (sessionId, exerciseId) => {
    try {
      loading.value = true;
      const { data, error: supabaseError } = await useSupabaseClient()
        .from('workoutexercise')
        .insert([
          {
            session_id: sessionId,
            exercise_id: exerciseId,
            order: workoutExercises.value.length + 1
          }
        ])
        .select()
        .single();

      if (supabaseError) throw supabaseError;

      workoutExercises.value.push(data);
      return { success: true, data };
    } catch (e) {
      error.value = e.message;
      console.error('Erreur lors de l\'ajout de l\'exercice:', e);
      return { success: false, error: e.message };
    } finally {
      loading.value = false;
    }
  };

  // Supprimer un exercice d'une séance
  const removeWorkoutExercise = async (workoutExerciseId) => {
    try {
      loading.value = true;
      error.value = null;

      const { error: deleteError } = await useSupabaseClient()
        .from('workoutexercise')
        .delete()
        .eq('id', workoutExerciseId);

      if (deleteError) throw deleteError;

      // Mettre à jour le state local
      workoutExercises.value = workoutExercises.value.filter(
        exercise => exercise.id !== workoutExerciseId
      );

      return { success: true };
    } catch (err) {
      error.value = err.message;
      return { success: false, error: err.message };
    } finally {
      loading.value = false;
    }
  };

  // Mettre à jour l'ordre des exercices
  const updateExerciseOrder = async (workoutExerciseId, newOrder) => {
    try {
      loading.value = true;
      error.value = null;

      const { error: updateError } = await useSupabaseClient()
        .from('workoutexercise')
        .update({ order: newOrder })
        .eq('id', workoutExerciseId);

      if (updateError) throw updateError;

      return { success: true };
    } catch (err) {
      error.value = err.message;
      return { success: false, error: err.message };
    } finally {
      loading.value = false;
    }
  };

  const getWorkoutExercise = async (exerciseId) => {
    try {
      loading.value = true;
      if (!isOnline()) {
        const cachedExercise = getCachedWorkoutExercise(exerciseId);
        if (cachedExercise) {
          return { data: cachedExercise, error: null };
        }
      }
      const { data, error: fetchError } = await useSupabaseClient()
        .from('workoutexercise')
        .select(`
          *,
          exercise:exercise_id (
            id,
            name,
            primary_muscle,
            measurement_type,
            is_custom
          )
        `)
        .eq('id', exerciseId)
        .single();

      if (fetchError) throw fetchError;
      cacheWorkoutExercise(exerciseId, data);
      return { data, error: null };
    } catch (e) {
      console.error('Error fetching exercise:', e);
      const cachedExercise = getCachedWorkoutExercise(exerciseId);
      if (cachedExercise) {
        return { data: cachedExercise, error: null };
      }
      error.value = e.message;
      return { data: null, error: e };
    } finally {
      loading.value = false;
    }
  };

  return {
    workoutExercises,
    error,
    loading,
    getWorkoutExercises,
    addExerciseToSession,
    removeWorkoutExercise,
    updateExerciseOrder,
    getWorkoutExercise
  };
}; 
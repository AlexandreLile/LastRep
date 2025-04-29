import { ref } from 'vue';

export function useWorkoutExercise() {
  const workoutExercises = ref([]);
  const loading = ref(false);
  const error = ref(null);

  // Récupérer tous les exercices d'une séance
  const getWorkoutExercises = async (sessionId) => {
    try {
      loading.value = true;
      error.value = null;

      const { data, error: fetchError } = await useSupabaseClient()
        .from('workoutexercise')
        .select(`
          id,
          session_id,
          exercise_id,
          "order",
          Exercise:exercise_id (
            id,
            name,
            primary_muscle
          )
        `)
        .eq('session_id', sessionId)
        .order('order', { ascending: true });

      if (fetchError) throw fetchError;

      workoutExercises.value = data;
      return { success: true, data };
    } catch (err) {
      error.value = err.message;
      return { success: false, error: err.message };
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
      const { data, error: fetchError } = await useSupabaseClient()
        .from('workoutexercise')
        .select(`
          *,
          Exercise (
            name,
            primary_muscle,
            description
          )
        `)
        .eq('id', exerciseId)
        .single()

      if (fetchError) throw fetchError
      return { data, error: null }
    } catch (e) {
      console.error('Error fetching exercise:', e)
      return { data: null, error: e }
    }
  }

  return {
    workoutExercises,
    loading,
    error,
    getWorkoutExercises,
    addExerciseToSession,
    removeWorkoutExercise,
    updateExerciseOrder,
    getWorkoutExercise
  };
} 
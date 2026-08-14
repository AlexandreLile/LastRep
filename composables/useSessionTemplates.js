import { ref } from 'vue';
import { adminFetch } from '~/composables/useAdminFetch';

export function useSessionTemplates() {
  const templates = ref([]);
  const loading = ref(false);
  const error = ref(null);

  const getSessionTemplates = async () => {
    loading.value = true;
    error.value = null;

    try {
      const supabase = useSupabaseClient();
      const { data, error: supabaseError } = await supabase
        .from('session_template')
        .select(`
          *,
          exercises:session_template_exercise (
            id,
            order,
            target_sets,
            target_reps,
            exercise:exercise_id (
              id,
              name,
              primary_muscle,
              image_url
            )
          )
        `)
        .order('category', { ascending: true })
        .order('title', { ascending: true });

      if (supabaseError) throw supabaseError;

      templates.value = (data || []).map(template => ({
        ...template,
        exercises: [...(template.exercises || [])].sort((a, b) => a.order - b.order)
      }));

      return { data: templates.value, error: null };
    } catch (err) {
      console.error('Erreur lors de la récupération des séances modèles:', err);
      error.value = err.message;
      return { data: null, error: err.message };
    } finally {
      loading.value = false;
    }
  };

  // Copie une séance modèle dans les séances de l'utilisateur connecté
  const addTemplateToMySessions = async (template) => {
    const user = useSupabaseUser();
    if (!user?.value?.id) {
      error.value = 'Utilisateur non connecté';
      return { success: false, error: error.value };
    }

    loading.value = true;
    error.value = null;

    try {
      const supabase = useSupabaseClient();

      const { data: newSession, error: sessionError } = await supabase
        .from('workoutsession')
        .insert({
          title: template.title,
          notes: template.description || null,
          user_id: user.value.id,
          date: new Date().toISOString()
        })
        .select()
        .single();

      if (sessionError) throw sessionError;

      const exercisesToInsert = (template.exercises || []).map(templateExercise => ({
        session_id: newSession.id,
        exercise_id: templateExercise.exercise.id,
        order: templateExercise.order
      }));

      if (exercisesToInsert.length > 0) {
        const { error: exercisesError } = await supabase
          .from('workoutexercise')
          .insert(exercisesToInsert);

        if (exercisesError) throw exercisesError;
      }

      return { success: true, data: newSession };
    } catch (err) {
      console.error('Erreur lors de l\'ajout de la séance modèle:', err);
      error.value = err.message;
      return { success: false, error: err.message };
    } finally {
      loading.value = false;
    }
  };

  // Admin : crée une nouvelle séance modèle dans le catalogue (nécessite les droits admin)
  const createSessionTemplate = async (payload) => {
    loading.value = true;
    error.value = null;

    try {
      const response = await adminFetch('/api/admin/session-templates', {
        method: 'POST',
        body: payload
      });
      return { success: true, data: response.data };
    } catch (err) {
      const message = err?.data?.statusMessage || err.message;
      error.value = message;
      return { success: false, error: message };
    } finally {
      loading.value = false;
    }
  };

  // Admin : modifie une séance modèle existante du catalogue (nécessite les droits admin)
  const updateSessionTemplate = async (templateId, payload) => {
    loading.value = true;
    error.value = null;

    try {
      const response = await adminFetch(`/api/admin/session-templates/${templateId}`, {
        method: 'PATCH',
        body: payload
      });
      return { success: true, data: response.data };
    } catch (err) {
      const message = err?.data?.statusMessage || err.message;
      error.value = message;
      return { success: false, error: message };
    } finally {
      loading.value = false;
    }
  };

  // Admin : supprime une séance modèle du catalogue (nécessite les droits admin)
  const deleteSessionTemplate = async (templateId) => {
    loading.value = true;
    error.value = null;

    try {
      await adminFetch(`/api/admin/session-templates/${templateId}`, { method: 'DELETE' });
      templates.value = templates.value.filter(template => template.id !== templateId);
      return { success: true };
    } catch (err) {
      const message = err?.data?.statusMessage || err.message;
      error.value = message;
      return { success: false, error: message };
    } finally {
      loading.value = false;
    }
  };

  return {
    templates,
    loading,
    error,
    getSessionTemplates,
    addTemplateToMySessions,
    createSessionTemplate,
    updateSessionTemplate,
    deleteSessionTemplate
  };
}

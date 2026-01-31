import { ref } from 'vue';
import { useSupabaseClient } from '#imports';
import { cacheWorkoutSession, cacheWorkoutSessions, getCachedWorkoutSession, getCachedWorkoutSessions, isOnline } from '~/utils/offlineTraining';

export function useWorkoutSessions(user) {
    const workoutSessions = ref([]);
    const loading = ref(false);
    const error = ref(null);
    const lastFetchTime = ref(null);
    const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

    const validateSessionData = (sessionData) => {
        const requiredFields = ['title', 'date'];
        return requiredFields.every(field => sessionData[field]);
    };

    const getWorkoutSession = async (sessionId) => {
        if (!user?.value?.id) {
            error.value = 'Utilisateur non connecté';
            return { data: null, error: error.value };
        }

        loading.value = true;
        error.value = null;

        try {
            if (!isOnline()) {
                const cachedSession = getCachedWorkoutSession(sessionId);
                if (cachedSession) {
                    return { data: cachedSession, error: null };
                }
            }

            const supabase = useSupabaseClient();
            const { data, error: supabaseError } = await supabase
                .from('workoutsession')
                .select('*')
                .eq('id', sessionId)
                .single();

            if (supabaseError) throw supabaseError;

            cacheWorkoutSession(sessionId, data);
            return { data, error: null };
        } catch (err) {
            console.error('Erreur lors de la récupération de la séance:', err);
            const cachedSession = getCachedWorkoutSession(sessionId);
            if (cachedSession) {
                return { data: cachedSession, error: null };
            }
            return { data: null, error: err.message };
        } finally {
            loading.value = false;
        }
    };

    const getWorkoutSessions = async () => {
        if (!user?.value?.id) {
            error.value = 'Utilisateur non connecté';
            return;
        }

        loading.value = true;
        error.value = null;

        try {
            if (!isOnline()) {
                workoutSessions.value = getCachedWorkoutSessions(user.value.id) || [];
                return;
            }

            const supabase = useSupabaseClient();
            const { data, error: supabaseError } = await supabase
                .from('workoutsession')
                .select(`
                    *,
                    exercises:workoutexercise (
                        id,
                        exercise:exercise_id (
                            id,
                            name,
                            primary_muscle
                        )
                    )
                `)
                .eq('user_id', user.value.id)
                .order('date', { ascending: false });

            if (supabaseError) throw supabaseError;

            workoutSessions.value = data || [];
            cacheWorkoutSessions(user.value.id, workoutSessions.value);
        } catch (err) {
            console.error('Erreur lors de la récupération des séances:', err);
            const cachedSessions = getCachedWorkoutSessions(user.value.id);
            if (cachedSessions && cachedSessions.length > 0) {
                workoutSessions.value = cachedSessions;
            } else {
                error.value = err.message;
            }
        } finally {
            loading.value = false;
        }
    };

    const createWorkoutSession = async (sessionData) => {
        if (!user?.value?.id) {
            error.value = 'Utilisateur non connecté';
            return { success: false, error: error.value };
        }

        loading.value = true;
        error.value = null;

        try {
            const supabase = useSupabaseClient();
            const { data, error: supabaseError } = await supabase
                .from('workoutsession')
                .insert({
                    ...sessionData,
                    user_id: user.value.id,
                    date: new Date().toISOString()
                })
                .select()
                .single();

            if (supabaseError) throw supabaseError;

            workoutSessions.value.unshift(data);
            return { success: true, data };
        } catch (err) {
            console.error('Erreur lors de la création de la séance:', err);
            error.value = err.message;
            return { success: false, error: err.message };
        } finally {
            loading.value = false;
        }
    };

    const editWorkoutSession = async (sessionId, updatedData) => {
        if (!user?.value?.id) {
            error.value = 'Utilisateur non connecté';
            return { success: false, error: error.value };
        }

        loading.value = true;
        error.value = null;

        try {
            const supabase = useSupabaseClient();
            const { data, error: supabaseError } = await supabase
                .from('workoutsession')
                .update(updatedData)
                .eq('id', sessionId)
                .eq('user_id', user.value.id)
                .select()
                .single();

            if (supabaseError) throw supabaseError;

            const index = workoutSessions.value.findIndex(s => s.id === sessionId);
            if (index !== -1) {
                workoutSessions.value[index] = data;
            }

            return { success: true, data };
        } catch (err) {
            console.error('Erreur lors de la modification de la séance:', err);
            error.value = err.message;
            return { success: false, error: err.message };
        } finally {
            loading.value = false;
        }
    };

    const deleteWorkoutSession = async (sessionId) => {
        if (!user?.value?.id) {
            error.value = 'Utilisateur non connecté';
            return { success: false, error: error.value };
        }

        loading.value = true;
        error.value = null;

        try {
            const supabase = useSupabaseClient();
            const { error: supabaseError } = await supabase
                .from('workoutsession')
                .delete()
                .eq('id', sessionId)
                .eq('user_id', user.value.id);

            if (supabaseError) throw supabaseError;

            workoutSessions.value = workoutSessions.value.filter(s => s.id !== sessionId);
            return { success: true };
        } catch (err) {
            console.error('Erreur lors de la suppression de la séance:', err);
            error.value = err.message;
            return { success: false, error: err.message };
        } finally {
            loading.value = false;
        }
    };

    const getSessionById = async (sessionId) => {
        if (!user?.value?.id) return null;
        return workoutSessions.value.find(session => session.id === sessionId);
    };

    const getSessionsByDate = (date) => {
        return workoutSessions.value.filter(session => 
            new Date(session.date).toDateString() === new Date(date).toDateString()
        );
    };

    onMounted(() => {
        if (user?.value?.id) getWorkoutSessions();
    });

    return {
        workoutSessions,
        loading,
        error,
        getWorkoutSession,
        getWorkoutSessions,
        createWorkoutSession,
        editWorkoutSession,
        deleteWorkoutSession,
        getSessionById,
        getSessionsByDate
    };
}
  
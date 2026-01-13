<template>
  <div>
    <div v-if="loading" class="flex justify-center items-center h-32">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="lastSession" class="space-y-6">
      <!-- Titre de la séance -->
      <div class="space-y-2">
        <h4 class="text-xl font-semibold text-foreground">{{ lastSession.title }}</h4>
        <div class="flex items-center space-x-3 text-sm text-muted-foreground">
          <div class="flex items-center space-x-1">
            <Calendar class="w-4 h-4" />
            <span>{{ formatDate(lastSession.ended_at) }}</span>
          </div>
          <span>•</span>
          <div class="flex items-center space-x-1">
            <Clock class="w-4 h-4" />
            <span>{{ formatDuration(lastSession.started_at, lastSession.ended_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Volume total -->
      <div class="bg-primary/10 rounded-lg p-6">
        <div class="space-y-2">
          <span class="text-sm text-muted-foreground">Volume total</span>
          <div class="flex items-baseline space-x-2">
            <span class="text-3xl font-bold text-primary">{{ totalWeight.toLocaleString('fr-FR') }}</span>
            <span class="text-lg text-muted-foreground">kg</span>
            <div v-if="volumeDifference !== null" 
                 :class="[
                   'flex items-center space-x-1 text-sm font-medium',
                   volumeDifference > 0 ? 'text-green-500' : volumeDifference < 0 ? 'text-red-500' : 'text-muted-foreground'
                 ]"
            >
              <ArrowUp v-if="volumeDifference > 0" class="w-4 h-4" />
              <ArrowDown v-if="volumeDifference < 0" class="w-4 h-4" />
              <span>{{ Math.abs(volumeDifference).toLocaleString('fr-FR') }} kg</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="flex flex-col items-center justify-center py-8 px-4 space-y-4 bg-muted/50 rounded-lg">
      <Dumbbell class="w-12 h-12 text-muted-foreground/50" />
      <p class="text-sm text-muted-foreground text-center">
        Aucune séance effectuée
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'
import { Timer, Dumbbell, ArrowUp, ArrowDown, Calendar, Clock } from 'lucide-vue-next'

const supabase = useSupabaseClient()
const loading = ref(true)
const lastSession = ref(null)
const totalWeight = ref(0)
const volumeDifference = ref(null)

const fetchLastSession = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Récupérer la dernière séance effectuée
    const { data: session, error: sessionError } = await supabase
      .from('performedsession')
      .select(`
        id,
        started_at,
        ended_at,
        workout_session_id,
        workoutsession (
          title,
          workoutexercise (
            id,
            exercise_id
          )
        )
      `)
      .eq('user_id', user.id)
      .order('ended_at', { ascending: false })
      .not('ended_at', 'is', null)
      .limit(1)
      .single()

    if (sessionError) throw sessionError

    if (session && session.started_at && session.ended_at) {
      lastSession.value = {
        ...session,
        title: session.workoutsession.title
      }

      // Récupérer les exercices de la séance
      const exerciseIds = session.workoutsession.workoutexercise.map(ex => ex.exercise_id)

      // Récupérer les sets de la dernière séance
      const { data: currentSets, error: currentSetsError } = await supabase
        .from('exerciseset')
        .select(`
          weight_kg,
          reps,
          created_at
        `)
        .in('exercise_id', exerciseIds)
        .eq('user_id', user.id)
        .gte('created_at', session.started_at)
        .lte('created_at', session.ended_at)

      if (currentSetsError) throw currentSetsError

      // Calculer le volume total de la séance actuelle
      if (currentSets && currentSets.length > 0) {
        totalWeight.value = currentSets.reduce((total, set) => {
          return total + (set.weight_kg * set.reps)
        }, 0)

        // Récupérer toutes les séances effectuées pour ce workout_session_id
        const { data: allSessions, error: allSessionsError } = await supabase
          .from('performedsession')
          .select(`
            id,
            started_at,
            ended_at
          `)
          .eq('user_id', user.id)
          .eq('workout_session_id', session.workout_session_id)
          .order('ended_at', { ascending: false })

        if (!allSessionsError && allSessions && allSessions.length > 1) {
          // Trouver la séance précédente (la deuxième dans la liste puisqu'elles sont triées par date décroissante)
          const previousSession = allSessions.find(s => s.id !== session.id)

          if (previousSession) {
            // Récupérer les sets de la séance précédente
            const { data: previousSets, error: previousSetsError } = await supabase
              .from('exerciseset')
              .select(`
                weight_kg,
                reps
              `)
              .in('exercise_id', exerciseIds)
              .eq('user_id', user.id)
              .gte('created_at', previousSession.started_at)
              .lte('created_at', previousSession.ended_at)

            if (!previousSetsError && previousSets && previousSets.length > 0) {
              const previousVolume = previousSets.reduce((total, set) => {
                return total + (set.weight_kg * set.reps)
              }, 0)
              
              // Calculer la différence
              volumeDifference.value = totalWeight.value - previousVolume
            }
          }
        }
      } else {
        totalWeight.value = 0
      }
    }
  } catch (error) {
    console.error('Erreur lors de la récupération de la dernière séance:', error)
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

const formatDuration = (start, end) => {
  const startDate = new Date(start)
  const endDate = new Date(end)
  const durationMs = endDate - startDate
  const minutes = Math.floor(durationMs / (1000 * 60))
  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60

  if (hours > 0) {
    return `${hours}h${remainingMinutes > 0 ? ` ${remainingMinutes}min` : ''}`
  }
  return `${minutes}min`
}

onMounted(() => {
  fetchLastSession()
})
</script> 
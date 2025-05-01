<template>
  <div>
    <h3 class="text-lg font-medium text-gray-900 mb-4">Dernière séance</h3>
    <div v-if="loading" class="flex justify-center items-center h-32">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
    </div>
    <div v-else-if="lastSession" class="space-y-4">
      <div class="flex justify-between items-center">
        <span class="text-gray-600">Séance</span>
        <span class="font-medium">{{ lastSession.title }}</span>
      </div>
      <div class="flex justify-between items-center">
        <span class="text-gray-600">Date</span>
        <span class="font-medium">{{ formatDate(lastSession.ended_at) }}</span>
      </div>
      <div class="flex justify-between items-center">
        <span class="text-gray-600">Poids total</span>
        <span class="font-medium">{{ totalWeight.toLocaleString('fr-FR') }} kg</span>
      </div>
    </div>
    <div v-else class="text-gray-500 text-center py-8">
      Aucune séance effectuée
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'

const supabase = useSupabaseClient()
const loading = ref(true)
const lastSession = ref(null)
const totalWeight = ref(0)

const fetchLastSession = async () => {
  try {
    const user = await supabase.auth.getUser()
    console.log('User ID:', user.data.user.id)

    // Récupérer la dernière séance effectuée
    const { data: session, error: sessionError } = await supabase
      .from('performedsession')
      .select(`
        id,
        started_at,
        ended_at,
        workout_session_id,
        workoutsession (
          title
        )
      `)
      .eq('user_id', user.data.user.id)
      .order('ended_at', { ascending: false })
      .not('ended_at', 'is', null)
      .limit(1)
      .single()

    if (sessionError) {
      console.error('Erreur session:', sessionError)
      throw sessionError
    }

    console.log('Dernière séance:', session)

    if (session && session.started_at && session.ended_at) {
      lastSession.value = {
        ...session,
        title: session.workoutsession.title
      }

      // D'abord, vérifions tous les sets de l'utilisateur
      const { data: allSets, error: allSetsError } = await supabase
        .from('exerciseset')
        .select('*')
        .eq('user_id', user.data.user.id)

      if (allSetsError) {
        console.error('Erreur récupération tous les sets:', allSetsError)
      } else {
        console.log('Tous les sets de l\'utilisateur:', allSets)
      }

      // Récupérer le poids total de la séance
      const { data: sets, error: setsError } = await supabase
        .from('exerciseset')
        .select(`
          weight_kg,
          reps,
          exercise_id,
          created_at
        `)
        .eq('user_id', user.data.user.id)
        .eq('performed_session_id', session.id)

      if (setsError) {
        console.error('Erreur sets:', setsError)
        throw setsError
      }

      console.log('Sets récupérés pour la session:', sets)
      console.log('ID de la session:', session.id)

      if (sets && sets.length > 0) {
        // Calcul du poids total (poids × répétitions pour chaque série)
        totalWeight.value = sets.reduce((total, set) => {
          console.log('Calcul pour le set:', {
            weight: set.weight_kg,
            reps: set.reps,
            subtotal: set.weight_kg * set.reps
          })
          return total + (set.weight_kg * set.reps)
        }, 0)

        console.log('Poids total calculé:', totalWeight.value)
      } else {
        console.log('Aucun set trouvé pour cette séance')
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

onMounted(() => {
  fetchLastSession()
})
</script> 
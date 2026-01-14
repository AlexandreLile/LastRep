<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
    <div class="container mx-auto px-4 py-16">
      <!-- Carte principale -->
      <Card class="max-w-2xl mx-auto shadow-xl">
        <CardHeader class="text-center pb-4">
          <div class="flex items-center justify-center gap-3 mb-2">
            <Avatar class="h-12 w-12">
              <AvatarImage :src="session?.user?.avatar_url" />
              <AvatarFallback>{{ session?.user?.username?.[0]?.toUpperCase() }}</AvatarFallback>
            </Avatar>
            <div class="text-left">
              <CardTitle class="text-2xl">{{ session?.workout?.title || 'Séance d\'entraînement' }}</CardTitle>
              <CardDescription v-if="session?.user">
                Par @{{ session.user.username }}
              </CardDescription>
            </div>
          </div>
        </CardHeader>

        <CardContent class="space-y-6">
          <!-- Statistiques principales -->
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div class="text-center p-4 bg-primary/5 rounded-lg">
              <div class="text-3xl mb-2">⏱️</div>
              <div class="text-2xl font-bold text-gray-900">
                {{ formatDuration(session?.duration) }}
              </div>
              <div class="text-sm text-muted-foreground">Durée</div>
            </div>

            <div class="text-center p-4 bg-primary/5 rounded-lg">
              <div class="text-3xl mb-2">💪</div>
              <div class="text-2xl font-bold text-gray-900">
                {{ session?.exercise_count || 0 }}
              </div>
              <div class="text-sm text-muted-foreground">Exercices</div>
            </div>

            <div class="text-center p-4 bg-primary/5 rounded-lg">
              <div class="text-3xl mb-2">📊</div>
              <div class="text-2xl font-bold text-gray-900">
                {{ formatWeight(session?.total_weight) }}
              </div>
              <div class="text-sm text-muted-foreground">Volume</div>
            </div>

            <div class="text-center p-4 bg-primary/5 rounded-lg">
              <div class="text-3xl mb-2">🔥</div>
              <div class="text-2xl font-bold text-gray-900">
                ~{{ session?.calories || 0 }}
              </div>
              <div class="text-sm text-muted-foreground">Calories</div>
            </div>
          </div>

          <!-- Date -->
          <div class="text-center text-muted-foreground">
            <Calendar class="h-4 w-4 inline mr-2" />
            {{ formatDate(session?.started_at) }}
          </div>

          <!-- Exercices (si disponibles) -->
          <div v-if="session?.exercises?.length" class="space-y-2">
            <h3 class="font-semibold text-lg">Exercices réalisés</h3>
            <div class="space-y-2">
              <div 
                v-for="exercise in session.exercises" 
                :key="exercise.id"
                class="p-3 bg-gray-50 rounded-lg"
              >
                <div class="font-medium">{{ exercise.exercise?.name }}</div>
                <div class="text-sm text-muted-foreground">
                  {{ exercise.sets?.length || 0 }} séries
                </div>
              </div>
            </div>
          </div>

          <!-- Call to action -->
          <div class="flex flex-col sm:flex-row gap-3 pt-4">
            <Button 
              @click="goToApp"
              class="flex-1"
              size="lg"
            >
              <Dumbbell class="h-4 w-4 mr-2" />
              Créer un compte sur LastRep
            </Button>
            
            <Button 
              @click="shareThisPage"
              variant="outline"
              class="flex-1"
              size="lg"
            >
              <Share2 class="h-4 w-4 mr-2" />
              Partager cette séance
            </Button>
          </div>
        </CardContent>

        <CardFooter class="flex justify-center pt-4 border-t">
          <p class="text-sm text-muted-foreground">
            Créé avec ❤️ sur <span class="font-semibold text-primary">LastRep</span>
          </p>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useSupabaseClient } from '#imports'
import { Calendar, Dumbbell, Share2 } from 'lucide-vue-next'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'

const route = useRoute()
const supabase = useSupabaseClient()
const session = ref(null)
const loading = ref(true)

// Récupérer la séance par token
onMounted(async () => {
  try {
    const { data, error } = await supabase
      .from('performedsession')
      .select(`
        *,
        workoutsession:workout_session_id (
          id,
          title
        ),
        user:user_id (
          id,
          username,
          avatar_url
        )
      `)
      .eq('share_token', route.params.token)
      .eq('is_shared', true)
      .single()

    if (error) throw error
    session.value = data

    // Calculer les stats
    if (data) {
      // Calculer la durée
      if (data.started_at && data.ended_at) {
        const start = new Date(data.started_at)
        const end = new Date(data.ended_at)
        session.value.duration = Math.round((end - start) / 1000 / 60) // en minutes
      }

      // Récupérer les exercices
      const { data: exercises } = await supabase
        .from('exerciseset')
        .select(`
          exercise_id,
          exercise:exercise_id (name),
          performed_session_id
        `)
        .eq('performed_session_id', data.id)
        .eq('user_id', data.user_id)

      if (exercises) {
        // Grouper par exercice
        const grouped = exercises.reduce((acc, ex) => {
          const key = ex.exercise_id
          if (!acc[key]) {
            acc[key] = {
              exercise_id: key,
              exercise: ex.exercise,
              sets: []
            }
          }
          acc[key].sets.push(ex)
          return acc
        }, {})

        session.value.exercises = Object.values(grouped)
        session.value.exercise_count = Object.keys(grouped).length
      }
    }
  } catch (error) {
    console.error('Erreur:', error)
  } finally {
    loading.value = false
  }
})

// Formater la durée
const formatDuration = (minutes) => {
  if (!minutes) return '0min'
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  if (hours > 0) {
    return `${hours}h${mins > 0 ? `${mins}m` : ''}`
  }
  return `${mins}min`
}

// Formater le poids
const formatWeight = (kg) => {
  if (!kg) return '0kg'
  return `${Math.round(kg)}kg`
}

// Formater la date
const formatDate = (dateString) => {
  if (!dateString) return ''
  return new Date(dateString).toLocaleDateString('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// Aller sur l'app
const goToApp = () => {
  window.location.href = '/register'
}

// Partager cette page
const shareThisPage = async () => {
  if (navigator.share) {
    try {
      await navigator.share({
        title: session.value?.workout?.title || 'Séance d\'entraînement',
        text: 'Regardez cette séance d\'entraînement ! 💪',
        url: window.location.href
      })
    } catch (err) {
      // L'utilisateur a annulé
    }
  } else {
    // Fallback : copier le lien
    await navigator.clipboard.writeText(window.location.href)
    alert('Lien copié !')
  }
}

// Meta tags pour Open Graph
useHead({
  title: `${session.value?.workout?.title || 'Séance'} - LastRep`,
  meta: [
    {
      property: 'og:title',
      content: `${session.value?.workout?.title || 'Séance d\'entraînement'} - LastRep`
    },
    {
      property: 'og:description',
      content: `Séance d'entraînement de ${session.value?.user?.username || 'un utilisateur'}`
    },
    {
      property: 'og:type',
      content: 'website'
    },
    {
      property: 'og:url',
      content: window.location.href
    }
  ]
})
</script>

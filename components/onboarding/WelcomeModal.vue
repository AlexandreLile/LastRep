<template>
  <Dialog :open="open" @update:open="handleOpenChange">
    <DialogContent class="max-w-2xl max-h-[90vh] overflow-hidden flex flex-col p-0">
      <!-- Header avec indicateur de progression -->
      <div class="px-6 pt-6 pb-4 border-b border-border">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-2xl font-bold text-foreground">Bienvenue sur LastRep ! 🎉</h2>
          <DialogClose asChild>
            <Button variant="ghost" size="icon" class="h-8 w-8">
              <X class="h-4 w-4" />
            </Button>
          </DialogClose>
        </div>
        
        <!-- Indicateur de progression -->
        <div class="flex items-center gap-2">
          <div 
            v-for="(slide, index) in slides" 
            :key="index"
            :class="[
              'h-2 flex-1 rounded-full transition-all duration-300',
              currentSlide >= index ? 'bg-primary' : 'bg-muted'
            ]"
          />
        </div>
        <p class="text-sm text-muted-foreground mt-2">
          {{ currentSlide + 1 }} / {{ slides.length }}
        </p>
      </div>

      <!-- Contenu des slides -->
      <div class="flex-1 overflow-y-auto px-6 py-6">
        <div class="min-h-[400px] flex flex-col items-center justify-center">
          <!-- Slide 1: Bienvenue -->
          <div v-if="currentSlide === 0" class="text-center space-y-6">
            <div class="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
              <span class="text-5xl">💪</span>
            </div>
            <div>
              <h3 class="text-2xl font-bold text-foreground mb-3">
                Bienvenue sur LastRep !
              </h3>
              <p class="text-muted-foreground text-lg max-w-md mx-auto">
                Votre compagnon d'entraînement pour suivre vos progrès et atteindre vos objectifs.
              </p>
            </div>
            <div class="bg-muted/50 rounded-lg p-4 max-w-md mx-auto">
              <p class="text-sm text-muted-foreground">
                En quelques minutes, découvrez comment utiliser LastRep pour optimiser vos entraînements.
              </p>
            </div>
          </div>

          <!-- Slide 2: Créer des séances -->
          <div v-if="currentSlide === 1" class="text-center space-y-6">
            <div class="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
              <Dumbbell class="w-12 h-12 text-primary" />
            </div>
            <div>
              <h3 class="text-2xl font-bold text-foreground mb-3">
                Créez vos séances d'entraînement
              </h3>
              <p class="text-muted-foreground text-lg max-w-md mx-auto mb-4">
                Organisez vos entraînements en créant des séances personnalisées.
              </p>
            </div>
            <div class="bg-muted/50 rounded-lg p-4 max-w-md mx-auto text-left space-y-3">
              <div class="flex items-start gap-3">
                <CheckCircle class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Donnez un nom</strong> à votre séance (ex: "Push Day", "Leg Day")
                </p>
              </div>
              <div class="flex items-start gap-3">
                <CheckCircle class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Ajoutez des exercices</strong> à votre séance
                </p>
              </div>
              <div class="flex items-start gap-3">
                <CheckCircle class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Réutilisez</strong> vos séances autant de fois que vous voulez
                </p>
              </div>
            </div>
          </div>

          <!-- Slide 3: Exercices -->
          <div v-if="currentSlide === 2" class="text-center space-y-6">
            <div class="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
              <ListChecks class="w-12 h-12 text-primary" />
            </div>
            <div>
              <h3 class="text-2xl font-bold text-foreground mb-3">
                Ajoutez et créez des exercices
              </h3>
              <p class="text-muted-foreground text-lg max-w-md mx-auto mb-4">
                Utilisez la bibliothèque d'exercices ou créez les vôtres.
              </p>
            </div>
            <div class="bg-muted/50 rounded-lg p-4 max-w-md mx-auto text-left space-y-3">
              <div class="flex items-start gap-3">
                <CheckCircle class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Bibliothèque complète</strong> : Choisissez parmi des centaines d'exercices
                </p>
              </div>
              <div class="flex items-start gap-3">
                <CheckCircle class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Exercices personnalisés</strong> : Créez vos propres exercices avec différents types de mesure (poids, temps, distance)
                </p>
              </div>
              <div class="flex items-start gap-3 bg-primary/5 rounded p-2">
                <Info class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Astuce :</strong> Les exercices que vous créez s'ajoutent automatiquement à votre liste et peuvent être réutilisés dans d'autres séances !
                </p>
              </div>
            </div>
          </div>

          <!-- Slide 4: Suivre sa progression -->
          <div v-if="currentSlide === 3" class="text-center space-y-6">
            <div class="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
              <TrendingUp class="w-12 h-12 text-primary" />
            </div>
            <div>
              <h3 class="text-2xl font-bold text-foreground mb-3">
                Suivez vos statistiques
              </h3>
              <p class="text-muted-foreground text-lg max-w-md mx-auto mb-4">
                Visualisez votre progression de différentes manières.
              </p>
            </div>
            <div class="bg-muted/50 rounded-lg p-4 max-w-md mx-auto text-left space-y-3">
              <div class="flex items-start gap-3">
                <BarChart3 class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Stats par séance</strong> : Nombre de séances, temps total, poids total soulevé
                </p>
              </div>
              <div class="flex items-start gap-3">
                <Activity class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Stats par exercice</strong> : Progression du poids, évolution des répétitions, graphiques détaillés
                </p>
              </div>
              <div class="flex items-start gap-3">
                <Calendar class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Calendrier</strong> : Visualisez vos entraînements sur un calendrier
                </p>
              </div>
              <div class="flex items-start gap-3">
                <Target class="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                <p class="text-sm text-muted-foreground">
                  <strong class="text-foreground">Objectifs mensuels</strong> : Fixez-vous des objectifs et suivez-les
                </p>
              </div>
            </div>
          </div>

          <!-- Slide 5: C'est parti ! -->
          <div v-if="currentSlide === 4" class="text-center space-y-6">
            <div class="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
              <span class="text-5xl">🚀</span>
            </div>
            <div>
              <h3 class="text-2xl font-bold text-foreground mb-3">
                C'est parti !
              </h3>
              <p class="text-muted-foreground text-lg max-w-md mx-auto mb-4">
                Vous êtes prêt à commencer votre parcours avec LastRep.
              </p>
            </div>
            <div class="bg-primary/10 rounded-lg p-6 max-w-md mx-auto space-y-4">
              <p class="text-sm text-foreground font-medium">
                Prochaines étapes recommandées :
              </p>
              <div class="text-left space-y-2">
                <div class="flex items-center gap-2">
                  <span class="text-primary font-bold">1.</span>
                  <span class="text-sm text-muted-foreground">Créez votre première séance</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="text-primary font-bold">2.</span>
                  <span class="text-sm text-muted-foreground">Ajoutez des exercices</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="text-primary font-bold">3.</span>
                  <span class="text-sm text-muted-foreground">Complétez votre première séance</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="text-primary font-bold">4.</span>
                  <span class="text-sm text-muted-foreground">Consultez vos statistiques</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer avec navigation -->
      <div class="px-6 py-4 border-t border-border flex items-center justify-between">
        <Button 
          v-if="currentSlide > 0"
          variant="outline" 
          @click="previousSlide"
        >
          <ChevronLeft class="h-4 w-4 mr-2" />
          Précédent
        </Button>
        <div v-else />

        <div class="flex items-center gap-2">
          <Button
            v-if="currentSlide < slides.length - 1"
            @click="nextSlide"
          >
            Suivant
            <ChevronRight class="h-4 w-4 ml-2" />
          </Button>
          <Button
            v-else
            @click="handleFinish"
          >
            Commencer
            <ArrowRight class="h-4 w-4 ml-2" />
          </Button>
        </div>
      </div>
    </DialogContent>
  </Dialog>
</template>

<script setup>
import { ref } from 'vue'
import { Dialog, DialogContent, DialogClose } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { 
  X, 
  ChevronLeft, 
  ChevronRight, 
  ArrowRight,
  Dumbbell,
  ListChecks,
  TrendingUp,
  BarChart3,
  Activity,
  Calendar,
  Target,
  CheckCircle,
  Info
} from 'lucide-vue-next'

const props = defineProps({
  open: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:open'])

// Watch pour déboguer
watch(() => props.open, (newVal) => {
  console.log('Props open changé:', newVal)
})

const currentSlide = ref(0)

const slides = [
  { title: 'Bienvenue' },
  { title: 'Créer des séances' },
  { title: 'Exercices' },
  { title: 'Statistiques' },
  { title: 'C\'est parti !' }
]

const nextSlide = () => {
  if (currentSlide.value < slides.length - 1) {
    currentSlide.value++
  }
}

const previousSlide = () => {
  if (currentSlide.value > 0) {
    currentSlide.value--
  }
}

const handleFinish = () => {
  // Marquer comme vu dans localStorage
  if (typeof window !== 'undefined') {
    localStorage.setItem('welcomeModalSeen', 'true')
  }
  emit('update:open', false)
}

const handleOpenChange = (open) => {
  if (!open) {
    // Si on ferme la modal, marquer comme vu
    if (typeof window !== 'undefined') {
      localStorage.setItem('welcomeModalSeen', 'true')
    }
  }
  emit('update:open', open)
}
</script>

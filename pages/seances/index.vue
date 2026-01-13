<template>
  <div class="relative">
    <!-- Header amélioré -->
    <div class="mb-8 bg-card rounded-xl p-6">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
          <Dumbbell class="h-6 w-6 text-primary" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-foreground">Séances d'entraînement</h2>
          <p class="text-sm text-muted-foreground">Créez et gérez vos programmes d'entraînement</p>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Left Column - Add Session and List -->
      <div class="lg:col-span-2 space-y-6">
        <!-- Add Session Card -->
        <div class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-start gap-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
              <Plus class="w-5 h-5 text-primary" />
            </div>
            <div class="flex-1">
              <div class="mb-4">
                <h3 class="text-lg font-semibold">Créer votre séance</h3>
                <p class="text-sm text-muted-foreground">Établissez un programme et suivez vos progrès.</p>
              </div>
              <Dialog>
                <DialogTrigger asChild>
                  <Button class="w-full sm:w-auto bg-primary hover:bg-primary/90">
                    <PlusCircle class="mr-2 h-4 w-4" /> Ajouter une séance
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogDescription>
                      <SessionsAddWorkoutSession></SessionsAddWorkoutSession>
                    </DialogDescription>
                  </DialogHeader>
                </DialogContent>
              </Dialog>
            </div>
          </div>
        </div>

        <!-- Sessions List -->
        <div class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <ListOrdered class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold">Mes séances</h3>
          </div>
          <SessionsWorkoutSessionList />
        </div>
      </div>

      <!-- Right Column - Stats -->
      <div class="space-y-6">
        <div class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
              <PieChart class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold">Répartition</h3>
          </div>
          <StatsSessionRepartition />
        </div>
        
        <!-- Section de conseils -->
        <div class="bg-primary/10 rounded-xl p-6 hover:shadow-md transition-all duration-300">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
              <Lightbulb class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold text-foreground">Conseils</h3>
          </div>
          <div class="space-y-4">
            <p class="text-sm text-muted-foreground">Pour une routine optimale, variez vos types d'exercices et alternez les groupes musculaires.</p>
            <div class="bg-card p-4 rounded-lg">
              <h4 class="font-medium text-sm mb-2">Programme idéal</h4>
              <ul class="text-xs text-muted-foreground space-y-1.5">
                <li class="flex items-center">
                  <CheckCircle2 class="h-3.5 w-3.5 mr-2 text-primary" />
                  3-4 séances par semaine
                </li>
                <li class="flex items-center">
                  <CheckCircle2 class="h-3.5 w-3.5 mr-2 text-primary" />
                  Alternez haut et bas du corps
                </li>
                <li class="flex items-center">
                  <CheckCircle2 class="h-3.5 w-3.5 mr-2 text-primary" />
                  Incluez des exercices composés
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTrigger } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { 
  Dumbbell, 
  Plus, 
  PlusCircle, 
  ListOrdered, 
  PieChart,
  Lightbulb,
  CheckCircle2
} from 'lucide-vue-next'
</script>

<style scoped>
.bg-primary\/10 {
  background-color: rgba(var(--primary), 0.1);
}

.bg-primary\/20 {
  background-color: rgba(var(--primary), 0.2);
}
</style> 
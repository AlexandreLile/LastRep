<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <h2 class="text-2xl font-semibold text-gray-900">Séances d'entraînement</h2>
    </div>

    <!-- Main Content -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Left Column - Add Session and List -->
      <div class="lg:col-span-2 space-y-8">
        <!-- Add Session Card -->
        <div class="bg-white rounded-xl p-6">
          <div class="flex flex-col space-y-4">
            <div>
              <h3 class="text-lg font-medium">Créer votre séance</h3>
              <p class="text-sm text-gray-500">Établissez un programme et suivez vos progrès.</p>
            </div>
            <div>
              <Dialog>
                <DialogTrigger asChild>
                  <Button class="w-full sm:w-auto">Ajouter une séance</Button>
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
        <div class="bg-white rounded-xl p-8">
          <SessionsWorkoutSessionList />
        </div>
      </div>

      <!-- Right Column - Stats -->
      <div class="space-y-8">
        <div class="bg-white rounded-xl">
          <StatsSessionRepartition />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTrigger } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
</script> 
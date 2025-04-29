<template>
    <div class="relative w-full rounded-2xl p-6">
    <div
      class="max-w-full py-10 sm:max-w-2xl lg:max-w-4xl md:items-start mx-auto flex flex-col justify-center items-start"
    >
      <h1 class="text-2xl sm:text-3xl md:text-4xl font-bold mb-4 text-left">
        Créer votre séance selon vos besoins 
      </h1>
      <p class="text-sm sm:text-base md:text-lg mb-4 opacity-90 text-left">
        Établissez un programme et suivez vos progrès.
      </p>
      <Dialog>
      <DialogTrigger as-child>
        <Button>Ajouter une séance</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogDescription>
            <SessionsAddWorkoutSession></SessionsAddWorkoutSession>
          </DialogDescription>
        </DialogHeader>
      </DialogContent> 
    </Dialog>
      <div class="w-full flex justify-center items-center mt-8">
        <div class="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-3 gap-4 w-full max-w-4xl">
          <div class="flex items-center justify-center bg-gray-100 p-4 rounded-lg">
            <div class="text-center">
              <p class="text-2xl font-bold text-primary">42</p>
              <p class="text-sm text-muted-foreground">Séances effectuées</p>
            </div>
          </div>

          <div class="flex items-center justify-center bg-gray-100 p-4 rounded-lg">
            <div class="text-center">
              <p class="text-2xl font-bold text-primary">12.5T</p>
              <p class="text-sm text-muted-foreground">Poids total soulevé</p>
            </div>
          </div>

          <div class="flex items-center justify-center bg-gray-100 p-4 rounded-lg">
            <div class="text-center">
              <p class="text-2xl font-bold text-primary">36h</p>
              <p class="text-sm text-muted-foreground">Temps d'entraînement</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
    
   
    <SessionsWorkoutSessionList />
  
</template>

<script setup>
</script> 
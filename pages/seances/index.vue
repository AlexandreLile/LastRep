<template>
    <div class="relative w-full rounded-2xl p-6">
      <div
        class="max-w-full py-10 sm:max-w-3xl lg:max-w-5xl xl:max-w-7xl md:items-start mx-auto flex flex-col justify-center items-start"
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
      </div>
    </div>
    <div class="relative w-full rounded-2xl p-6">
    <div class="max-w-full sm:max-w-3xl lg:max-w-5xl xl:max-w-7xl mx-auto ">
      <SessionsWorkoutSessionList />
    </div>
    <StatsSessionRepartition></StatsSessionRepartition>
    </div>
</template>

<script setup>
</script> 
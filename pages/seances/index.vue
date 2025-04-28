<template>
  <div>
    <h1>Seances</h1>
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
    <SessionsWorkoutSessionList />
  </div>
</template>

<script setup>
</script> 
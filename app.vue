<template>
  <div>
    <ClientOnly>
      <NuxtLayout>
        <NuxtPage />
      </NuxtLayout>
      <template #fallback>
        <div class="min-h-screen flex items-center justify-center bg-background">
          <div class="text-center">
            <h2 class="text-lg font-medium mb-2">Chargement de l'application...</h2>
            <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary mx-auto"></div>
          </div>
        </div>
      </template>
    </ClientOnly>
  </div>
</template>

<script setup>
// Forcer le mode client uniquement pour éviter les problèmes d'hydratation
definePageMeta({
  middleware: 'client-only'
})
</script>

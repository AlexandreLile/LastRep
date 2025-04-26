<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-100">
    <div class="w-full max-w-md p-8 bg-white rounded-2xl shadow-lg">
      <slot />
    </div>
  </div>
</template>

<script setup>
defineProps({});
</script>

<style scoped>
/* Tu peux ajouter un peu d'animation ou de transition si tu veux ici plus tard */
</style>

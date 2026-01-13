<template>
  <div class="min-h-screen bg-background">
    <div class="container mx-auto px-6 py-8">
      <slot />
    </div>
  </div>
</template>

<script setup>
defineOptions({
  name: 'StartSessionLayout'
})
</script> 
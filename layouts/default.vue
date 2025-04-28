<template>
  <header class="fixed top-0 left-0 right-0 w-full z-50  p-4">
    <div class="container mx-auto">
      <nav class="flex justify-center items-center">
        <ul class="flex items-center gap-6 bg-white rounded-full  shadow-lg">
          <li 
            :class="[
              'font-bold py-2 px-4 rounded-full transition-colors  border-solid border-2 border-white',
              currentPath === '/' ? 'bg-primary text-white' : ''
            ]"
          >
            <NuxtLink to="/">
              Accueil
            </NuxtLink>
          </li>
          <li 
            :class="[
              'font-bold py-2 px-4 rounded-full transition-colors border-solid border-2 border-white',
              currentPath === '/seances' ? 'bg-primary text-white' : ''
            ]"
          >
            <NuxtLink to="/seances">
              Séances
            </NuxtLink>
          </li>

          <li 
            :class="[
              'font-bold py-2 px-4 rounded-full transition-colors border-solid border-2 border-white',
              currentPath === '/exercices' ? 'bg-primary text-white' : ''
            ]"
          >
            <NuxtLink to="/exercices">
              Exercices
            </NuxtLink>
          </li>
        </ul>
      </nav>
    </div>
  </header>
  <main class="min-h-screen mt-16">
    
      <slot />
    
  </main>
</template>

<script setup>
import { useRoute } from 'vue-router'

const route = useRoute()
const currentPath = computed(() => route.path)
</script>
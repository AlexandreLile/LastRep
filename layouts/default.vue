<template>
  <!-- Mobile Menu Button -->
  <button 
    @click="isMenuOpen = !isMenuOpen"
    class="fixed top-4 right-4 z-50 p-2 rounded-lg bg-card shadow-sm border border-border md:hidden"
  >
    <Menu v-if="!isMenuOpen" class="w-6 h-6" />
    <X v-else class="w-6 h-6" />
  </button>

  <!-- Sidebar -->
  <div 
    class="fixed left-0 top-0 h-full w-64 bg-card/80 backdrop-blur-sm p-6 border-r border-border shadow-sm z-40 transition-transform duration-300 md:translate-x-0 flex flex-col"
    :class="[isMenuOpen ? 'translate-x-0' : '-translate-x-full']"
  >
    <div class="mb-8">
      <NuxtLink to="/" class="flex items-center" @click="closeMenuOnMobile">
        <img src="/logo.png" alt="LastRep" class="h-14 w-auto" loading="lazy" />
      </NuxtLink>
    </div>
    
    <nav class="space-y-4 flex-1">
      <NuxtLink 
        to="/" 
        class="flex items-center space-x-3 text-muted-foreground hover:text-foreground"
        :class="{ 'text-primary font-medium': currentPath === '/' }"
        @click="closeMenuOnMobile"
      >
        <LayoutDashboard class="w-5 h-5" />
        <span>Vue d'ensemble</span>
      </NuxtLink>

      <NuxtLink 
        to="/seances" 
        class="flex items-center space-x-3 text-muted-foreground hover:text-foreground"
        :class="{ 'text-primary font-medium': currentPath === '/seances' }"
        @click="closeMenuOnMobile"
      >
        <Timer class="w-5 h-5" />
        <span>Séances</span>
      </NuxtLink>

      <NuxtLink 
        to="/exercices" 
        class="flex items-center space-x-3 text-muted-foreground hover:text-foreground"
        :class="{ 'text-primary font-medium': currentPath === '/exercices' }"
        @click="closeMenuOnMobile"
      >
        <Dumbbell class="w-5 h-5" />
        <span>Exercices</span>
      </NuxtLink>

      <NuxtLink
        to="/cycles"
        class="flex items-center space-x-3 text-muted-foreground hover:text-foreground"
        :class="{ 'text-primary font-medium': currentPath.startsWith('/cycles') }"
        @click="closeMenuOnMobile"
      >
        <RotateCcw class="w-5 h-5" />
        <span>Cycles</span>
      </NuxtLink>

      <NuxtLink
        to="/profil"
        class="flex items-center space-x-3 text-muted-foreground hover:text-foreground"
        :class="{ 'text-primary font-medium': currentPath === '/profil' }"
        @click="closeMenuOnMobile"
      >
        <User class="w-5 h-5" />
        <span>Profil</span>
      </NuxtLink>
    </nav>

    <AlertDialog>
      <AlertDialogTrigger asChild>
        <Button variant="ghost" class="w-full justify-start text-muted-foreground hover:text-foreground">
          <LogOut class="w-5 h-5 mr-3" />
          Déconnexion
        </Button>
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Déconnexion</AlertDialogTitle>
          <AlertDialogDescription>
            Êtes-vous sûr de vouloir vous déconnecter ?
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Annuler</AlertDialogCancel>
          <AlertDialogAction @click="logout">Se déconnecter</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </div>

  <!-- Overlay pour fermer le menu sur mobile -->
  <div 
    v-if="isMenuOpen" 
    class="fixed inset-0 bg-black/20 backdrop-blur-sm z-30 md:hidden"
    @click="isMenuOpen = false"
  ></div>

  <main class="min-h-screen bg-background p-4 md:p-8 md:pl-72">
    <slot />
  </main>

</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { LayoutDashboard, Timer, Dumbbell, LogOut, Menu, X, User, RotateCcw } from 'lucide-vue-next'
import { useSupabaseClient } from '#imports'
import { Button } from '@/components/ui/button'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { clearCachedUser } from '~/utils/offlineTraining'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog'

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient()
const { setupOfflineSync } = usePerformedSession(supabase)

const currentPath = computed(() => route.path)
const isMenuOpen = ref(false)

const closeMenuOnMobile = () => {
  if (window.innerWidth < 768) { // 768px est le breakpoint md de Tailwind
    isMenuOpen.value = false
  }
}

const logout = async () => {
  try {
    await supabase.auth.signOut()
    // Effacer le cache utilisateur offline
    clearCachedUser()
    router.push('/login')
  } catch (error) {
    console.error('Erreur lors de la déconnexion:', error)
  }
}

onMounted(() => {
  setupOfflineSync()
})
</script>
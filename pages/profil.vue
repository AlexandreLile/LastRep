<template>
  <div class="relative">
    <!-- Header -->
    <div class="mb-8 bg-card rounded-xl p-6">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
          <User class="h-6 w-6 text-primary" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-foreground">Profil</h2>
          <p class="text-sm text-muted-foreground">Gérez vos informations personnelles et vos préférences</p>
        </div>
      </div>
    </div>

    <div class="mb-6 grid grid-cols-1 md:grid-cols-[1fr_16rem] gap-6 items-start max-w-3xl">
      <div class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300">
        <div class="flex items-center gap-3 mb-6">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <UserCog class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Informations personnelles</h3>
            <p class="text-sm text-muted-foreground">Modifiez vos informations de base</p>
          </div>
        </div>
        <form @submit.prevent="updateProfile" class="space-y-4">
          <div>
            <Label class="block mb-1 font-medium">Prénom</Label>
            <Input v-model="profile.first_name" type="text" class="w-full" />
          </div>
          <div>
            <Label class="block mb-1 font-medium">Nom</Label>
            <Input v-model="profile.last_name" type="text" class="w-full" />
          </div>
          <div>
            <Label class="block mb-1 font-medium">Email</Label>
            <Input v-model="profile.email" type="email" disabled class="w-full bg-muted" />
          </div>
          <div class="pt-2">
            <Button type="submit" :disabled="loading" class="flex items-center gap-2">
              <Save v-if="!loading" class="h-4 w-4" />
              <Loader2 v-else class="h-4 w-4 animate-spin" />
              {{ loading ? 'Enregistrement...' : 'Enregistrer' }}
            </Button>
            <div v-if="success" class="flex items-center gap-2 text-green-600 mt-3">
              <CheckCircle class="h-4 w-4" />
              <span>Profil mis à jour avec succès !</span>
            </div>
            <div v-if="error" class="flex items-center gap-2 text-red-600 mt-3">
              <AlertTriangle class="h-4 w-4" />
              <span>{{ error }}</span>
            </div>
          </div>
        </form>
      </div>

      <!-- Raccourcis -->
      <div class="grid grid-cols-2 md:grid-cols-1 gap-4">
        <NuxtLink
          to="/historique"
          class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300 flex items-center gap-3"
        >
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <History class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-base font-semibold">Historique</h3>
            <p class="text-sm text-muted-foreground">Vos séances passées</p>
          </div>
        </NuxtLink>

        <button
          @click="showWelcomeModal = true"
          class="bg-card rounded-xl p-6 hover:shadow-md transition-all duration-300 flex items-center gap-3 text-left"
        >
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <HelpCircle class="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 class="text-base font-semibold">Guide de démarrage</h3>
            <p class="text-sm text-muted-foreground">Revoir le guide d'introduction</p>
          </div>
        </button>
      </div>
    </div>

    <!-- Zone de danger - Suppression de compte -->
    <div class="bg-card rounded-xl p-6 max-w-lg mt-6 border border-destructive/20">
      <div class="flex items-center gap-3 mb-4">
        <div class="w-10 h-10 bg-destructive/10 rounded-full flex items-center justify-center">
          <AlertTriangle class="w-5 h-5 text-destructive" />
        </div>
        <div>
          <h3 class="text-lg font-semibold text-destructive">Zone de danger</h3>
          <p class="text-sm text-muted-foreground">Actions irréversibles sur votre compte</p>
        </div>
      </div>
      
      <div class="space-y-4">
        <div>
          <p class="text-sm text-muted-foreground mb-2">
            La suppression de votre compte entraînera la suppression définitive de toutes vos données :
          </p>
          <ul class="text-xs text-muted-foreground list-disc list-inside space-y-1 mb-4">
            <li>Toutes vos séances d'entraînement</li>
            <li>Toutes vos séries et performances</li>
            <li>Tous vos exercices personnalisés</li>
            <li>Toutes vos statistiques</li>
            <li>Votre compte et toutes vos données personnelles</li>
          </ul>
          <p class="text-xs text-destructive font-medium mb-4">
            ⚠️ Cette action est irréversible et ne peut pas être annulée.
          </p>
        </div>

        <AlertDialog>
          <AlertDialogTrigger asChild>
            <Button variant="destructive" class="w-full">
              <Trash2 class="h-4 w-4 mr-2" />
              Supprimer mon compte
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Confirmer la suppression du compte</AlertDialogTitle>
              <AlertDialogDescription>
                Êtes-vous absolument sûr de vouloir supprimer votre compte ? Cette action supprimera définitivement :
                <ul class="list-disc list-inside mt-2 space-y-1 text-sm">
                  <li>Toutes vos séances d'entraînement</li>
                  <li>Toutes vos séries et performances</li>
                  <li>Tous vos exercices personnalisés</li>
                  <li>Toutes vos statistiques</li>
                  <li>Votre compte et toutes vos données personnelles</li>
                </ul>
                <p class="mt-3 font-semibold text-destructive">
                  Cette action est irréversible et ne peut pas être annulée.
                </p>
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Annuler</AlertDialogCancel>
              <AlertDialogAction 
                @click="deleteAccount" 
                :disabled="deleting"
                class="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              >
                <Trash2 v-if="!deleting" class="h-4 w-4 mr-2" />
                <Loader2 v-else class="h-4 w-4 mr-2 animate-spin" />
                {{ deleting ? 'Suppression en cours...' : 'Oui, supprimer mon compte' }}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>
    </div>

    <!-- Modal de bienvenue -->
    <WelcomeModal v-model:open="showWelcomeModal" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'
import { useRouter } from 'vue-router'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import WelcomeModal from '@/components/onboarding/WelcomeModal.vue'
import {
  User,
  UserCog,
  Save,
  Loader2,
  CheckCircle,
  AlertTriangle,
  Trash2,
  History,
  HelpCircle
} from 'lucide-vue-next'
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

const supabase = useSupabaseClient()
const showWelcomeModal = ref(false)
const profile = ref({
  first_name: '',
  last_name: '',
  email: ''
})
const loading = ref(false)
const success = ref(false)
const error = ref('')
const deleting = ref(false)
const router = useRouter()

const loadProfile = async () => {
  loading.value = true
  error.value = ''
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Utilisateur non connecté')
    profile.value = {
      first_name: user.user_metadata?.first_name || '',
      last_name: user.user_metadata?.last_name || '',
      email: user.email || ''
    }
  } catch (e) {
    error.value = e.message || 'Erreur lors du chargement du profil'
  } finally {
    loading.value = false
  }
}

const updateProfile = async () => {
  loading.value = true
  error.value = ''
  success.value = false
  try {
    const updates = {
      data: {
        first_name: profile.value.first_name,
        last_name: profile.value.last_name,
        full_name: `${profile.value.first_name} ${profile.value.last_name}`.trim()
      }
    }
    const { error: updateError } = await supabase.auth.updateUser(updates)
    if (updateError) throw updateError
    success.value = true
  } catch (e) {
    error.value = e.message || 'Erreur lors de la mise à jour'
  } finally {
    loading.value = false
    setTimeout(() => { success.value = false }, 3000)
  }
}

const deleteAccount = async () => {
  deleting.value = true
  error.value = ''
  
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Utilisateur non connecté')
    
    const userId = user.id
    
    // Appeler la fonction SQL qui supprime toutes les données en cascade
    const { error: deleteError } = await supabase.rpc('delete_user_account', {
      user_uuid: userId
    })
    
    if (deleteError) {
      throw new Error(deleteError.message || 'Erreur lors de la suppression des données')
    }
    
    // Déconnexion de l'utilisateur
    await supabase.auth.signOut()
    
    // Redirection vers la page de login avec un message
    router.push({
      path: '/login',
      query: { deleted: 'true' }
    })
    
  } catch (e) {
    console.error('Erreur lors de la suppression du compte:', e)
    error.value = e.message || 'Une erreur est survenue lors de la suppression de votre compte. Veuillez réessayer ou contacter le support.'
    deleting.value = false
  }
}

onMounted(loadProfile)
</script>

<style scoped>
.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style> 
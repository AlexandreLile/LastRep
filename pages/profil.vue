<template>
  <div class="relative">
    <!-- Header -->
    <div class="mb-8 bg-white rounded-xl p-6">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
          <User class="h-6 w-6 text-primary" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Profil</h2>
          <p class="text-sm text-muted-foreground">Gérez vos informations personnelles et vos préférences</p>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-xl p-6 max-w-lg hover:shadow-md transition-all duration-300">
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
          <Input v-model="profile.email" type="email" disabled class="w-full bg-gray-50" />
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
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSupabaseClient } from '#imports'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { 
  User, 
  UserCog, 
  Save, 
  Loader2, 
  CheckCircle, 
  AlertTriangle 
} from 'lucide-vue-next'

const supabase = useSupabaseClient()
const profile = ref({
  first_name: '',
  last_name: '',
  email: ''
})
const loading = ref(false)
const success = ref(false)
const error = ref('')

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
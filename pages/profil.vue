<template>
  <div>
    <!-- Header -->
    <div class="mb-8">
      <h2 class="text-2xl font-semibold text-gray-900">Profil</h2>
      <p class="text-sm text-muted-foreground mt-1">
        Gérez vos informations personnelles et vos préférences
      </p>
    </div>

    <div class="bg-white rounded-xl p-6 max-w-lg">
      <form @submit.prevent="updateProfile" class="space-y-4">
        <div>
          <Label class="block mb-1">Prénom</Label>
          <Input v-model="profile.first_name" type="text" />
        </div>
        <div>
          <Label class="block mb-1">Nom</Label>
          <Input v-model="profile.last_name" type="text" />
        </div>
        <div>
          <Label class="block mb-1">Email</Label>
          <Input v-model="profile.email" type="email" disabled />
        </div>
        <div>
          <Button type="submit" :disabled="loading">
            {{ loading ? 'Enregistrement...' : 'Enregistrer' }}
          </Button>
          <span v-if="success" class="text-green-600 ml-4">Profil mis à jour !</span>
          <span v-if="error" class="text-red-600 ml-4">{{ error }}</span>
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
    setTimeout(() => { success.value = false }, 2000)
  }
}

onMounted(loadProfile)
</script> 
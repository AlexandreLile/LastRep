<template>
  <div class="relative min-h-screen p-6">
    <!-- Header -->
    <div class="mb-8 bg-card rounded-xl p-6 border border-yellow-500/20">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-yellow-500/10 rounded-full flex items-center justify-center">
          <Shield class="h-6 w-6 text-yellow-600" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-foreground">Dashboard Admin</h2>
          <p class="text-sm text-muted-foreground">
            Gestion des utilisateurs
            <span class="ml-2 px-2 py-1 bg-yellow-500/10 text-yellow-600 text-xs rounded">
              LOCAL ONLY
            </span>
          </p>
        </div>
      </div>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-6 gap-4 mb-6">
      <div class="bg-card rounded-xl p-4 border">
        <div class="text-sm text-muted-foreground">Total utilisateurs</div>
        <div class="text-2xl font-bold mt-1">{{ users.length }}</div>
      </div>
      <div class="bg-card rounded-xl p-4 border">
        <div class="text-sm text-muted-foreground">Comptes actifs</div>
        <div class="text-2xl font-bold mt-1">{{ activeUsers }}</div>
      </div>
      <div class="bg-card rounded-xl p-4 border">
        <div class="text-sm text-muted-foreground">Emails confirmés</div>
        <div class="text-2xl font-bold mt-1">{{ confirmedUsers }}</div>
      </div>
      <div class="bg-card rounded-xl p-4 border">
        <div class="text-sm text-muted-foreground">Comptes supprimés</div>
        <div class="text-2xl font-bold mt-1 text-orange-600">{{ deletedUsers }}</div>
      </div>
      <div class="bg-card rounded-xl p-4 border">
        <div class="text-sm text-muted-foreground">Séances créées</div>
        <div class="text-2xl font-bold mt-1">{{ totalWorkoutSessions }}</div>
      </div>
      <div class="bg-card rounded-xl p-4 border">
        <div class="text-sm text-muted-foreground">Séances effectuées</div>
        <div class="text-2xl font-bold mt-1">{{ totalPerformedSessions }}</div>
      </div>
    </div>

    <!-- Table des utilisateurs -->
    <div class="bg-card rounded-xl border">
      <div class="p-6 border-b">
        <div class="flex items-center justify-between">
          <h3 class="text-lg font-semibold">Liste des utilisateurs</h3>
          <Button 
            @click="loadUsers" 
            :disabled="loading"
            variant="outline"
            size="sm"
          >
            <RefreshCw v-if="!loading" class="h-4 w-4 mr-2" />
            <Loader2 v-else class="h-4 w-4 mr-2 animate-spin" />
            Actualiser
          </Button>
        </div>
      </div>

      <div v-if="loading && users.length === 0" class="p-12 text-center">
        <Loader2 class="h-8 w-8 animate-spin mx-auto text-muted-foreground" />
        <p class="mt-4 text-muted-foreground">Chargement des utilisateurs...</p>
      </div>

      <div v-else-if="error" class="p-6">
        <div class="flex items-center gap-2 text-destructive bg-destructive/10 p-4 rounded-lg">
          <AlertTriangle class="h-5 w-5" />
          <span>{{ error }}</span>
        </div>
      </div>

      <div v-else-if="users.length === 0" class="p-12 text-center">
        <Users class="h-12 w-12 mx-auto text-muted-foreground mb-4" />
        <p class="text-muted-foreground">Aucun utilisateur trouvé</p>
      </div>

      <div v-else class="overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Email</TableHead>
              <TableHead>Prénom</TableHead>
              <TableHead>Nom</TableHead>
              <TableHead>Nom complet</TableHead>
              <TableHead>Séances créées</TableHead>
              <TableHead>Séances effectuées</TableHead>
              <TableHead>Inscription</TableHead>
              <TableHead>Dernière connexion</TableHead>
              <TableHead>Statut</TableHead>
              <TableHead>Compte supprimé</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="user in users" :key="user.id">
              <TableCell class="font-medium">{{ user.email }}</TableCell>
              <TableCell>{{ user.first_name || '-' }}</TableCell>
              <TableCell>{{ user.last_name || '-' }}</TableCell>
              <TableCell>{{ user.full_name }}</TableCell>
              <TableCell>
                <span class="font-medium">{{ user.workout_sessions_count || 0 }}</span>
              </TableCell>
              <TableCell>
                <span class="font-medium">{{ user.performed_sessions_count || 0 }}</span>
              </TableCell>
              <TableCell>
                <span v-if="user.created_at" class="text-sm text-muted-foreground">
                  {{ formatDate(user.created_at) }}
                </span>
                <span v-else>-</span>
              </TableCell>
              <TableCell>
                <span v-if="user.last_sign_in_at" class="text-sm text-muted-foreground">
                  {{ formatDate(user.last_sign_in_at) }}
                </span>
                <span v-else class="text-muted-foreground">Jamais</span>
              </TableCell>
              <TableCell>
                <div class="flex items-center gap-2">
                  <span 
                    v-if="user.is_active" 
                    class="px-2 py-1 bg-green-500/10 text-green-600 text-xs rounded"
                  >
                    Actif
                  </span>
                  <span 
                    v-else 
                    class="px-2 py-1 bg-red-500/10 text-red-600 text-xs rounded"
                  >
                    Inactif
                  </span>
                  <span 
                    v-if="user.email_confirmed_at" 
                    class="px-2 py-1 bg-blue-500/10 text-blue-600 text-xs rounded"
                    title="Email confirmé"
                  >
                    ✓
                  </span>
                </div>
              </TableCell>
              <TableCell>
                <div v-if="user.is_deleted" class="flex flex-col gap-1">
                  <span class="px-2 py-1 bg-orange-500/10 text-orange-600 text-xs rounded font-medium">
                    Supprimé
                  </span>
                  <span v-if="user.deleted_at" class="text-xs text-muted-foreground">
                    {{ formatDate(user.deleted_at) }}
                  </span>
                </div>
                <span v-else class="text-muted-foreground text-sm">-</span>
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </div>
    </div>

    <!-- Avertissement de sécurité -->
    <div class="mt-6 bg-yellow-500/10 border border-yellow-500/20 rounded-xl p-4">
      <div class="flex items-start gap-3">
        <AlertTriangle class="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
        <div class="text-sm">
          <p class="font-semibold text-yellow-600 mb-1">⚠️ Dashboard Admin - Local uniquement</p>
          <p class="text-muted-foreground">
            Ce dashboard est uniquement accessible en développement local. 
            Il est automatiquement bloqué en production pour des raisons de sécurité.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { 
  Shield, 
  RefreshCw, 
  Loader2, 
  AlertTriangle,
  Users
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'

// Middleware admin (bloque en production)
definePageMeta({
  middleware: 'admin'
})

const users = ref([])
const loading = ref(false)
const error = ref('')

const activeUsers = computed(() => {
  return users.value.filter(u => u.is_active).length
})

const confirmedUsers = computed(() => {
  return users.value.filter(u => u.email_confirmed_at).length
})

const totalWorkoutSessions = computed(() => {
  return users.value.reduce((sum, user) => sum + (user.workout_sessions_count || 0), 0)
})

const totalPerformedSessions = computed(() => {
  return users.value.reduce((sum, user) => sum + (user.performed_sessions_count || 0), 0)
})

const deletedUsers = computed(() => {
  return users.value.filter(u => u.is_deleted).length
})

const formatDate = (dateString) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

const loadUsers = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const response = await $fetch('/api/admin/users')
    
    if (response.success) {
      users.value = response.users || []
    } else {
      throw new Error('Erreur lors du chargement des utilisateurs')
    }
  } catch (e) {
    console.error('Error loading users:', e)
    error.value = e.message || 'Erreur lors du chargement des utilisateurs'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadUsers()
})
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

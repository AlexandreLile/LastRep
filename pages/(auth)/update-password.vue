<template>
  <div class="flex min-h-screen items-center justify-center p-4">
    <Card class="w-full max-w-md p-6 space-y-6">
      <h1 class="text-2xl font-bold text-center">
        Définir un nouveau mot de passe
      </h1>

      <form
        v-if="!success"
        @submit.prevent="handleUpdatePassword"
        class="space-y-4"
      >
        <div class="grid gap-2">
          <Label for="password">Nouveau mot de passe</Label>
          <div class="relative">
            <Input 
              id="password" 
              :type="showPassword ? 'text' : 'password'" 
              v-model="newPassword" 
              required 
              class="pr-10"
            />
            <button
              type="button"
              @click="showPassword = !showPassword"
              class="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
              tabindex="-1"
            >
              <Eye v-if="!showPassword" class="h-4 w-4" />
              <EyeOff v-else class="h-4 w-4" />
            </button>
          </div>
          <p class="text-xs text-muted-foreground">
            Le mot de passe doit contenir au moins 6 caractères
          </p>
        </div>

        <Button type="submit" class="w-full" :disabled="loading">
          {{ loading ? "Mise à jour..." : "Mettre à jour" }}
        </Button>

        <p v-if="error" class="text-red-500 text-center mt-2">{{ error }}</p>
      </form>

      <div v-else class="text-center space-y-4">
        <p class="text-green-600">Mot de passe mis à jour avec succès ✅</p>
        <Button @click="router.push('/login')" class="w-full">
          Retour à la connexion
        </Button>
      </div>
    </Card>
  </div>
</template>

<script setup>
import { onMounted } from "vue";
import { Eye, EyeOff } from 'lucide-vue-next';

definePageMeta({
  layout: false,
  middleware: [] // Pas de middleware pour permettre l'accès avec le hash de réinitialisation
});

const supabase = useSupabaseClient();
const router = useRouter();

const newPassword = ref("");
const loading = ref(false);
const success = ref(false);
const error = ref("");
const showPassword = ref(false);

const handleUpdatePassword = async () => {
  loading.value = true;
  error.value = "";

  try {
    const { error: updateError } = await supabase.auth.updateUser({
      password: newPassword.value,
    });

    if (updateError) {
      throw updateError;
    }

    success.value = true;
  } catch (err) {
    error.value = err.message || "Une erreur est survenue";
  } finally {
    loading.value = false;
  }
};

// Check la session au montage de la page
onMounted(async () => {
  try {
    // Vérifier si on arrive depuis un lien de réinitialisation (avec hash)
    const hash = typeof window !== 'undefined' ? window.location.hash : '';
    const hasRecoveryHash = hash.includes('access_token') || hash.includes('type=recovery');
    
    // Si on a un hash de réinitialisation, laisser Supabase le gérer
    if (hasRecoveryHash) {
      console.log("Hash de réinitialisation détecté, traitement en cours...");
      // Attendre un peu pour que Supabase traite le hash
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Supabase va automatiquement traiter le hash et créer une session
      const { data: { session }, error: sessionError } = await supabase.auth.getSession();
      
      if (sessionError) {
        console.error('Erreur lors de la récupération de la session:', sessionError);
        error.value = "Le lien de réinitialisation est invalide ou a expiré";
        setTimeout(() => router.push("/reset-password"), 3000);
        return;
      }
      
      if (!session) {
        console.log("Pas de session après traitement du hash, redirection vers /reset-password");
        error.value = "Le lien de réinitialisation est invalide ou a expiré";
        setTimeout(() => router.push("/reset-password"), 3000);
        return;
      }
      
      console.log("Session recovery créée avec succès");
      return;
    }
    
    // Sinon, vérifier la session normale
    const { data } = await supabase.auth.getSession();

    if (!data.session) {
      console.log("Pas de session active, redirection vers /reset-password");
      router.push("/reset-password");
    } else {
      // Vérifier si c'est une session de réinitialisation
      // Les sessions de réinitialisation sont créées via le hash, donc si on a une session sans hash, c'est probablement une session normale
      const hashCheck = typeof window !== 'undefined' ? window.location.hash : '';
      const isRecoverySession = hashCheck.includes('type=recovery');
      
      if (!isRecoverySession && data.session.user?.email_confirmed_at) {
        // Si l'utilisateur est connecté normalement, pas en reset
        console.log("Session normale détectée, redirection vers /");
        router.push("/");
      } else {
        console.log("Session recovery détectée, accès autorisé");
      }
    }
  } catch (err) {
    console.error('Erreur lors de la vérification de la session:', err);
    error.value = "Une erreur est survenue";
    setTimeout(() => router.push("/reset-password"), 3000);
  }
});
</script>

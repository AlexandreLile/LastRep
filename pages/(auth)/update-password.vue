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
    // Vérifier qu'on a bien une session avant de mettre à jour
    const { data: { session } } = await supabase.auth.getSession();
    
    if (!session) {
      error.value = "Votre session a expiré. Veuillez refaire une demande de réinitialisation.";
      setTimeout(() => router.push("/reset-password"), 3000);
      return;
    }

    const { error: updateError } = await supabase.auth.updateUser({
      password: newPassword.value,
    });

    if (updateError) {
      throw updateError;
    }

    // Déconnecter l'utilisateur après la mise à jour du mot de passe
    // pour qu'il se reconnecte avec son nouveau mot de passe
    await supabase.auth.signOut();
    
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
      
      // Nettoyer le hash de l'URL pour éviter les problèmes
      if (typeof window !== 'undefined') {
        window.history.replaceState(null, '', window.location.pathname);
      }
      
      console.log("Session recovery créée avec succès, restons sur la page");
      return;
    }
    
    // Sinon, vérifier la session normale
    const { data } = await supabase.auth.getSession();

    if (!data.session) {
      console.log("Pas de session active, redirection vers /reset-password");
      router.push("/reset-password");
    } else {
      // Si on arrive ici sans hash mais avec une session, c'est probablement une session normale
      // Rediriger vers la page d'accueil sauf si c'est vraiment une session de réinitialisation
      // On peut détecter une session de réinitialisation en vérifiant si l'utilisateur vient juste de recevoir un email de réinitialisation
      // Mais comme on n'a pas cette info, on va plutôt vérifier si l'utilisateur peut accéder à cette page
      // En fait, si on est sur cette page sans hash, c'est qu'on ne devrait pas y être
      console.log("Session détectée sans hash de réinitialisation, redirection vers /");
      router.push("/");
    }
  } catch (err) {
    console.error('Erreur lors de la vérification de la session:', err);
    error.value = "Une erreur est survenue";
    setTimeout(() => router.push("/reset-password"), 3000);
  }
});
</script>

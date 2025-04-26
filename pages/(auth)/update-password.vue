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
          <Input id="password" type="password" v-model="newPassword" required />
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

const supabase = useSupabaseClient();
const router = useRouter();

const newPassword = ref("");
const loading = ref(false);
const success = ref(false);
const error = ref("");

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
  const { data } = await supabase.auth.getSession();

  if (!data.session) {
    console.log("Pas de session active, redirection vers /login");
    router.push("/login");
  } else if (
    data.session.user?.email_confirmed_at &&
    !data.session.user?.recovery_sent_at
  ) {
    // Si l'utilisateur est connecté normalement, pas en reset
    console.log("Session normale détectée, redirection vers /login");
    router.push("/");
  } else {
    console.log("Session recovery détectée, accès autorisé");
  }
});
</script>

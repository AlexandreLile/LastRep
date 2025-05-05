<template>
  <div class="flex min-h-screen items-center justify-center p-4">
    <Card class="w-full max-w-md p-6 space-y-6">
      <h1 class="text-2xl font-bold text-center">
        Réinitialiser votre mot de passe
      </h1>

      <div v-if="!emailSent">
        <form @submit.prevent="handleResetPassword" class="space-y-4">
          <div class="grid gap-2">
            <Label for="email">Email</Label>
            <Input id="email" type="email" v-model="email" required />
          </div>

          <Button type="submit" class="w-full" :disabled="loading">
            {{
              loading
                ? "Envoi en cours..."
                : "Envoyer le lien de réinitialisation"
            }}
          </Button>
        </form>
      </div>

      <div v-else class="text-center">
        <p class="text-green-600">
          Un email de réinitialisation a été envoyé à votre adresse ✅
        </p>
        <Button class="mt-4 w-full" @click="router.push('/login')">
          Retour à la connexion
        </Button>
      </div>

      <p v-if="error" class="text-red-500 text-center">{{ error }}</p>
    </Card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false,
  middleware: ["auth"]
});

const supabase = useSupabaseClient();
const router = useRouter();

const email = ref("");
const loading = ref(false);
const emailSent = ref(false);
const error = ref("");

const handleResetPassword = async () => {
  loading.value = true;
  error.value = "";
  try {
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(
      email.value,
      {
        redirectTo: `${window.location.origin}/update-password`,
      }
    );

    if (resetError) {
      throw resetError;
    }

    emailSent.value = true;
  } catch (err: any) {
    error.value = err.message || "Une erreur est survenue";
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div class="h-screen flex items-center justify-center w-full">
    <Card class="mx-auto max-w-sm w-full">
      <form @submit.prevent="onSubmit">
        <CardHeader class="pb-2">
          <CardTitle class="text-2xl">Inscription</CardTitle>
        </CardHeader>

        <CardContent>
          <div class="grid gap-4">
            <div class="grid gap-2">
              <Label for="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="votre@email.com"
                required
                v-model="email"
              />
            </div>

            <div class="grid gap-2">
              <Label for="password">Mot de passe</Label>
              <Input
                id="password"
                type="password"
                placeholder="Votre mot de passe"
                required
                v-model="password"
              />
            </div>

            <Button type="submit" class="w-full">Créer un compte</Button>
            <Button variant="outline" class="w-full" @click="handleGoogleLogin">
              Continuer avec Google
            </Button>

            <div
              v-if="errorMessage"
              class="text-red-500 text-sm text-center mt-2"
            >
              {{ errorMessage }}
            </div>
          </div>

          <div class="mt-4 text-center text-sm">
            Déjà un compte ?
            <NuxtLink
              class="ml-auto inline-block text-sm underline"
              to="/login"
            >
              Se connecter
            </NuxtLink>
          </div>
        </CardContent>
      </form>
    </Card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false,
});
import { useAuth } from "@/composables/useAuth";

const { email, password, handleRegister, handleGoogleLogin, errorMessage } = useAuth();

const onSubmit = () => {
  handleRegister();
};
</script>

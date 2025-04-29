<template>
  <div class="h-screen flex items-center justify-center w-full">
    <Card class="mx-auto max-w-sm w-full">
      <form @submit.prevent="onSubmit">
        <CardHeader class="pb-2">
          <CardTitle class="text-2xl">Connexion</CardTitle>
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
              <div class="flex items-center">
                <Label for="password">Mot de passe</Label>
                <NuxtLink
                  class="ml-auto inline-block text-sm underline"
                  to="/reset-password"
                >
                  Mot de passe oublié ?
                </NuxtLink>
              </div>
              <Input
                id="password"
                type="password"
                required
                v-model="password"
              />
            </div>

            <Button type="submit" class="w-full">Se connecter</Button>
            <Button variant="outline" type="button" class="w-full" @click="handleGoogleLogin">
              Connexion avec Google
            </Button>

            <div
              v-if="errorMessage"
              class="text-red-500 text-sm text-center mt-2"
            >
              {{ errorMessage }}
            </div>
          </div>

          <div class="mt-4 text-center text-sm">
            Pas encore de compte ?
            <NuxtLink
              class="ml-auto inline-block text-sm underline"
              to="/register"
            >
              Inscription
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

const { email, password, handleLogin, handleGoogleLogin, errorMessage } = useAuth();

const onSubmit = () => {
  handleLogin();
};
</script>

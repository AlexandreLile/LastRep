<template>
  <Card class="mx-auto max-w-sm">
    <form @submit="onSubmit">
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
              <a href="#" class="ml-auto inline-block text-sm underline">
                Mot de passe oublié ?
              </a>
            </div>
            <Input id="password" type="password" required v-model="password" />
          </div>

          <Button type="submit" class="w-full">Se connecter</Button>
          <Button variant="outline" class="w-full"
            >Connexion avec Google</Button
          >

          <div
            v-if="errorMessage"
            class="text-red-500 text-sm text-center mt-2"
          >
            {{ errorMessage }}
          </div>
        </div>

        <div class="mt-4 text-center text-sm">
          Pas encore de compte ?
          <a href="#" class="underline">S'inscrire</a>
        </div>
      </CardContent>
    </form>
  </Card>
</template>

<script setup lang="ts">
import { useAuth } from "@/composables/useAuth";

const { email, password, handleLogin, errorMessage } = useAuth();

const onSubmit = (e: Event) => {
  e.preventDefault();
  handleLogin();
};
</script>

<template>
  <div class="min-h-screen flex items-center justify-center w-full bg-gray-50 p-4 sm:p-6 md:p-10">
    <div class="max-w-md w-full mx-auto">
      <!-- Logo et en-tête -->
      <div class="text-center mb-8">
        <div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
          <LockKeyhole class="h-8 w-8 text-primary" />
        </div>
        <h1 class="text-2xl font-bold text-gray-900">LastRep</h1>
        <p class="text-sm text-muted-foreground mt-2">Connectez-vous pour accéder à votre espace d'entraînement</p>
      </div>

      <Card class="border border-gray-200 shadow-sm">
        <form @submit.prevent="onSubmit">
          <CardHeader class="pb-2">
            <CardTitle class="text-xl font-semibold">Connexion</CardTitle>
            <CardDescription>
              Entrez vos identifiants pour accéder à votre compte
            </CardDescription>
          </CardHeader>

          <CardContent>
            <div class="grid gap-4">
              <div class="grid gap-2">
                <Label for="email" class="font-medium">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="votre@email.com"
                  required
                  v-model="email"
                  class="h-10"
                />
              </div>

              <div class="grid gap-2">
                <div class="flex items-center">
                  <Label for="password" class="font-medium">Mot de passe</Label>
                  <NuxtLink
                    class="ml-auto inline-block text-sm text-primary hover:underline"
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
                  class="h-10"
                />
              </div>

              <Button type="submit" class="w-full h-10 mt-2">
                <LogIn v-if="!loading" class="h-4 w-4 mr-2" />
                <Loader2 v-else class="h-4 w-4 mr-2 animate-spin" />
                Se connecter
              </Button>
              
              <div class="relative my-2">
                <div class="absolute inset-0 flex items-center">
                  <span class="w-full border-t border-gray-200"></span>
                </div>
                <div class="relative flex justify-center text-xs">
                  <span class="bg-white px-2 text-muted-foreground">ou continuer avec</span>
                </div>
              </div>
              
              <Button variant="outline" type="button" class="w-full h-10" @click="handleGoogleLogin">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" viewBox="0 0 24 24"><path fill="#EA4335" d="M5.266 9.765A7.077 7.077 0 0 1 12 4.909c1.69 0 3.218.6 4.418 1.582L19.91 3C17.782 1.145 15.055 0 12 0 7.27 0 3.198 2.698 1.24 6.65l4.026 3.115Z"/><path fill="#34A853" d="M16.04 18.013c-1.09.703-2.474 1.078-4.04 1.078a7.077 7.077 0 0 1-6.723-4.823l-4.04 3.067A11.965 11.965 0 0 0 12 24c2.933 0 5.735-1.043 7.834-3l-3.793-2.987Z"/><path fill="#4A90E2" d="M19.834 21c2.195-2.048 3.62-5.096 3.62-9 0-.71-.109-1.473-.272-2.182H12v4.637h6.436c-.317 1.559-1.17 2.766-2.395 3.558L19.834 21Z"/><path fill="#FBBC05" d="M5.277 14.268A7.12 7.12 0 0 1 4.909 12c0-.782.125-1.533.357-2.235L1.24 6.65A11.934 11.934 0 0 0 0 12c0 1.92.445 3.73 1.237 5.335l4.04-3.067Z"/></svg>
                Connexion avec Google
              </Button>

              <div
                v-if="errorMessage"
                class="text-red-500 text-sm p-2 rounded-md bg-red-50 border border-red-200 mt-4"
              >
                <div class="flex items-center">
                  <AlertTriangle class="h-4 w-4 mr-2 text-red-500" />
                  {{ errorMessage }}
                </div>
              </div>
            </div>

            <div class="mt-6 text-center text-sm">
              Pas encore de compte ?
              <NuxtLink
                class="text-primary font-medium hover:underline"
                to="/register"
              >
                Inscription
              </NuxtLink>
            </div>
          </CardContent>
        </form>
      </Card>
    </div>
  </div>
</template>

<script setup >
definePageMeta({
  layout: false,
  middleware: ["auth"]
});
import { useAuth } from "@/composables/useAuth";
import { LogIn, LockKeyhole, Loader2, AlertTriangle } from 'lucide-vue-next';

const { email, password, handleLogin, handleGoogleLogin, errorMessage, loading } = useAuth();

const onSubmit = () => {
  handleLogin();
};
</script>

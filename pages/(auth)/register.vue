<template>
  <div class="min-h-screen flex items-center justify-center w-full bg-background p-4 sm:p-6 md:p-10">
    <div class="max-w-md w-full mx-auto">
      <!-- Logo et en-tête -->
      <div class="text-center mb-8">
        <img src="/logo.png" alt="LastRep" class="h-16 w-auto mx-auto mb-4" loading="eager" />
        <p class="text-sm text-muted-foreground">Créez votre compte pour commencer à suivre vos entraînements</p>
      </div>
      
      <Card class="border border-border shadow-sm">
        <form @submit.prevent="onSubmit">
          <CardHeader class="pb-2">
            <CardTitle class="text-xl font-semibold">Inscription</CardTitle>
            <CardDescription>
              Créez un compte pour commencer à utiliser LastRep
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
                  @blur="checkEmailFormat"
                  :class="[
                    'h-10',
                    emailError ? 'border-red-300 focus:border-red-500' : ''
                  ]"
                />
                <p v-if="emailError" class="text-xs text-red-500 flex items-center gap-1">
                  <AlertTriangle class="h-3 w-3" />
                  {{ emailError }}
                </p>
              </div>

              <div class="grid gap-2">
                <Label for="password" class="font-medium">Mot de passe</Label>
                <div class="relative">
                  <Input
                    id="password"
                    :type="showPassword ? 'text' : 'password'"
                    placeholder="Votre mot de passe"
                    required
                    v-model="password"
                    class="h-10 pr-10"
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

              <div class="flex items-start gap-2 mt-2">
                <input
                  id="accept-terms"
                  type="checkbox"
                  v-model="acceptTerms"
                  class="mt-1 h-4 w-4 rounded border-border text-primary focus:ring-primary focus:ring-offset-0 cursor-pointer"
                  :class="termsError ? 'border-red-500' : ''"
                />
                <label for="accept-terms" class="text-sm text-foreground cursor-pointer leading-relaxed">
                  J'ai lu et j'accepte les 
                  <NuxtLink to="/cgu" target="_blank" class="text-primary hover:underline font-medium">
                    Conditions Générales d'Utilisation
                  </NuxtLink>
                  et la 
                  <NuxtLink to="/politique-confidentialite" target="_blank" class="text-primary hover:underline font-medium">
                    Politique de confidentialité
                  </NuxtLink>
                </label>
              </div>
              <p v-if="termsError" class="text-xs text-red-500 flex items-center gap-1">
                <AlertTriangle class="h-3 w-3" />
                {{ termsError }}
              </p>

              <Button type="submit" class="w-full h-10 mt-2" :disabled="!acceptTerms">
                <CheckCircle v-if="!loading" class="h-4 w-4 mr-2" />
                <Loader2 v-else class="h-4 w-4 mr-2 animate-spin" />
                Créer un compte
              </Button>
              
              <div class="relative my-2">
                <div class="absolute inset-0 flex items-center">
                  <span class="w-full border-t border-border"></span>
                </div>
                <div class="relative flex justify-center text-xs">
                  <span class="bg-card px-2 text-muted-foreground">ou continuer avec</span>
                </div>
              </div>
              
              <Button variant="outline" class="w-full h-10" @click="handleGoogleLoginWithTerms" :disabled="!acceptTerms">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" viewBox="0 0 24 24"><path fill="#EA4335" d="M5.266 9.765A7.077 7.077 0 0 1 12 4.909c1.69 0 3.218.6 4.418 1.582L19.91 3C17.782 1.145 15.055 0 12 0 7.27 0 3.198 2.698 1.24 6.65l4.026 3.115Z"/><path fill="#34A853" d="M16.04 18.013c-1.09.703-2.474 1.078-4.04 1.078a7.077 7.077 0 0 1-6.723-4.823l-4.04 3.067A11.965 11.965 0 0 0 12 24c2.933 0 5.735-1.043 7.834-3l-3.793-2.987Z"/><path fill="#4A90E2" d="M19.834 21c2.195-2.048 3.62-5.096 3.62-9 0-.71-.109-1.473-.272-2.182H12v4.637h6.436c-.317 1.559-1.17 2.766-2.395 3.558L19.834 21Z"/><path fill="#FBBC05" d="M5.277 14.268A7.12 7.12 0 0 1 4.909 12c0-.782.125-1.533.357-2.235L1.24 6.65A11.934 11.934 0 0 0 0 12c0 1.92.445 3.73 1.237 5.335l4.04-3.067Z"/></svg>
                Continuer avec Google
              </Button>
              <p class="text-xs text-muted-foreground text-center mt-1">
                Si vous avez déjà un compte avec cette adresse email, votre compte sera automatiquement lié.
              </p>

              <!-- Message d'erreur pour email déjà utilisé -->
              <div
                v-if="errorMessage === 'email_exists'"
                class="text-primary text-sm p-3 rounded-md bg-primary/10 border border-primary/20 mt-4"
              >
                <div class="flex items-start">
                  <AlertTriangle class="h-4 w-4 mr-2 text-primary mt-0.5 flex-shrink-0" />
                  <div class="flex-1">
                    <p class="font-medium mb-1">Cette adresse email est déjà utilisée</p>
                    <p class="text-xs text-muted-foreground mb-2">
                      Un compte existe déjà avec cette adresse email. Si c'est votre compte, connectez-vous.
                    </p>
                    <NuxtLink
                      to="/login"
                      class="text-xs font-medium text-primary hover:text-primary/80 underline"
                    >
                      Aller à la page de connexion →
                    </NuxtLink>
                  </div>
                </div>
              </div>

              <!-- Autres messages d'erreur -->
              <div
                v-else-if="errorMessage"
                class="text-red-500 text-sm p-3 rounded-md bg-red-50 border border-red-200 mt-4"
              >
                <div class="flex items-center">
                  <AlertTriangle class="h-4 w-4 mr-2 text-red-500" />
                  {{ errorMessage }}
                </div>
              </div>
            </div>

            <div class="mt-6 text-center text-sm">
              Déjà un compte ?
              <NuxtLink
                class="text-primary font-medium hover:underline"
                to="/login"
              >
                Se connecter
              </NuxtLink>
            </div>
          </CardContent>
        </form>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false,
  middleware: ["auth"]
});
import { useAuth } from "@/composables/useAuth";
import { UserPlus, CheckCircle, Loader2, AlertTriangle, Eye, EyeOff } from 'lucide-vue-next';
import { ref, watch } from 'vue';

const { email, password, handleRegister, handleGoogleLogin, errorMessage, loading } = useAuth();
const emailError = ref('');
const acceptTerms = ref(false);
const termsError = ref('');
const showPassword = ref(false);

// Réinitialiser l'erreur d'email déjà utilisé quand l'utilisateur modifie l'email
watch(email, () => {
  if (errorMessage.value === 'email_exists') {
    errorMessage.value = '';
  }
  // Réinitialiser aussi l'erreur de format si l'email est modifié
  if (emailError.value) {
    emailError.value = '';
  }
});

// Validation du format email
const checkEmailFormat = () => {
  emailError.value = '';
  
  if (!email.value) {
    return;
  }
  
  // Expression régulière pour valider le format email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  
  if (!emailRegex.test(email.value)) {
    emailError.value = 'Veuillez entrer une adresse email valide';
    return;
  }
  
  // Vérifier que l'email n'est pas trop long
  if (email.value.length > 254) {
    emailError.value = 'L\'adresse email est trop longue';
    return;
  }
};

const onSubmit = () => {
  // Réinitialiser les erreurs
  emailError.value = '';
  termsError.value = '';
  
  // Vérifier le format avant de soumettre
  checkEmailFormat();
  
  if (emailError.value) {
    return;
  }
  
  // Vérifier l'acceptation des CGU
  if (!acceptTerms.value) {
    termsError.value = 'Vous devez accepter les Conditions Générales d\'Utilisation et la Politique de confidentialité pour créer un compte.';
    return;
  }
  
  handleRegister();
};

const handleGoogleLoginWithTerms = () => {
  termsError.value = '';
  
  if (!acceptTerms.value) {
    termsError.value = 'Vous devez accepter les Conditions Générales d\'Utilisation et la Politique de confidentialité pour continuer avec Google.';
    return;
  }
  
  // Stocker l'acceptation dans sessionStorage pour vérification dans callback
  if (typeof window !== 'undefined') {
    sessionStorage.setItem('terms_accepted', 'true');
  }
  
  handleGoogleLogin(true); // Passer true pour indiquer que c'est depuis register
};
</script>

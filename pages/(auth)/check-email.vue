<template>
  <div class="min-h-screen flex items-center justify-center bg-background p-4">
    <div class="max-w-md w-full text-center">
      <div class="bg-card rounded-xl p-8 shadow-sm border border-border">
        <div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
          <Mail class="w-8 h-8 text-primary" />
        </div>
        <h1 class="text-2xl font-bold mb-4 text-foreground">Vérifiez votre boîte mail ✉️</h1>
        <p class="text-muted-foreground mb-6">
          Un lien de confirmation a été envoyé à votre adresse email.<br />
          Merci de cliquer dessus pour activer votre compte !
        </p>
        
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6 text-left">
          <p class="text-sm text-blue-800 font-medium mb-2">💡 Conseils :</p>
          <ul class="text-xs text-blue-700 space-y-1 list-disc list-inside">
            <li>Vérifiez votre dossier spam/courrier indésirable</li>
            <li>L'email peut prendre quelques minutes à arriver</li>
            <li>Vérifiez que l'adresse email est correcte</li>
          </ul>
        </div>

        <div class="bg-amber-50 border border-amber-200 rounded-lg p-4 mb-6 text-left">
          <p class="text-sm text-amber-800 font-medium mb-2">⚠️ Si l'email n'arrive pas :</p>
          <p class="text-xs text-amber-700 mb-2">
            Si vous avez déjà un compte avec cette adresse email (par exemple via Google), 
            vous pouvez vous connecter directement :
          </p>
          <Button 
            @click="goToLogin" 
            variant="outline" 
            size="sm"
            class="w-full text-xs"
          >
            Se connecter avec votre compte existant
          </Button>
        </div>

        <div class="space-y-3">
          <Button @click="resendEmail" :disabled="loading || resendCooldown > 0" variant="outline" class="w-full">
            <Mail class="w-4 h-4 mr-2" />
            {{ resendCooldown > 0 ? `Renvoyer dans ${resendCooldown}s` : 'Renvoyer l\'email' }}
          </Button>
          
          <NuxtLink to="/login" class="block text-sm text-primary hover:underline">
            Retour à la connexion
          </NuxtLink>
        </div>

        <div v-if="errorMessage" class="mt-4 text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg p-3">
          {{ errorMessage }}
        </div>
        
        <div v-if="successMessage" class="mt-4 text-sm text-green-600 bg-green-50 border border-green-200 rounded-lg p-3">
          {{ successMessage }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { useSupabaseClient } from '#imports';
import { useRoute } from 'vue-router';
import { Mail } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';

definePageMeta({
  layout: false,
  middleware: ["auth"]
});

const supabase = useSupabaseClient();
const route = useRoute();

const loading = ref(false);
const errorMessage = ref('');
const successMessage = ref('');
const resendCooldown = ref(0);
let cooldownInterval = null;

// Récupérer l'email depuis les query params ou le localStorage
const getEmail = () => {
  return route.query.email || localStorage.getItem('signup_email') || '';
};

const resendEmail = async () => {
  const email = getEmail();
  
  if (!email) {
    errorMessage.value = 'Impossible de récupérer l\'adresse email. Veuillez réessayer de vous inscrire.';
    return;
  }

  loading.value = true;
  errorMessage.value = '';
  successMessage.value = '';

  try {
    const { error } = await supabase.auth.resend({
      type: 'signup',
      email: email,
    });

    if (error) {
      // Vérifier si c'est une erreur d'email déjà utilisé
      if (
        error.message?.includes('already registered') ||
        error.message?.includes('already exists') ||
        error.message?.includes('email address has already been registered')
      ) {
        errorMessage.value = 'Cette adresse email est déjà utilisée. Si c\'est votre compte, connectez-vous.';
      } else {
        errorMessage.value = error.message || 'Erreur lors de l\'envoi de l\'email. Veuillez réessayer.';
      }
      loading.value = false;
      return;
    }

    successMessage.value = 'Email de confirmation renvoyé avec succès !';
    
    // Démarrer le cooldown de 60 secondes
    resendCooldown.value = 60;
    cooldownInterval = setInterval(() => {
      resendCooldown.value--;
      if (resendCooldown.value <= 0) {
        clearInterval(cooldownInterval);
        cooldownInterval = null;
      }
    }, 1000);

    // Effacer le message de succès après 5 secondes
    setTimeout(() => {
      successMessage.value = '';
    }, 5000);
  } catch (error) {
    errorMessage.value = 'Une erreur inattendue est survenue. Veuillez réessayer.';
    console.error('Erreur lors du renvoi de l\'email:', error);
  } finally {
    loading.value = false;
  }
};

const goToLogin = () => {
  navigateTo('/login');
};

onMounted(() => {
  // Sauvegarder l'email dans localStorage si présent dans l'URL
  if (route.query.email) {
    localStorage.setItem('signup_email', route.query.email);
  }
});

onUnmounted(() => {
  if (cooldownInterval) {
    clearInterval(cooldownInterval);
  }
});
</script>

<template>
  <div class="h-screen flex items-center justify-center bg-gray-50 p-4">
    <div class="text-center max-w-md w-full">
      <div v-if="loading" class="space-y-4">
        <div class="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto"></div>
        <h1 class="text-2xl font-bold mb-2">Connexion en cours...</h1>
        <p class="text-gray-600">Veuillez patienter pendant que nous vous connectons.</p>
      </div>
      
      <div v-else-if="error" class="space-y-4">
        <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto">
          <AlertTriangle class="w-8 h-8 text-red-600" />
        </div>
        <h1 class="text-2xl font-bold mb-2 text-gray-900">Erreur de connexion</h1>
        <div class="bg-red-50 border border-red-200 rounded-lg p-4 text-left">
          <p class="text-red-800 font-medium mb-2">{{ errorTitle }}</p>
          <p class="text-sm text-red-700 mb-4">{{ errorMessage }}</p>
          <div v-if="isEmailExists" class="space-y-2">
            <p class="text-xs text-red-600">
              Un compte existe déjà avec cette adresse email. Vous pouvez :
            </p>
            <ul class="text-xs text-red-600 list-disc list-inside space-y-1">
              <li>Vous connecter avec votre mot de passe</li>
              <li>Ou réinitialiser votre mot de passe si vous l'avez oublié</li>
            </ul>
          </div>
        </div>
        <div class="flex gap-3 justify-center">
          <Button @click="goToLogin" variant="default">
            Aller à la connexion
          </Button>
          <Button @click="goToRegister" variant="outline">
            Créer un compte
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useSupabaseClient } from '#imports';
import { useRouter, useRoute } from 'vue-router';
import { ref, onMounted } from 'vue';
import { AlertTriangle } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';

const supabase = useSupabaseClient();
const router = useRouter();
const route = useRoute();

const loading = ref(true);
const error = ref(false);
const errorTitle = ref('');
const errorMessage = ref('');
const isEmailExists = ref(false);

// Vérifier les erreurs dans l'URL (query params)
const checkUrlErrors = () => {
  const errorParam = route.query.error;
  const errorDescription = route.query.error_description;
  
  if (errorParam) {
    error.value = true;
    loading.value = false;
    
    // Détecter les erreurs liées à l'email déjà utilisé
    if (
      errorDescription?.includes('already registered') ||
      errorDescription?.includes('already exists') ||
      errorDescription?.includes('email address has already been registered') ||
      errorParam === 'email_already_exists'
    ) {
      isEmailExists.value = true;
      errorTitle.value = 'Cette adresse email est déjà utilisée';
      errorMessage.value = 'Un compte existe déjà avec cette adresse email. Si c\'est votre compte, connectez-vous avec votre mot de passe.';
    } else {
      errorTitle.value = 'Erreur de connexion';
      errorMessage.value = errorDescription || 'Une erreur est survenue lors de la connexion avec Google.';
    }
    return true;
  }
  return false;
};

const goToLogin = () => {
  navigateTo('/login');
};

const goToRegister = () => {
  navigateTo('/register');
};

onMounted(async () => {
  // Vérifier d'abord les erreurs dans l'URL
  if (checkUrlErrors()) {
    return;
  }
  
  try {
    // Écouter les changements d'état d'authentification pour détecter la connexion
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' && session) {
        // Attendre un court instant pour s'assurer que la session est bien établie
        await new Promise(resolve => setTimeout(resolve, 500));
        
        // Vérifier à nouveau la session
        const { data: { session: confirmedSession } } = await supabase.auth.getSession();
        
        if (confirmedSession) {
          subscription.unsubscribe();
          loading.value = false;
          await navigateTo('/');
        } else {
          console.error('La session n\'a pas pu être confirmée');
          subscription.unsubscribe();
          loading.value = false;
          error.value = true;
          errorTitle.value = 'Erreur de connexion';
          errorMessage.value = 'La session n\'a pas pu être établie. Veuillez réessayer.';
        }
      } else if (event === 'SIGNED_OUT') {
        subscription.unsubscribe();
        loading.value = false;
        error.value = true;
        errorTitle.value = 'Connexion annulée';
        errorMessage.value = 'Vous avez annulé la connexion avec Google.';
      } else if (event === 'TOKEN_REFRESHED') {
        // Token rafraîchi, continuer à attendre SIGNED_IN
      }
    });
    
    // Essayer de récupérer la session immédiatement
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      console.error('Erreur lors de la récupération de la session:', sessionError);
      
      // Vérifier si c'est une erreur d'email déjà utilisé
      if (
        sessionError.message?.includes('already registered') ||
        sessionError.message?.includes('already exists') ||
        sessionError.message?.includes('email address has already been registered')
      ) {
        loading.value = false;
        error.value = true;
        isEmailExists.value = true;
        errorTitle.value = 'Cette adresse email est déjà utilisée';
        errorMessage.value = 'Un compte existe déjà avec cette adresse email. Si c\'est votre compte, connectez-vous avec votre mot de passe.';
        return;
      }
      
      // Attendre un peu au cas où la session arrive via l'événement
      setTimeout(async () => {
        const { data: { session: retrySession } } = await supabase.auth.getSession();
        if (retrySession) {
          loading.value = false;
          await navigateTo('/');
        } else {
          loading.value = false;
          error.value = true;
          errorTitle.value = 'Erreur de connexion';
          errorMessage.value = sessionError.message || 'Impossible de récupérer la session. Veuillez réessayer.';
        }
      }, 2000);
      return;
    }
    
    if (session) {
      // Attendre un peu pour s'assurer que la session est bien établie
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Vérifier à nouveau la session
      const { data: { session: finalSession } } = await supabase.auth.getSession();
      
      if (finalSession) {
        subscription.unsubscribe();
        loading.value = false;
        await navigateTo('/');
      } else {
        // Attendre un peu plus au cas où la session arrive via l'événement
        setTimeout(() => {
          subscription.unsubscribe();
          loading.value = false;
          error.value = true;
          errorTitle.value = 'Erreur de connexion';
          errorMessage.value = 'La session n\'a pas pu être confirmée. Veuillez réessayer.';
        }, 2000);
      }
    } else {
      // Si pas de session immédiate, attendre l'événement SIGNED_IN
      // Timeout après 5 secondes
      setTimeout(() => {
        subscription.unsubscribe();
        loading.value = false;
        error.value = true;
        errorTitle.value = 'Timeout de connexion';
        errorMessage.value = 'La connexion prend trop de temps. Veuillez réessayer.';
      }, 5000);
    }
  } catch (err) {
    console.error('Erreur inattendue:', err);
    loading.value = false;
    error.value = true;
    errorTitle.value = 'Erreur inattendue';
    errorMessage.value = err.message || 'Une erreur inattendue est survenue. Veuillez réessayer.';
  }
});
</script> 
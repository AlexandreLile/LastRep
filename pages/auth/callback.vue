<template>
  <div class="h-screen flex items-center justify-center">
    <div class="text-center">
      <h1 class="text-2xl font-bold mb-4">Connexion en cours...</h1>
      <p class="text-gray-600">Veuillez patienter pendant que nous vous connectons.</p>
    </div>
  </div>
</template>

<script setup>
import { useSupabaseClient } from '#imports';
import { useRouter } from 'vue-router';

const supabase = useSupabaseClient();
const router = useRouter();

onMounted(async () => {
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
          await navigateTo('/');
        } else {
          console.error('La session n\'a pas pu être confirmée');
          subscription.unsubscribe();
          await navigateTo('/login');
        }
      }
    });
    
    // Essayer de récupérer la session immédiatement
    const { data: { session }, error } = await supabase.auth.getSession();
    
    if (error) {
      console.error('Erreur lors de la récupération de la session:', error);
      // Attendre un peu au cas où la session arrive via l'événement
      setTimeout(async () => {
        const { data: { session: retrySession } } = await supabase.auth.getSession();
        if (retrySession) {
          await navigateTo('/');
        } else {
          await navigateTo('/login');
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
        await navigateTo('/');
      } else {
        // Attendre un peu plus au cas où la session arrive via l'événement
        setTimeout(() => {
          subscription.unsubscribe();
          navigateTo('/login');
        }, 2000);
      }
    } else {
      // Si pas de session immédiate, attendre l'événement SIGNED_IN
      // Timeout après 5 secondes
      setTimeout(() => {
        subscription.unsubscribe();
        navigateTo('/login');
      }, 5000);
    }
  } catch (error) {
    console.error('Erreur inattendue:', error);
    await navigateTo('/login');
  }
});
</script> 
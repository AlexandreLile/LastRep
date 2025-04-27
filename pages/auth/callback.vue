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
    // Attendre que Supabase termine le processus d'authentification
    const { data: { session }, error } = await supabase.auth.getSession();
    
    if (error) {
      console.error('Erreur lors de la récupération de la session:', error);
      router.push('/login');
      return;
    }
    
    if (session) {
      // Forcer la persistance de la session
      await supabase.auth.setSession({
        access_token: session.access_token,
        refresh_token: session.refresh_token
      });
      
      // Attendre un peu pour s'assurer que la session est bien établie
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Vérifier à nouveau la session
      const { data: { session: finalSession } } = await supabase.auth.getSession();
      
      if (finalSession) {
        router.push('/');
      } else {
        console.error('La session n\'a pas pu être établie');
        router.push('/login');
      }
    } else {
      // Si pas de session, essayer de récupérer la session depuis l'URL
      const { data: { session: urlSession }, error: urlError } = await supabase.auth.getSession();
      
      if (urlError) {
        console.error('Erreur lors de la récupération de la session depuis l\'URL:', urlError);
        router.push('/login');
        return;
      }
      
      if (urlSession) {
        // Forcer la persistance de la session
        await supabase.auth.setSession({
          access_token: urlSession.access_token,
          refresh_token: urlSession.refresh_token
        });
        router.push('/');
      } else {
        router.push('/login');
      }
    }
  } catch (error) {
    console.error('Erreur inattendue:', error);
    router.push('/login');
  }
});
</script> 
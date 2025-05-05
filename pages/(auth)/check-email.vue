<template>
  <div class="h-screen flex items-center justify-center text-center">
    <div class="max-w-md">
      <h1 class="text-2xl font-bold mb-4">Vérifiez votre boîte mail ✉️</h1>
      <p class="mb-6">
        Un lien de confirmation a été envoyé à votre adresse email.<br />
        Merci de cliquer dessus pour activer votre compte !
      </p>
      <NuxtLink to="/login" class="text-blue-600 underline">
        Retour à la connexion
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: false,
  middleware: ["auth"]
});
</script>

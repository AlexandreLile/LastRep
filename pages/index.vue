<template>
  <div
    class="relative w-full rounded-2xl overflow-hidden bg-gradient-to-r from-black via-gray-900 to-red-700 text-white p-6"
  >
    <div
      class="max-w-full py-10 sm:max-w-2xl lg:max-w-4xl md:items-start mx-auto flex flex-col justify-center items-center"
    >
      <h1
        class="text-2xl sm:text-3xl md:text-4xl font-bold mb-4 text-center sm:text-left"
      >
        LiftMetrics, gardez le contrôle de vos performances
      </h1>
      <p
        class="text-sm sm:text-base md:text-lg mb-4 opacity-90 text-center sm:text-left"
      >
        Suivez vos séances, analysez vos progrès et atteignez vos objectifs plus
        rapidement.
      </p>
      <Button @click="logout">Déconnexion</Button>
    </div>
  </div>
</template>

<script setup>
const user = useSupabaseUser();
const supabase = useSupabaseClient();
const router = useRouter();

const logout = async () => {
  try {
    await supabase.auth.signOut();
    router.push("/login");
  } catch (error) {
    console.error("Erreur lors de la déconnexion:", error);
  }
};
</script>

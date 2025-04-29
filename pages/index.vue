<template>
  <div class="relative w-full rounded-2xl p-6">
    <div
      class="max-w-full py-10 sm:max-w-2xl lg:max-w-4xl md:items-start mx-auto flex flex-col justify-center items-start"
    >
      <h1 class="text-2xl sm:text-3xl md:text-4xl font-bold mb-4 text-left">
        Last<strong class="text-primary">Rep</strong>, gardez le contrôle de vos performances
      </h1>
      <p class="text-sm sm:text-base md:text-lg mb-4 opacity-90 text-left">
        Suivez vos séances, analysez vos progrès et atteignez vos objectifs plus
        rapidement.
      </p>
      <Button @click="logout">Déconnexion</Button>
      <div class="w-full flex justify-center items-center mt-8">
        <div class="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-3 gap-4 w-full max-w-4xl">
          <SessionCount />
          <TotalWeightLifted />
          <TotalTrainingTime />
        </div>
      </div>
    </div>
  </div>

<StatsSessionRepartition></StatsSessionRepartition>
</template>

<script setup>

import SessionCount from '~/components/stats/SessionCount.vue'
import TotalWeightLifted from '~/components/stats/TotalWeightLifted.vue'
import TotalTrainingTime from '~/components/stats/TotalTrainingTime.vue'

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

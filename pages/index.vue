<template>
  <div class="relative w-full rounded-2xl p-6">
    <div
      class="max-w-full py-10 sm:max-w-2xl lg:max-w-4xl md:items-start mx-auto flex flex-col justify-center items-start"
    >
      <h1 class="text-2xl sm:text-3xl md:text-4xl font-bold mb-4 text-left">
        LiftMetrics, gardez le contrôle de vos performances
      </h1>
      <p class="text-sm sm:text-base md:text-lg mb-4 opacity-90 text-left">
        Suivez vos séances, analysez vos progrès et atteignez vos objectifs plus
        rapidement.
      </p>
      <Button @click="logout">Déconnexion</Button>
    </div>

    <!-- Section des statistiques -->
    <div class="w-full flex justify-center items-center mt-8">
      <div class="flex items-center justify-start w-full gap-8 flex-wrap">
        <div class="flex items-center gap-4">
          <div class="text-center">
            <p class="text-3xl font-bold text-primary">42</p>
            <p class="text-sm text-muted-foreground">Total des séances effectuées</p>
          </div>
        </div>

        <div class="flex items-center gap-4">
          <div class="text-center">
            <p class="text-3xl font-bold text-primary">12.5T</p>
            <p class="text-sm text-muted-foreground">Poids total soulevé</p>
          </div>
        </div>

        <div class="text-center">
          <p class="text-3xl font-bold text-primary">36h</p>
          <p class="text-sm text-muted-foreground">Temps d'entraînement</p>
        </div>
      </div>
    </div>
  </div>

<StatsSessionRepartition></StatsSessionRepartition>
</template>

<script setup>


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

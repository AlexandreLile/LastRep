<template>
  <div class="space-y-6">
    <!-- Liste des séances -->
    <div v-if="loading" class="flex justify-center">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="text-red-500 text-center">
      {{ error.message }}
    </div>

    <div v-else-if="workoutSessions.length === 0" class="text-center text-muted-foreground">
      Aucune séance trouvée
    </div>

    <div v-else class="space-y-5">
      <div
        v-for="(session, index) in sortedSessions"
        :key="session.id"
        :ref="(el) => setCardRef(session.id, el)"
        :data-session-id="session.id"
        :style="{ animationDelay: `${index * 50}ms` }"
        class="session-card group relative overflow-hidden rounded-xl border bg-card cursor-pointer transition-all duration-300 hover:border-primary/40 hover:-translate-y-0.5 hover:shadow-lg hover:shadow-primary/10"
        :class="isSpotlighted(session.id) ? 'is-spotlighted border-primary/40 -translate-y-0.5 shadow-lg shadow-primary/10' : 'border-primary/15'"
        @click="viewSession(session.id)"
      >
        <div class="session-glow absolute inset-0" aria-hidden="true"></div>

        <div class="relative flex flex-col h-full p-6">
          <div class="flex flex-wrap gap-4 items-start mb-4">
            <div class="flex items-center space-x-3 flex-1 max-w-[300px]">
              <div
                class="p-2 rounded-full bg-primary/20 transition-all duration-300 group-hover:bg-primary/30 group-hover:scale-110"
                :class="{ 'bg-primary/30 scale-110': isSpotlighted(session.id) }"
              >
                <Dumbbell
                  class="h-5 w-5 text-primary transition-transform duration-300 group-hover:rotate-12"
                  :class="{ 'rotate-12': isSpotlighted(session.id) }"
                />
              </div>
              <div class="text-left min-w-0">
                <h3
                  class="text-lg font-medium text-foreground transition-colors duration-300 group-hover:text-primary"
                  :class="{ 'text-primary': isSpotlighted(session.id) }"
                >{{ session.title }}</h3>
                <p class="text-xs text-muted-foreground">Dernière modification: {{ formatDate(session.updated_at) }}</p>
                <div v-if="sessionBadges[session.id]" class="mt-1.5 flex flex-wrap gap-1.5">
                  <span
                    v-if="sessionBadges[session.id].lastSessionPrCount > 0"
                    class="inline-flex items-center gap-1 rounded-full border border-record/30 bg-record/10 px-2 py-0.5 text-[11px] font-medium text-record"
                  >
                    🏆 {{ sessionBadges[session.id].lastSessionPrCount }} record{{ sessionBadges[session.id].lastSessionPrCount > 1 ? 's' : '' }} battu{{ sessionBadges[session.id].lastSessionPrCount > 1 ? 's' : '' }}
                  </span>
                  <span
                    v-if="sessionBadges[session.id].recordsInPlay > 0"
                    class="inline-flex items-center gap-1 rounded-full border border-record/30 bg-record/10 px-2 py-0.5 text-[11px] font-medium text-record"
                  >
                    {{ sessionBadges[session.id].recordsInPlay }} record{{ sessionBadges[session.id].recordsInPlay > 1 ? 's' : '' }} en jeu
                  </span>
                </div>
              </div>
            </div>
            <div class="hidden sm:flex items-center gap-2">
              <div class="relative inline-block">
                <div class="cta-glow absolute -inset-1.5 rounded-lg bg-primary" aria-hidden="true"></div>
                <Button
                  variant="default"
                  size="sm"
                  class="relative flex items-center gap-1.5 bg-primary hover:bg-primary/90 text-primary-foreground"
                  @click.stop="navigateToSession(session.id)"
                >
                  <Play class="h-4 w-4" />
                  <span class="text-sm font-medium">Démarrer</span>
                </Button>
              </div>
              <Button
                variant="ghost"
                size="sm"
                class="flex items-center gap-1 text-foreground hover:text-primary hover:bg-primary/10"
                @click.stop="editSession(session)"
              >
                <Pencil class="h-4 w-4" />
                <span class="text-sm font-medium">Modifier</span>
              </Button>
            </div>
          </div>

          <p class="text-muted-foreground mb-4 flex-grow line-clamp-2 transition-colors duration-300 group-hover:text-gray-700">{{ session.notes }}</p>

          <div class="space-y-2">
            <div class="flex flex-wrap gap-2">
              <span
                v-for="exercise in session.exercises"
                :key="exercise.id"
                class="text-sm text-muted-foreground bg-muted/50 px-3 py-1 rounded-full transition-all duration-300 group-hover:bg-primary/10 group-hover:text-primary group-hover:scale-105"
                :class="{ 'bg-primary/10 text-primary scale-105': isSpotlighted(session.id) }"
              >
                {{ exercise.exercise.name }}
              </span>
            </div>
          </div>

          <!-- Actions visibles seulement sur mobile -->
          <div class="sm:hidden flex justify-end gap-2 mt-4">
            <div class="relative inline-block">
              <div class="cta-glow absolute -inset-1.5 rounded-lg bg-primary" aria-hidden="true"></div>
              <Button
                variant="default"
                size="sm"
                class="relative flex items-center gap-1.5 bg-primary hover:bg-primary/90 text-primary-foreground px-3 py-1 font-medium"
                @click.stop="navigateToSession(session.id)"
              >
                <Play class="h-3.5 w-3.5" />
                <span class="text-xs">Démarrer</span>
              </Button>
            </div>
            <Button
              variant="ghost"
              size="sm"
              class="flex items-center gap-1 text-foreground bg-muted hover:bg-primary/20 hover:text-primary px-3 py-1 font-medium"
              @click.stop="editSession(session)"
            >
              <Pencil class="h-3.5 w-3.5" />
              <span class="text-xs">Éditer</span>
            </Button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Pencil, Dumbbell, Play } from 'lucide-vue-next';
import { useRouter } from 'vue-router';
import { computed, onMounted, onBeforeUnmount, reactive, nextTick } from 'vue';
import { loadSessionMotivation } from '~/composables/useSessionMotivation';


const router = useRouter();
const user = useSupabaseUser();
const supabase = useSupabaseClient();
const {
  workoutSessions,
  loading,
  error,
  getWorkoutSessions
} = useWorkoutSessions(user);

// Résumé motivation par séance (id -> { lastSessionPrCount, recordsInPlay }), chargé en best-effort
const sessionBadges = reactive({});

const loadSessionBadges = async () => {
  await Promise.all(
    workoutSessions.value.map(async (session) => {
      const normalizedExercises = (session.exercises || []).map((ex) => ({
        exercise_id: ex.exercise?.id,
        measurement_type: ex.exercise?.measurement_type
      }))
      const result = await loadSessionMotivation(supabase, {
        sessionId: session.id,
        exercises: normalizedExercises
      })
      sessionBadges[session.id] = result
    })
  )
}

// Séances triées par date de modification (plus récentes en premier)
const sortedSessions = computed(() => {
  return [...workoutSessions.value].sort((a, b) => {
    return new Date(b.updated_at) - new Date(a.updated_at);
  });
});

// ============================================
// SPOTLIGHT AU SCROLL
// ============================================
// Reproduit l'effet hover sur la carte qui traverse le centre de l'écran :
// suit le scroll au lieu de dépendre de la souris (utile aussi au tactile).
const cardEls = new Map();
const spotlightedIds = reactive(new Set());
let scrollObserver = null;

const setCardRef = (sessionId, el) => {
  if (el) cardEls.set(sessionId, el);
  else cardEls.delete(sessionId);
};

const isSpotlighted = (sessionId) => spotlightedIds.has(sessionId);

const setupScrollSpotlight = () => {
  scrollObserver?.disconnect();
  scrollObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        const sessionId = entry.target.dataset.sessionId;
        if (entry.isIntersecting) spotlightedIds.add(sessionId);
        else spotlightedIds.delete(sessionId);
      });
    },
    { rootMargin: '-35% 0px -35% 0px', threshold: 0 }
  );
  cardEls.forEach((el) => scrollObserver.observe(el));
};

// Rafraîchir la liste au montage
onMounted(async () => {
  await getWorkoutSessions();
  loadSessionBadges();
  await nextTick();
  setupScrollSpotlight();
});

onBeforeUnmount(() => {
  scrollObserver?.disconnect();
});

const viewSession = (sessionId) => {
  router.push(`/seances/${sessionId}/train`);
};

const navigateToSession = async (sessionId) => {
  try {
    const supabase = useSupabaseClient()
    const { prepareSession } = usePerformedSession(supabase)
    const userId = (await supabase.auth.getUser()).data.user.id
    prepareSession(sessionId, userId)
    router.push(`/seances/${sessionId}/start`)
  } catch (e) {
    console.error('Erreur lors du démarrage de la séance:', e)
  }
};

// Gérer l'édition d'une séance
const editSession = (session) => {
  router.push(`/seances/${session.id}/edit`);
};

const formatDate = (dateString) => {
  const date = new Date(dateString);
  return date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });
};
</script>

<style scoped>
.session-card {
  animation: fadeInUp 0.4s ease both;
}

.session-glow {
  overflow: hidden;
  pointer-events: none;
}

.session-glow::before {
  content: '';
  position: absolute;
  width: 200px;
  height: 200px;
  top: -80px;
  right: -60px;
  border-radius: 9999px;
  background: var(--primary);
  opacity: 0.15;
  filter: blur(60px);
  transition: opacity 0.3s ease;
}

.session-card:hover .session-glow::before,
.session-card.is-spotlighted .session-glow::before {
  opacity: 0.3;
}

.cta-glow {
  filter: blur(12px);
  animation: glow 2.4s ease-in-out infinite;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes glow {
  0%, 100% {
    opacity: 0.2;
    transform: scale(1);
  }
  50% {
    opacity: 0.45;
    transform: scale(1.05);
  }
}

@media (prefers-reduced-motion: reduce) {
  .cta-glow,
  .session-card {
    animation: none;
  }
}
</style>

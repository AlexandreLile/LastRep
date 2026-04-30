<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <!-- Header -->
    <div class="text-center mb-10">
      <div class="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-1.5 rounded-full text-sm font-medium mb-4">
        <Sparkles class="h-4 w-4" />
        LastRep Premium
      </div>
      <h1 class="text-3xl font-bold mb-3">Passez au niveau supérieur</h1>
      <p class="text-muted-foreground text-lg">Débloquez toutes les fonctionnalités et progressez sans limites</p>
    </div>

    <!-- Alerte succès -->
    <div v-if="route.query.success" class="mb-8 bg-green-50 border border-green-200 rounded-xl p-4 flex items-center gap-3">
      <CheckCircle class="h-5 w-5 text-green-600 flex-shrink-0" />
      <div>
        <p class="font-semibold text-green-800">Abonnement activé !</p>
        <p class="text-sm text-green-700">Bienvenue dans LastRep Premium. Toutes les fonctionnalités sont maintenant débloquées.</p>
      </div>
    </div>

    <!-- Alerte annulation -->
    <div v-if="route.query.canceled" class="mb-8 bg-amber-50 border border-amber-200 rounded-xl p-4 flex items-center gap-3">
      <AlertTriangle class="h-5 w-5 text-amber-600 flex-shrink-0" />
      <p class="text-sm text-amber-700">Le paiement a été annulé. Vous pouvez réessayer quand vous le souhaitez.</p>
    </div>

    <!-- Statut abonnement actuel -->
    <div v-if="isPremium" class="mb-8 bg-card border rounded-xl p-6">
      <div class="flex items-center justify-between flex-wrap gap-4">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Crown class="h-5 w-5 text-primary" />
          </div>
          <div>
            <p class="font-semibold">Abonnement Premium actif</p>
            <p class="text-sm text-muted-foreground">
              {{ isYearly ? 'Plan annuel' : 'Plan mensuel' }}
              <span v-if="periodEnd"> · Renouvellement le {{ formatDate(periodEnd) }}</span>
              <span v-if="isCanceling" class="text-amber-600 font-medium"> · Se termine le {{ formatDate(periodEnd) }}</span>
            </p>
          </div>
        </div>
        <Button variant="outline" @click="handlePortal" :disabled="portalLoading">
          <Loader2 v-if="portalLoading" class="h-4 w-4 animate-spin mr-2" />
          Gérer mon abonnement
        </Button>
      </div>
      <div v-if="isCanceling" class="mt-3 text-sm text-amber-600 bg-amber-50 rounded-lg px-3 py-2">
        Votre abonnement ne sera pas renouvelé. Vous conservez l'accès Premium jusqu'au {{ formatDate(periodEnd) }}.
      </div>
    </div>

    <!-- Toggle mensuel/annuel -->
    <div v-if="!isPremium" class="flex justify-center mb-8">
      <div class="bg-muted rounded-full p-1 flex items-center gap-1">
        <button
          @click="isYearlyToggle = false"
          :class="['px-5 py-2 rounded-full text-sm font-medium transition-all', !isYearlyToggle ? 'bg-white shadow text-foreground' : 'text-muted-foreground']"
        >
          Mensuel
        </button>
        <button
          @click="isYearlyToggle = true"
          :class="['px-5 py-2 rounded-full text-sm font-medium transition-all flex items-center gap-2', isYearlyToggle ? 'bg-white shadow text-foreground' : 'text-muted-foreground']"
        >
          Annuel
          <span class="bg-primary text-white text-xs px-2 py-0.5 rounded-full">-33%</span>
        </button>
      </div>
    </div>

    <!-- Cartes de prix -->
    <div v-if="!isPremium" class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
      <!-- Gratuit -->
      <div class="bg-card border rounded-xl p-6">
        <div class="mb-6">
          <h2 class="text-xl font-bold mb-1">Gratuit</h2>
          <p class="text-muted-foreground text-sm">Pour commencer votre parcours</p>
        </div>
        <div class="mb-6">
          <span class="text-4xl font-bold">0€</span>
          <span class="text-muted-foreground"> / mois</span>
        </div>
        <Button variant="outline" class="w-full mb-6" disabled>Plan actuel</Button>
        <ul class="space-y-3">
          <li v-for="feature in freeFeatures" :key="feature" class="flex items-center gap-2 text-sm">
            <Check class="h-4 w-4 text-muted-foreground flex-shrink-0" />
            <span class="text-muted-foreground">{{ feature }}</span>
          </li>
          <li v-for="feature in lockedFeatures" :key="feature" class="flex items-center gap-2 text-sm">
            <X class="h-4 w-4 text-muted-foreground/40 flex-shrink-0" />
            <span class="text-muted-foreground/50 line-through">{{ feature }}</span>
          </li>
        </ul>
      </div>

      <!-- Premium -->
      <div class="bg-card border-2 border-primary rounded-xl p-6 relative">
        <div class="absolute -top-3 left-1/2 -translate-x-1/2">
          <span class="bg-primary text-white text-xs font-bold px-4 py-1 rounded-full">RECOMMANDÉ</span>
        </div>
        <div class="mb-6">
          <h2 class="text-xl font-bold mb-1 flex items-center gap-2">
            Premium
            <Crown class="h-5 w-5 text-primary" />
          </h2>
          <p class="text-muted-foreground text-sm">Tout ce dont vous avez besoin</p>
        </div>
        <div class="mb-6">
          <span class="text-4xl font-bold">{{ isYearlyToggle ? '6,66€' : '9,99€' }}</span>
          <span class="text-muted-foreground"> / mois</span>
          <p v-if="isYearlyToggle" class="text-sm text-muted-foreground mt-1">Facturé 79,99€ / an</p>
        </div>
        <Button class="w-full mb-6" @click="handleCheckout" :disabled="checkoutLoading">
          <Loader2 v-if="checkoutLoading" class="h-4 w-4 animate-spin mr-2" />
          <Sparkles v-else class="h-4 w-4 mr-2" />
          Commencer Premium
        </Button>
        <ul class="space-y-3">
          <li v-for="feature in allFeatures" :key="feature" class="flex items-center gap-2 text-sm">
            <Check class="h-4 w-4 text-primary flex-shrink-0" />
            <span>{{ feature }}</span>
          </li>
        </ul>
      </div>
    </div>

    <!-- Comparaison fonctionnalités (quand premium) -->
    <div v-if="isPremium" class="bg-card border rounded-xl p-6 mb-8">
      <h3 class="font-semibold mb-4 flex items-center gap-2">
        <Crown class="h-5 w-5 text-primary" />
        Vos fonctionnalités Premium
      </h3>
      <ul class="space-y-3">
        <li v-for="feature in allFeatures" :key="feature" class="flex items-center gap-2 text-sm">
          <Check class="h-4 w-4 text-primary flex-shrink-0" />
          <span>{{ feature }}</span>
        </li>
      </ul>
    </div>

    <!-- FAQ -->
    <div class="space-y-4">
      <h2 class="text-xl font-bold mb-6">Questions fréquentes</h2>
      <div v-for="item in faq" :key="item.q" class="bg-card border rounded-xl p-5">
        <button class="w-full text-left" @click="item.open = !item.open">
          <div class="flex items-center justify-between">
            <span class="font-medium">{{ item.q }}</span>
            <ChevronDown :class="['h-4 w-4 text-muted-foreground transition-transform', item.open ? 'rotate-180' : '']" />
          </div>
        </button>
        <p v-if="item.open" class="text-sm text-muted-foreground mt-3">{{ item.a }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { Sparkles, Crown, Check, X, CheckCircle, AlertTriangle, ChevronDown, Loader2 } from 'lucide-vue-next'
import { useSubscription } from '~/composables/useSubscription'
import { toast } from 'vue-sonner'

definePageMeta({ middleware: ['client-only'] })

const route = useRoute()
const { isPremium, isYearly, isCanceling, periodEnd, fetchSubscription, startCheckout, openPortal } = useSubscription()

const isYearlyToggle = ref(false)
const checkoutLoading = ref(false)
const portalLoading = ref(false)

const runtimeConfig = useRuntimeConfig()

const freeFeatures = [
  'Jusqu\'à 3 séances d\'entraînement',
  'Jusqu\'à 3 exercices personnalisés',
  'Statistiques de base',
  'Suivi poids et répétitions',
]

const lockedFeatures = [
  'Séances illimitées',
  'Exercices personnalisés illimités',
  'Graphiques avancés',
  'Historique complet',
  'Calcul 1RM',
  'Répartition musculaire',
]

const allFeatures = [
  'Séances d\'entraînement illimitées',
  'Exercices personnalisés illimités',
  'Graphiques de progression avancés',
  'Historique complet de vos séances',
  'Calcul du 1RM (One Rep Max)',
  'Analyse de la répartition musculaire',
  'Statistiques détaillées par exercice',
  'Support prioritaire',
]

const faq = reactive([
  {
    q: 'Puis-je annuler à tout moment ?',
    a: 'Oui, vous pouvez annuler votre abonnement à tout moment depuis le portail de gestion. Vous conservez l\'accès Premium jusqu\'à la fin de votre période de facturation.',
    open: false,
  },
  {
    q: 'Mes données sont-elles conservées si j\'annule ?',
    a: 'Absolument. Vos séances, séries et statistiques sont conservées indéfiniment, quelle que soit votre formule.',
    open: false,
  },
  {
    q: 'Puis-je passer du mensuel à l\'annuel ?',
    a: 'Oui, vous pouvez changer de plan à tout moment depuis le portail de gestion. La différence sera créditée au prorata.',
    open: false,
  },
  {
    q: 'Quels moyens de paiement sont acceptés ?',
    a: 'Nous acceptons toutes les cartes bancaires (Visa, Mastercard, American Express) via Stripe, la plateforme de paiement la plus sécurisée du marché.',
    open: false,
  },
])

function formatDate(date) {
  if (!date) return ''
  return new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }).format(date)
}

async function handleCheckout() {
  checkoutLoading.value = true
  try {
    const priceId = isYearlyToggle.value
      ? runtimeConfig.public.stripePriceYearly
      : runtimeConfig.public.stripePriceMonthly

    if (!priceId) {
      toast.error('Configuration Stripe manquante. Vérifiez les variables d\'environnement.')
      return
    }

    await startCheckout(priceId)
  } catch (err) {
    toast.error('Une erreur est survenue. Veuillez réessayer.')
    console.error(err)
  } finally {
    checkoutLoading.value = false
  }
}

async function handlePortal() {
  portalLoading.value = true
  try {
    await openPortal()
  } catch (err) {
    toast.error('Impossible d\'ouvrir le portail. Veuillez réessayer.')
    console.error(err)
  } finally {
    portalLoading.value = false
  }
}

onMounted(async () => {
  await fetchSubscription()
  if (route.query.success) {
    await fetchSubscription()
  }
})
</script>

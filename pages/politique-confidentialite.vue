<template>
  <div class="min-h-screen bg-background p-4 sm:p-6 md:p-10">
    <div class="max-w-4xl mx-auto">
      <div class="mb-8">
        <NuxtLink
          to="/register"
          class="text-primary hover:underline inline-flex items-center gap-2 mb-4"
        >
          <ArrowLeft class="h-4 w-4" />
          Retour à l'inscription
        </NuxtLink>
        <h1 class="text-3xl font-bold text-foreground mb-2">Politique de Confidentialité</h1>
        <p class="text-muted-foreground">Dernière mise à jour : {{ new Date().toLocaleDateString('fr-FR') }}</p>
      </div>

      <Card class="border border-border shadow-sm">
        <CardContent class="pt-6">
          <div class="prose prose-sm max-w-none dark:prose-invert">
            <h2>1. Collecte d'informations</h2>
            <p>
              LastRep collecte les informations suivantes lorsque vous créez un compte :
            </p>
            <ul>
              <li>Adresse email</li>
              <li>Données d'entraînement (sessions, exercices, poids, répétitions)</li>
              <li>Informations de connexion (via Google OAuth si applicable)</li>
            </ul>

            <h2>2. Utilisation des informations</h2>
            <p>Nous utilisons vos informations pour :</p>
            <ul>
              <li>Fournir et améliorer nos services</li>
              <li>Personnaliser votre expérience</li>
              <li>Vous envoyer des notifications importantes concernant votre compte</li>
              <li>Analyser l'utilisation du service pour améliorer nos fonctionnalités</li>
            </ul>

            <h2>3. Protection des données</h2>
            <p>
              Nous mettons en œuvre des mesures de sécurité appropriées pour protéger vos informations personnelles
              contre l'accès non autorisé, la modification, la divulgation ou la destruction.
            </p>

            <h2>4. Partage des informations</h2>
            <p>
              Nous ne vendons, n'échangeons ni ne louons vos informations personnelles à des tiers.
              Vos données d'entraînement sont privées et ne sont accessibles que par vous.
            </p>

            <h2>5. Cookies et technologies similaires</h2>
            <p>
              Nous utilisons des cookies et des technologies similaires pour améliorer votre expérience,
              analyser l'utilisation du service et personnaliser le contenu.
            </p>

            <h2>6. Vos droits</h2>
            <p>Conformément au RGPD, vous avez le droit de :</p>
            <ul>
              <li>Accéder à vos données personnelles</li>
              <li>Rectifier vos données</li>
              <li>Supprimer votre compte et vos données</li>
              <li>Vous opposer au traitement de vos données</li>
              <li>Demander la portabilité de vos données</li>
            </ul>

            <h2>7. Conservation des données</h2>
            <p>
              Nous conservons vos données tant que votre compte est actif. Vous pouvez supprimer votre compte
              et toutes vos données à tout moment depuis la page de profil.
            </p>

            <h2>8. Modifications de cette politique</h2>
            <p>
              Nous pouvons modifier cette politique de confidentialité à tout moment. Les modifications prendront effet
              dès leur publication sur cette page.
            </p>

            <h2>9. Contact</h2>
            <p>
              Pour toute question concernant cette Politique de Confidentialité ou pour exercer vos droits,
              vous pouvez nous contacter via l'application ou par email.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</template>

<script setup>
import { ArrowLeft } from 'lucide-vue-next'

definePageMeta({
  layout: 'default'
})
</script>

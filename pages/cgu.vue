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
        <h1 class="text-3xl font-bold text-foreground mb-2">Conditions Générales d'Utilisation</h1>
        <p class="text-muted-foreground">Dernière mise à jour : {{ new Date().toLocaleDateString('fr-FR') }}</p>
      </div>

      <Card class="border border-border shadow-sm">
        <CardContent class="pt-6">
          <div class="prose prose-sm max-w-none dark:prose-invert">
            <h2>1. Acceptation des conditions</h2>
            <p>
              En accédant et en utilisant LastRep, vous acceptez d'être lié par ces Conditions Générales d'Utilisation.
              Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser notre service.
            </p>

            <h2>2. Description du service</h2>
            <p>
              LastRep est une application web permettant de suivre et gérer vos entraînements de musculation.
              Le service vous permet de créer des sessions d'entraînement, suivre vos performances et analyser vos progrès.
            </p>

            <h2>3. Compte utilisateur</h2>
            <p>
              Pour utiliser LastRep, vous devez créer un compte en fournissant des informations exactes et complètes.
              Vous êtes responsable de maintenir la confidentialité de votre mot de passe et de toutes les activités
              qui se produisent sous votre compte.
            </p>

            <h2>4. Utilisation du service</h2>
            <p>Vous vous engagez à :</p>
            <ul>
              <li>Utiliser le service uniquement à des fins légales</li>
              <li>Ne pas tenter d'accéder à des comptes d'autres utilisateurs</li>
              <li>Ne pas perturber ou endommager le service</li>
              <li>Respecter les droits de propriété intellectuelle</li>
            </ul>

            <h2>5. Propriété intellectuelle</h2>
            <p>
              Tous les contenus de LastRep, y compris mais sans s'y limiter, les textes, graphiques, logos,
              icônes et logiciels, sont la propriété de LastRep ou de ses fournisseurs de contenu et sont protégés
              par les lois sur la propriété intellectuelle.
            </p>

            <h2>6. Limitation de responsabilité</h2>
            <p>
              LastRep est fourni "tel quel" sans garantie d'aucune sorte. Nous ne garantissons pas que le service
              sera ininterrompu, sécurisé ou exempt d'erreurs. Vous utilisez le service à vos propres risques.
            </p>

            <h2>7. Modification des conditions</h2>
            <p>
              Nous nous réservons le droit de modifier ces conditions à tout moment. Les modifications prendront effet
              dès leur publication sur cette page. Il est de votre responsabilité de consulter régulièrement ces conditions.
            </p>

            <h2>8. Contact</h2>
            <p>
              Pour toute question concernant ces Conditions Générales d'Utilisation, vous pouvez nous contacter
              via l'application ou par email.
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

# LastRep

Application web de suivi d'entraînement — enregistre tes séances, visualise ta progression, analyse tes performances.

**Production** : [app.lastrep.fr](https://app.lastrep.fr)

## Stack

- **Framework** : Nuxt 3 (SPA, SSR désactivé)
- **UI** : Vue 3 + Shadcn-nuxt + Tailwind CSS v4
- **Backend** : Supabase (Auth, PostgreSQL, RLS)
- **Charts** : Chart.js + vue-chartjs
- **Email** : Resend (via SMTP Supabase)
- **Déploiement** : Vercel

## Installation

```bash
# 1. Cloner le repo
git clone https://github.com/AlexandreLile/LastRep.git
cd LastRep

# 2. Installer les dépendances
npm install

# 3. Configurer les variables d'environnement
cp .env.example .env.local
# Remplir .env.local avec les credentials Supabase DEV (voir docs/deployment.md)
```

## Démarrage

```bash
npm run dev        # Serveur de développement → http://localhost:3000
npm run build      # Build de production
npm run preview    # Prévisualiser le build
```

## Base de données (Supabase CLI)

```bash
npm run db:new <nom>   # Créer une migration
npm run db:push        # Appliquer les migrations en production
npm run db:status      # État des migrations
npm run db:link        # Lier le projet Supabase local
```

## Workflow

Toute contribution passe par une Pull Request. Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour les conventions de branches et de commits.

## Documentation

- [docs/architecture.md](docs/architecture.md) — structure technique, BDD, sécurité, performances
- [docs/deployment.md](docs/deployment.md) — configuration des environnements, Vercel, Supabase, email

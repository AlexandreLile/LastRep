# AUDIT — LastRep

> Généré le 2026-08-05. Ne modifie rien — attends validation avant toute action.

---

## 1. Stack et architecture générale

| Couche | Techno |
|---|---|
| Framework | Nuxt 3 (mode SPA, SSR désactivé globalement) |
| UI | Vue 3 + Shadcn-nuxt + Reka UI + Tailwind CSS v4 |
| Backend | Supabase (Auth, PostgreSQL, RLS, Storage) |
| Charts | Chart.js + vue-chartjs |
| Forms | vee-validate + Zod |
| Tables | @tanstack/vue-table |
| Email | Resend (via SMTP configuré dans Supabase) |
| PWA | manifest.json + favicon configurés |

**Architecture applicative :**
- SPA pure (ssr: false), rendu 100 % client
- Auth gérée manuellement via plugins Supabase (5 plugins client) + middleware Nuxt
- Supabase RLS activé sur toutes les tables
- Route `/admin/**` bloquée en production via routeRules Nitro
- API server-side minimale : un seul endpoint (`/api/admin/users`)
- Migrations DB versionnées via Supabase CLI (30+ fichiers dans `supabase/migrations/`)

**Déploiement actuel :**
- **Aucun CI/CD** (pas de répertoire `.github/`, pas de Dockerfile)
- Déploiement entièrement manuel : `nuxt build` puis upload
- La branche `production` semble servir de référence prod (dernier commit 2026-02-04)
- Domaine de production : `app.lastrep.fr`

---

## 2. État des branches

### Branches actives (récentes)

| Branche | Dernier commit | Auteur | Mergée dans main |
|---|---|---|---|
| `feature/stripe-integration` | 2026-04-30 | Alexandre Lile | Non |
| `production` | 2026-02-04 | Alexandre Lile | Non |
| `offline-training` | 2026-02-04 | Alexandre Lile | Non |
| `exercice-volume` | 2026-01-31 | Alexandre Lile | Non |
| `feature/admin-dashboard` | 2026-01-21 | Alexandre Lile | Non ← branche courante |
| `dev` | 2026-01-13 | Alexandre Lile | Non |

### Branches mortes / obsolètes (> 6 mois d'inactivité)

| Branche | Dernier commit | Statut |
|---|---|---|
| `design/test` | 2025-05-09 | **Morte** — expérimentation UI sans suite |
| `feature/exercice` | 2025-04-29 | **Morte** — fonctionnalité intégrée depuis |
| `fetaure/exerciseSet` | 2025-04-29 | **Morte** + faute de frappe dans le nom |
| `feature/performedsession` | 2025-04-29 | **Morte** — fonctionnalité intégrée depuis |
| `feature/session` | 2025-04-28 | **Morte** — fonctionnalité intégrée depuis |
| `feature/auth` | 2025-04-27 | **Morte** — fonctionnalité intégrée depuis |
| `origin/master` | 2025-04-26 | **Morte** — doublon de `main` |
| `main` | 2025-04-26 | **Figée** — jamais mis à jour, n'est plus la ref prod |

**Observation clé :** `main` est figé depuis le kick-off (2025-04-26). Toute la vie du projet s'est déroulée sur `production`, `dev`, et des branches feature sans jamais revenir sur `main`. Il n'existe aucune branche `develop`.

---

## 3. Inventaire des fichiers .md / .mdx

Aucun fichier `.mdx` — uniquement des `.md`. 42 fichiers au total.

### Groupe A — Documentation pérenne (à garder / consolider)

| Fichier | Taille | Dernière modif git | Résumé |
|---|---|---|---|
| `README.md` | 1.1 KB | 2025-04-26 | Template Nuxt minimal par défaut — **pas du tout à jour** |
| `README_ENV.md` | 940 B | 2026-01-13 | Guide de démarrage rapide des variables d'env |
| `ENV_SETUP.md` | 5.2 KB | 2026-01-13 | Config complète des environnements dev/prod |
| `MIGRATIONS.md` | 4.3 KB | 2026-01-12 | Guide d'utilisation de Supabase CLI et migrations |
| `SECURITY.md` | 5.0 KB | 2026-01-14 | Configuration sécurité (RLS, fonctions, politiques) |
| `PERFORMANCE_OPTIMIZATIONS.md` | 4.3 KB | 2026-01-13 | Problèmes de perf identifiés et optimisations appliquées |
| `ADMIN_DASHBOARD.md` | 3.4 KB | 2026-01-17 | Documentation du dashboard admin (local uniquement) |
| `ACCOUNT_DELETION_TRACKING.md` | 3.4 KB | 2026-01-17 | Suivi des suppressions de comptes — feature en place |
| `PRODUCTION_ADMIN_PROTECTION.md` | 2.5 KB | 2026-01-17 | Protection des routes admin en prod via routeRules |
| `supabase/templates/README.md` | 2.5 KB | 2026-01-15 | Documentation des templates email Supabase |

### Groupe B — Checklists / analyses de prêt-à-produire (obsolètes)

Ces fichiers étaient utiles pendant la phase de lancement, leur contenu est désormais figé dans le temps.

| Fichier | Taille | Dernière modif git | Résumé |
|---|---|---|---|
| `ANALYSE_PRET_PRODUCTION.md` | 12.4 KB | 2026-01-15 | Analyse ~75% prêt prod — état Jan 2026, désormais dépassé |
| `MVP_BETA_CHECKLIST.md` | 8.0 KB | 2026-01-14 | Checklist MVP beta testeurs — majorité des items faits |
| `PRODUCTION_CHECKLIST.md` | 7.2 KB | 2026-01-14 | Checklist prod complète — redondante avec l'analyse |
| `ONBOARDING_CHECKLIST.md` | 11.1 KB | 2026-01-13 | Checklist onboarding utilisateur — features en place |

**Recommandation : supprimer** — leur valeur informative est nulle à ce stade.

### Groupe C — Docs Resend / Email (7 fichiers redondants)

Tous créés en quelques heures le 2026-01-13 pour résoudre un problème DNS Resend. Ils se répètent et se contredisent.

| Fichier | Taille | Résumé |
|---|---|---|
| `RESEND_SETUP.md` | 9.6 KB | Guide complet de setup Resend |
| `RESEND_DNS_SETUP.md` | 10.0 KB | Config DNS pour Resend (redondant avec SETUP) |
| `RESEND_DNS_TROUBLESHOOTING.md` | 6.3 KB | Résolution status "Not Started" |
| `RESEND_DNS_FIX.md` | 4.6 KB | Fix "DNS Record not found" |
| `RESEND_NEXT_STEPS.md` | 4.3 KB | Étapes post-config DNS |
| `RESEND_WAIT_GUIDE.md` | 2.9 KB | Patience pendant propagation DNS |
| `RESEND_DELIVERABILITY_FIX.md` | 9.0 KB | Amélioration délivrabilité / éviter les spams |
| `SMTP_SETUP.md` | 10.0 KB | Config SMTP Supabase (overlaps avec Resend) |
| `SUPABASE_SMTP_CONFIG.md` | 6.6 KB | Config SMTP dans le dashboard Supabase |

**Recommandation : fusionner** en un seul `docs/email-setup.md`, puis supprimer les 9 fichiers.

### Groupe D — Docs domaine Supabase (4 fichiers redondants)

| Fichier | Taille | Résumé |
|---|---|---|
| `SUPABASE_DOMAIN_SETUP.md` | 6.5 KB | Config du custom domain `app.lastrep.fr` dans Supabase |
| `SUPABASE_CUSTOM_DOMAIN_FIX.md` | 3.8 KB | Fix URLs par défaut Supabase dans les emails |
| `DOMAIN_MIGRATION.md` | 4.8 KB | Checklist de migration vers `app.lastrep.fr` |
| `DOMAIN_CLARIFICATION.md` | 3.4 KB | Explication de la différence domaine/sous-domaine |

**Recommandation : fusionner** en `docs/deployment.md`, puis supprimer les 4 fichiers.

### Groupe E — Petites notes opérationnelles (à intégrer dans ENV_SETUP ou supprimer)

| Fichier | Taille | Résumé |
|---|---|---|
| `ADD_SERVICE_KEY.md` | 2.4 KB | Comment ajouter `SUPABASE_SERVICE_KEY` |
| `CHECK_SERVICE_KEY.md` | 2.1 KB | Comment vérifier la service key |
| `FIX_REFRESH_TOKEN_ERROR.md` | 2.1 KB | Fix historique refresh token — code déjà corrigé |
| `DEV_REDIRECT_FIX.md` | 3.8 KB | Fix historique redirection dev vers prod — corrigé |
| `README_ENV.md` | 940 B | Doublon partiel de `ENV_SETUP.md` |
| `SUPABASE_FREE_PLAN.md` | 4.3 KB | Fonctionnalités du plan gratuit Supabase |

**Recommandation :** `ADD_SERVICE_KEY.md` + `CHECK_SERVICE_KEY.md` → intégrer dans `ENV_SETUP.md`, puis supprimer. Les fixes historiques (`FIX_REFRESH_TOKEN_ERROR.md`, `DEV_REDIRECT_FIX.md`) → **supprimer**. `README_ENV.md` → **supprimer** (redondant). `SUPABASE_FREE_PLAN.md` → **supprimer** (info changeante, vérifier sur supabase.com).

### Groupe F — Specs de features non implémentées (à décider)

Des documents de design/analyse pour des features pas encore développées.

| Fichier | Taille | Résumé |
|---|---|---|
| `COACHING_SYSTEM_ANALYSIS.md` | 18.4 KB | Analyse de complexité d'un système de coaching |
| `COACHING_SYSTEM_DESIGN.md` | 25.9 KB | Design UX/technique du système de coaching |
| `CUSTOM_EXERCISES_ANALYSIS.md` | 22.3 KB | Analyse des exercices personnalisés avec types de mesure |
| `CUSTOM_EXERCISES_DESIGN.md` | 19.2 KB | Design des exercices personnalisés |
| `CUSTOM_EXERCISES_FLEXIBLE.md` | 12.4 KB | Approche flexible pour les exercices custom |
| `CUSTOM_EXERCISES_STATS.md` | 13.8 KB | Stats pour exercices personnalisés |
| `SHARE_SYSTEM_ANALYSIS.md` | 11.7 KB | Analyse du système de partage sur réseaux sociaux |
| `SHARE_SYSTEM_DESIGN.md` | 22.2 KB | Design du système de partage |
| `SOCIAL_FEATURES_ANALYSIS.md` | 8.4 KB | Analyse de fonctionnalités sociales type Strava |
| `PREMIUM_FEATURES.md` | 8.4 KB | Recommandations pour les fonctionnalités premium |

**Recommandation :** ces docs ont une valeur si les features sont encore envisagées. Si oui, les déplacer dans un dossier `docs/specs/` plutôt que de les laisser à la racine. Si les specs sont abandonnées, supprimer.

---

## 4. Résumé des recommandations

### Branches à supprimer (7 branches mortes)
```
design/test, feature/exercice, fetaure/exerciseSet,
feature/performedsession, feature/session, feature/auth, origin/master
```

### Restructuration des branches permanentes
- Renommer `production` → `main` (ou faire un merge propre)
- Créer `develop` comme intégration avant prod
- `main` actuelle (figée en avril 2025) → archiver ou supprimer

### Documents à supprimer (16 fichiers)
```
ANALYSE_PRET_PRODUCTION.md, MVP_BETA_CHECKLIST.md, PRODUCTION_CHECKLIST.md,
ONBOARDING_CHECKLIST.md, FIX_REFRESH_TOKEN_ERROR.md, DEV_REDIRECT_FIX.md,
README_ENV.md, SUPABASE_FREE_PLAN.md, RESEND_DNS_TROUBLESHOOTING.md,
RESEND_DNS_FIX.md, RESEND_NEXT_STEPS.md, RESEND_WAIT_GUIDE.md,
SMTP_SETUP.md, DOMAIN_CLARIFICATION.md, ADD_SERVICE_KEY.md, CHECK_SERVICE_KEY.md
```

### Documents à fusionner → nouvelles cibles

| Sources | Cible |
|---|---|
| `README.md` (réécrire) | `README.md` — présentation projet, install, démarrage |
| `ENV_SETUP.md` + `README_ENV.md` + `ADD_SERVICE_KEY.md` + `CHECK_SERVICE_KEY.md` | `docs/deployment.md` |
| `MIGRATIONS.md` + `SECURITY.md` + `PERFORMANCE_OPTIMIZATIONS.md` + `ADMIN_DASHBOARD.md` + `ACCOUNT_DELETION_TRACKING.md` + `PRODUCTION_ADMIN_PROTECTION.md` | `docs/architecture.md` |
| `RESEND_SETUP.md` + `RESEND_DNS_SETUP.md` + `RESEND_DELIVERABILITY_FIX.md` + `SUPABASE_SMTP_CONFIG.md` + `SUPABASE_DOMAIN_SETUP.md` + `SUPABASE_CUSTOM_DOMAIN_FIX.md` + `DOMAIN_MIGRATION.md` | `docs/deployment.md` (section email + domaine) |
| Specs features futures | `docs/specs/` (si toujours d'actualité) |

### Structure cible de la documentation
```
README.md                    ← présentation, install, démarrage rapide
CONTRIBUTING.md              ← workflow git, conventions (Phase 2)
docs/
  architecture.md            ← technique, BDD, sécurité, perf
  deployment.md              ← déploiement dev/prod, domaine, email
  specs/                     ← features futures (optionnel)
supabase/
  templates/README.md        ← conserver tel quel
```

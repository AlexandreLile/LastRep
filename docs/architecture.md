# Architecture — LastRep

## Vue d'ensemble

LastRep est une SPA Nuxt 3 (SSR désactivé) avec Supabase comme backend complet (Auth, PostgreSQL, RLS). Il n'y a pas de serveur applicatif propre — une seule route API server-side existe (`/api/admin/users`) pour les opérations d'administration nécessitant la service key.

```
Client (Vue 3 SPA)
  └── Supabase JS SDK (auth + requêtes DB directes)
  └── /api/admin/* (Nitro server — service key uniquement)
```

## Structure des répertoires

```
pages/          Routing Nuxt (SPA)
components/     UI organisé par domaine (charts/, sessions/, stats/, ui/)
composables/    Logique réutilisable et accès Supabase
middleware/     Guards d'authentification et admin
layouts/        default, auth, start-session
server/api/     Endpoints Nitro (admin uniquement)
supabase/
  migrations/   Migrations SQL versionnées
  templates/    Templates email Auth
```

## Base de données

### Schéma principal

| Table | Description |
|---|---|
| `workoutsession` | Séances d'entraînement (modèles) |
| `workoutexercise` | Exercices dans une séance |
| `exerciseset` | Séries (poids, reps, temps) |
| `performedsession` | Historique des séances effectuées |
| `exercise` | Référentiel d'exercices (public) |
| `exercise_muscles` | Association exercice ↔ muscles |
| `exercise_category` | Catégories d'exercices |
| `account_deletion_tracking` | Logs de suppressions de comptes |

### Migrations

Les migrations sont versionnées dans `supabase/migrations/` et gérées via Supabase CLI.

```bash
npm run db:new <nom_migration>  # Créer un fichier de migration horodaté
npm run db:push                  # Appliquer sur le projet lié
npm run db:status                # Voir l'état de chaque migration
npm run db:link                  # Lier à un projet Supabase (première fois)
```

**Règles :**
- Une migration = une modification logique (ne pas mélanger)
- Nommage descriptif : `add_exercise_muscles_table`, pas `migration1`
- Ne jamais modifier une migration déjà appliquée — créer une nouvelle migration corrective
- Toujours commiter les migrations dans Git avant de pousser en production

### Fonctions SQL personnalisées

| Fonction | Usage |
|---|---|
| `get_session_exercise_counts()` | Compte les exercices par session (évite le N+1) |
| `get_session_stats()` | Stats agrégées d'une session |
| `get_total_training_time()` | Temps total d'entraînement par user |
| `get_total_weight()` | Poids total soulevé par user |
| `delete_user_account()` | Suppression complète d'un compte |

Toutes les fonctions utilisent `SET search_path = public` et sont définies avec `SECURITY DEFINER` là où nécessaire.

## Sécurité

### Row Level Security (RLS)

RLS est activé sur toutes les tables contenant des données utilisateur. Principe général : `user_id = auth.uid()`.

| Table | Politique |
|---|---|
| `workoutsession` | user_id direct |
| `workoutexercise` | via session_id → workoutsession.user_id |
| `exerciseset` | user_id direct |
| `performedsession` | user_id direct |
| `exercise` | Lecture publique (pas de données perso) |
| `exercise_category` | Lecture publique |

**Ne jamais désactiver RLS.** Même avec RLS, vérifier le `user_id` côté application pour les opérations critiques.

### Authentification

Auth gérée par Supabase avec PKCE flow. Cinq plugins client Nuxt coordonnent l'initialisation, la restauration de session et le refresh automatique.

Middleware de protection :
- `auth.ts` — redirige vers `/login` si non connecté
- `admin.ts` — vérifie que l'utilisateur est admin (role Supabase)
- `public.ts` — exclut certaines routes de l'auth
- `check-training-session.global.js` — gestion de la session d'entraînement en cours

### Routes admin en production

Les routes `/admin/**` et `/api/admin/**` sont bloquées en production via `routeRules` dans `nuxt.config.ts` (redirect 404). Le dashboard admin n'est accessible qu'en local.

## Performances

### Optimisations en place

| Problème | Solution |
|---|---|
| N+1 queries sur l'historique | Fonction SQL `get_session_exercise_counts()` — 1 requête au lieu de N+1 |
| Stats rechargées à chaque render | `useStatsCache.js` — cache mémoire TTL 5 min |
| Requêtes stats dupliquées | `useUserStats.js` — point centralisé avec `Promise.all` |
| Bundle initial trop lourd | `defineAsyncComponent` sur les composants lourds (charts, calendrier) |
| Images non optimisées | `loading="lazy"` sur le logo sidebar, `loading="eager"` sur les pages auth |
| Logs en production | `utils/logger.js` — logging conditionnel désactivé en production |

### Points d'attention restants

- Pas de pagination sur l'historique des séances (impact quand > 100 séances)
- Recherche d'exercices sans debounce
- Les composants stats `*Supabase.vue` sont des doublons en cours de migration vers `useUserStats`

## Suppression de compte

La fonction `delete_user_account()` supprime toutes les données d'un utilisateur en cascade. Les suppressions sont tracées dans la table `account_deletion_tracking` avec timestamp, email hashé et motif.

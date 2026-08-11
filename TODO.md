# TODO

## Sécurité

- [ ] **Rotation des clés Supabase** — le project ref `jlfiuwpuixzvwcnsyxzw` est visible dans l'historique git (anciens fichiers markdown). Aucune clé n'a fuité, mais par précaution :
  1. Dashboard Supabase → Settings → API → Regenerate **anon key**
  2. Dashboard Supabase → Settings → API → Regenerate **service_role key**
  3. Mettre à jour les variables dans Vercel (prod + preview)
  4. Mettre à jour le `.env.local` en local

## Performance

Suite du bilan perf du mode entraînement / stats. Déjà corrigé : fan-out N+1 de la page exercice
(`pages/exercices/[id].vue` + composants enfants), boucle N+1 de `SessionWeightChart.vue`, bug
`dates`/`weights` non définis dans `WeightProgressionChart.vue`, composants stats legacy morts
supprimés (`SessionCount.vue`, `TotalWeightLifted.vue`, `TotalTrainingTime.vue`,
`LastSessionMaxWeightStats.vue`), et les 6× `auth.getUser()` redondants du dashboard.

- [ ] **`useExerciseStats.js`** — récupère toutes les lignes `exerciseset` de l'utilisateur sans
      limite puis regroupe côté client en O(n²) (`.reduce` + `.find`). À migrer vers une RPC
      `GROUP BY` côté SQL, sur le même modèle que `get_session_exercise_counts` (migration
      `20260113150000_add_get_session_exercise_counts_function.sql`).
- [ ] **`SessionRecap.vue`** — charge `allPreviousSets`, tout l'historique de séries pour les
      exercices de la dernière séance, sans borne temporelle ni pagination (pour calculer les PR).
      Grossit indéfiniment avec l'ancienneté du compte. À borner (ex : 90 derniers jours ou N
      dernières séances, comme le `.limit(50)` déjà utilisé plus bas dans le même fichier).
- [ ] **Requêtes séquentielles non parallélisées** — `LastSessionStats.vue` et `SessionRecap.vue`
      enchaînent 3-4 requêtes Supabase strictement l'une après l'autre alors que certaines
      pourraient partir en `Promise.all` (ex : chercher la séance précédente peut démarrer dès
      qu'on a `workout_session_id`, en parallèle du calcul du volume courant).
- [ ] **Duplication de `checkConnectivity`** — logique de vérification de connectivité réelle
      copiée à l'identique entre `composables/usePerformedSession.js` (`checkConnectivity`) et
      `utils/offlineTraining.js` (`checkRealConnectivity`). Pas un souci perf direct mais source de
      divergence de comportement offline si l'une évolue sans l'autre. À factoriser en un seul
      utilitaire partagé.
- [ ] **`useStatsCache.js` sans déduplication de promesses en vol** — au premier chargement à
      froid, si plusieurs composants montent en concurrence (ex : dashboard), chaque `withCache`
      peut lancer sa propre requête avant que la première ne pose le cache → doublons ponctuels.
      À corriger en mémorisant la promesse en cours par clé, pas seulement le résultat résolu.

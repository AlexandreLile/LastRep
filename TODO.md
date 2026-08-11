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
`LastSessionMaxWeightStats.vue`), les 6× `auth.getUser()` redondants du dashboard, l'agrégation
SQL de `useExerciseStats.js` (RPC `get_exercise_stats`), le bornage de `SessionRecap.vue` aux 50
séances précédentes déjà chargées, la parallélisation des requêtes indépendantes dans
`LastSessionStats.vue`/`SessionRecap.vue`, la déduplication de `checkConnectivity` (uniquement
`utils/offlineTraining.js` désormais), et la déduplication des promesses en vol dans
`useStatsCache.js`.

Rien de restant identifié pour l'instant sur ce périmètre.

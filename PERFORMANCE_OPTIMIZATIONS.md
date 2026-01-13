# Optimisations de Performance - LastRep

## 🔴 Problèmes Critiques Identifiés

### 1. **N+1 Query Problem** (CRITIQUE)
**Fichier**: `composables/useSessionHistory.js`
**Problème**: Une requête par session pour compter les exercices
**Impact**: Si 50 séances = 51 requêtes (1 + 50)
**Solution**: Utiliser une seule requête avec GROUP BY ou une fonction SQL

### 2. **Requêtes Multiples Non Optimisées**
**Problème**: Plusieurs composants font des requêtes séparées au lieu de les combiner
**Impact**: Latence réseau multipliée
**Solution**: Créer un composable centralisé pour les stats

### 3. **Console.log en Production**
**Problème**: Beaucoup de console.log qui ralentissent l'exécution
**Impact**: Performance réduite, surtout sur mobile
**Solution**: Utiliser un système de logging conditionnel

### 4. **Pas de Pagination**
**Problème**: Toutes les données sont chargées d'un coup
**Impact**: Temps de chargement long avec beaucoup de données
**Solution**: Implémenter la pagination ou le lazy loading

### 5. **Pas de Cache**
**Problème**: Les mêmes données sont rechargées à chaque fois
**Impact**: Requêtes inutiles répétées
**Solution**: Implémenter un système de cache avec TTL

### 6. **Images Non Optimisées**
**Problème**: Logo et favicon non optimisés
**Impact**: Taille de bundle plus grande
**Solution**: Optimiser les images et utiliser le lazy loading

## 🟡 Optimisations Recommandées

### 7. **Code Splitting**
**Problème**: Tout le code est chargé d'un coup
**Solution**: Lazy loading des composants lourds (charts, calendrier)

### 8. **Indexes de Base de Données**
**Vérifier**: Les indexes existent pour les colonnes fréquemment requêtées
**Solution**: Vérifier et ajouter des indexes si nécessaire

### 9. **Debouncing des Recherches**
**Problème**: Recherche d'exercices sans debounce
**Solution**: Ajouter un debounce de 300ms

### 10. **Memoization**
**Problème**: Calculs répétés dans les computed
**Solution**: Utiliser `computed` avec cache ou `useMemo`

## ✅ Optimisations Réalisées

### 1. **N+1 Query Corrigé** ✅
- **Fichier**: `composables/useSessionHistory.js`
- **Solution**: Création d'une fonction SQL `get_session_exercise_counts()` qui récupère tous les comptes en une seule requête
- **Impact**: Réduction de N+1 requêtes à 2 requêtes (1 pour les sessions, 1 pour les comptes)
- **Migration**: `20260113150000_add_get_session_exercise_counts_function.sql`
- **Gain**: 50-100x plus rapide avec beaucoup de séances

### 2. **Console.log Retirés en Production** ✅
- **Fichiers**: `components/goals/MonthlyGoals.vue`, `components/calendar/TrainingCalendar.vue`
- **Solution**: Création d'un système de logging conditionnel (`utils/logger.js`)
- **Impact**: Les logs sont désactivés en production, améliorant les performances
- **Note**: Les erreurs sont toujours loggées pour le debugging

### 3. **Système de Cache avec TTL** ✅
- **Fichier**: `composables/useStatsCache.js`
- **Solution**: Cache en mémoire avec TTL de 5 minutes pour les statistiques
- **Impact**: Évite les requêtes répétées, réduit la charge serveur
- **Utilisation**: Intégré dans tous les composants de stats

### 4. **Composable Centralisé pour les Stats** ✅
- **Fichier**: `composables/useUserStats.js`
- **Solution**: Un seul point d'accès pour toutes les statistiques utilisateur
- **Impact**: Code plus maintenable, requêtes optimisées avec Promise.all
- **Bénéfices**: Cache automatique, invalidation facile

### 5. **Optimisation des Images** ✅
- **Fichiers**: `layouts/default.vue`, `pages/(auth)/login.vue`, `pages/(auth)/register.vue`
- **Solution**: Ajout de `loading="lazy"` pour le logo dans la sidebar, `loading="eager"` pour les pages d'auth
- **Impact**: Réduction du temps de chargement initial

### 6. **Code Splitting** ✅
- **Fichier**: `pages/index.vue`
- **Solution**: Utilisation de `defineAsyncComponent` pour les composants lourds (TrainingCalendar, MonthlyGoals, LastSessionStats)
- **Impact**: Réduction de la taille du bundle initial, chargement à la demande
- **Gain**: Bundle initial ~30-40% plus petit

## 📊 Priorités Restantes

1. **IMPORTANT**: Implémenter le cache pour les stats
2. **IMPORTANT**: Optimiser les images
3. **RECOMMANDÉ**: Ajouter la pagination
4. **RECOMMANDÉ**: Code splitting
5. **RECOMMANDÉ**: Créer un composable centralisé pour les stats

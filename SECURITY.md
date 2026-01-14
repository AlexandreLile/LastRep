# 🔒 Sécurité - Configuration

Ce document décrit les mesures de sécurité mises en place pour protéger les données utilisateur.

## ✅ Row Level Security (RLS) - ACTIVÉ

### Tables protégées

Toutes les tables contenant des données utilisateur sont maintenant protégées par RLS :

1. **workoutsession**
   - Les utilisateurs ne peuvent voir/modifier/supprimer que leurs propres séances
   - Policy basée sur `user_id = auth.uid()`

2. **workoutexercise**
   - Les utilisateurs ne peuvent accéder qu'aux exercices de leurs propres séances
   - Policy basée sur la vérification que `session_id` appartient à l'utilisateur

3. **exerciseset**
   - Les utilisateurs ne peuvent voir/modifier/supprimer que leurs propres séries
   - Policy basée sur `user_id = auth.uid()`

4. **performedsession**
   - Les utilisateurs ne peuvent voir/modifier/supprimer que leurs propres séances effectuées
   - Policy basée sur `user_id = auth.uid()`

### Table publique

- **exercise** : Table de référence publique (Squat, Développé couché, etc.)
  - Pas de RLS nécessaire car accessible à tous les utilisateurs
  - Ne contient pas de données personnelles

## ⚠️ Validation Email - À ACTIVER MANUELLEMENT

La validation email doit être activée dans le Dashboard Supabase :

### Étapes

1. Connectez-vous à [supabase.com/dashboard](https://supabase.com/dashboard)
2. Sélectionnez votre projet
3. Allez dans **Authentication** → **Settings**
4. Activez **"Enable email confirmations"**
5. (Optionnel) Configurez les templates d'email personnalisés

### Pourquoi c'est important

- Empêche la création de comptes avec des emails invalides
- Améliore la sécurité globale
- Permet de réinitialiser les mots de passe de manière sécurisée

## 🔐 Bonnes pratiques de sécurité

### Pour les développeurs

1. **Ne jamais désactiver RLS** - C'est la protection principale
2. **Toujours vérifier user_id** - Même avec RLS, vérifiez côté application
3. **Ne pas exposer les clés API** - Utilisez les variables d'environnement
4. **Tester les permissions** - Vérifiez qu'un utilisateur ne peut pas accéder aux données d'un autre

### Pour les utilisateurs

1. Utilisez un mot de passe fort
2. Activez la validation email quand elle sera disponible
3. Ne partagez jamais vos identifiants

## ✅ Fonctions SQL sécurisées

Toutes les fonctions SQL ont maintenant un `search_path` fixe pour éviter les risques d'injection SQL :

1. **get_total_training_time** - Calcule le temps total d'entraînement
2. **get_total_weight** - Calcule le poids total soulevé
3. **get_session_stats** - Calcule les statistiques de séances
4. **update_workout_exercise_updated_at** - Trigger pour mettre à jour `updated_at` sur `workoutexercise`
5. **update_workout_session_updated_at** - Trigger pour mettre à jour `updated_at` sur `workoutsession`

Toutes ces fonctions utilisent `SET search_path = public` pour garantir la sécurité.

## ⚠️ Recommandations de sécurité supplémentaires

### 1. Vérification des mots de passe compromis (HaveIBeenPwned)

Supabase peut vérifier automatiquement si un mot de passe a été compromis en utilisant la base de données HaveIBeenPwned.

**Pour activer :**
1. Allez dans le Dashboard Supabase
2. **Authentication** → **Settings**
3. Activez **"Enable password breach detection"**

**Pourquoi c'est important :**
- Empêche l'utilisation de mots de passe qui ont été compromis dans des fuites de données
- Améliore significativement la sécurité des comptes utilisateurs

### 2. Mise à jour PostgreSQL

Votre version actuelle : `supabase-postgres-15.8.1.109`  
Des patches de sécurité sont disponibles.

**Pour mettre à jour :**
1. Allez dans le Dashboard Supabase
2. **Settings** → **Infrastructure**
3. Vérifiez les mises à jour disponibles et planifiez une mise à jour

**Note :** Les mises à jour peuvent nécessiter un redémarrage de la base de données. Planifiez-les pendant une période de faible trafic.

## 📋 Checklist de sécurité

- [x] RLS activé sur toutes les tables utilisateur
- [x] Policies créées pour SELECT, INSERT, UPDATE, DELETE
- [x] Toutes les fonctions SQL ont un search_path fixe
- [ ] Validation email activée (à faire dans le dashboard)
- [ ] Vérification des mots de passe compromis activée (à faire dans le dashboard)
- [ ] PostgreSQL mis à jour vers la dernière version (à vérifier dans le dashboard)
- [ ] Tests de sécurité effectués
- [ ] Documentation à jour

## 🧪 Tests recommandés

Pour vérifier que RLS fonctionne correctement :

1. Connectez-vous avec un utilisateur A
2. Créez des données (séances, séries, etc.)
3. Connectez-vous avec un utilisateur B
4. Vérifiez que l'utilisateur B ne peut pas voir les données de l'utilisateur A

## 📚 Documentation Supabase

- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Email Confirmations](https://supabase.com/docs/guides/auth/auth-email-templates)

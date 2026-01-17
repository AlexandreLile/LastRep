# 📊 Tracking des Suppressions de Compte

## ✅ Ce qui a été mis en place

### 1. Table de tracking (`account_deletion_log`)
- **Créée** : Migration `20260117120000_add_account_deletion_tracking.sql`
- **Stocke** : Email, user_id, date de suppression, métadonnées (nb séances, exercices)
- **Important** : L'email est conservé même après suppression du compte

### 2. Fonction SQL modifiée
- La fonction `delete_user_account` logge automatiquement AVANT de supprimer
- Les données sont enregistrées dans `account_deletion_log` avant la suppression

### 3. Tracking frontend
- **Clic sur le bouton** : Log dans la console quand l'utilisateur ouvre le dialog
- **Confirmation** : Log dans la console + enregistrement dans la base via la fonction SQL

---

## 🔍 Comment vérifier les suppressions

### Pour les FUTURS utilisateurs (après la migration)

#### Via SQL (Supabase Dashboard)
```sql
-- Voir toutes les suppressions
SELECT 
  id,
  email,
  deleted_at,
  metadata->>'session_count' as session_count,
  metadata->>'custom_exercise_count' as exercise_count,
  created_at
FROM account_deletion_log
ORDER BY deleted_at DESC;

-- Compter les suppressions par jour
SELECT 
  DATE(deleted_at) as date,
  COUNT(*) as count
FROM account_deletion_log
GROUP BY DATE(deleted_at)
ORDER BY date DESC;

-- Voir les suppressions d'un email spécifique
SELECT *
FROM account_deletion_log
WHERE email = 'user@example.com';
```

#### Via l'application (si tu veux créer une page admin)
```javascript
// Dans un composable ou page admin
const { data, error } = await supabase
  .from('account_deletion_log')
  .select('*')
  .order('deleted_at', { ascending: false })
```

---

## ⚠️ Pour les utilisateurs qui ont DÉJÀ supprimé leur compte

### Option 1 : Logs Supabase Auth (limité)
1. Va dans **Supabase Dashboard** → **Authentication** → **Users**
2. Regarde les utilisateurs supprimés (s'ils sont encore visibles)
3. **Limitation** : Les comptes supprimés peuvent ne plus être visibles

### Option 2 : Logs serveur/application
- Vérifie les logs de ton serveur (si tu as un backend)
- Vérifie les logs Supabase Edge Functions (si utilisées)
- Vérifie les logs de déploiement (Vercel, Netlify, etc.)

### Option 3 : Backups de base de données
- Si tu as des backups, tu peux comparer les utilisateurs avant/après
- Vérifie les exports de données

### Option 4 : Analytics externes (si configuré)
- Google Analytics
- Mixpanel
- Posthog
- etc.

---

## 📈 Exemple de requête pour analytics

```sql
-- Statistiques sur les suppressions
SELECT 
  COUNT(*) as total_deletions,
  AVG((metadata->>'session_count')::int) as avg_sessions_before_deletion,
  AVG((metadata->>'custom_exercise_count')::int) as avg_custom_exercises,
  MIN(deleted_at) as first_deletion,
  MAX(deleted_at) as last_deletion
FROM account_deletion_log;
```

---

## 🚀 Prochaines étapes (optionnel)

Si tu veux aller plus loin :

1. **Créer une page admin** pour visualiser les suppressions
2. **Ajouter des analytics** (Posthog, Mixpanel) pour tracker aussi les clics
3. **Envoyer un email** avant suppression (confirmation finale)
4. **Créer un dashboard** avec des graphiques de rétention

---

## ⚡ Important

- **Les suppressions passées** : Probablement trop tard sauf si tu as des backups/logs
- **Les suppressions futures** : Sont maintenant trackées automatiquement ✅

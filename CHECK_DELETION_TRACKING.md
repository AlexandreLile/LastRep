# 🔍 Vérifier le tracking des suppressions

## Problème : Les suppressions n'apparaissent pas dans le dashboard

### Causes possibles

1. **La migration n'a pas été appliquée**
   - La table `account_deletion_log` n'existe pas
   - La fonction `delete_user_account` n'a pas été mise à jour

2. **La fonction n'a pas loggé**
   - Erreur silencieuse lors de l'insertion
   - RLS bloque l'insertion

3. **Problème de matching email/user_id**
   - Les emails ne matchent pas (case sensitive, etc.)

---

## ✅ Vérifications à faire

### 1. Vérifier si la table existe

Dans Supabase Dashboard → SQL Editor, exécute :

```sql
SELECT * FROM account_deletion_log LIMIT 10;
```

**Si erreur "relation does not exist"** :
→ La migration n'a pas été appliquée. Applique `20260117120000_add_account_deletion_tracking.sql`

### 2. Vérifier si des suppressions ont été loggées

```sql
SELECT COUNT(*) as total_deletions FROM account_deletion_log;
```

Si 0, aucune suppression n'a été trackée.

### 3. Vérifier la fonction delete_user_account

```sql
SELECT pg_get_functiondef(oid) 
FROM pg_proc 
WHERE proname = 'delete_user_account';
```

Vérifie que la fonction contient `INSERT INTO public.account_deletion_log`.

### 4. Tester manuellement

```sql
-- Insérer un test (remplace par un vrai email)
INSERT INTO account_deletion_log (email, user_id, metadata)
VALUES ('test@example.com', '00000000-0000-0000-0000-000000000000', '{"test": true}');

-- Vérifier
SELECT * FROM account_deletion_log WHERE email = 'test@example.com';
```

---

## 🔧 Solutions

### Si la migration n'a pas été appliquée

1. Va dans Supabase Dashboard → Database → Migrations
2. Applique la migration `20260117120000_add_account_deletion_tracking.sql`
3. Ou via CLI : `npx supabase db push`

### Si la table existe mais vide

1. Vérifie les logs du serveur quand tu supprimes un compte
2. Regarde s'il y a des erreurs dans la console
3. Vérifie que la fonction `delete_user_account` a bien été mise à jour

### Si les données existent mais ne s'affichent pas

1. Regarde les logs du serveur (terminal où tourne `npm run dev`)
2. Tu devrais voir des messages de debug avec `🔍 Debug account_deletion_log`
3. Vérifie que les emails matchent (case insensitive)

---

## 📊 Debug dans le dashboard

Maintenant, quand tu charges le dashboard, regarde dans la console du serveur :

```
🔍 Debug account_deletion_log: { hasData: true, count: X, ... }
📋 Comptes supprimés trouvés: X
✅ Utilisateur supprimé détecté: { email: ..., user_id: ... }
```

Si tu vois `hasData: false` ou `count: 0`, la table est vide ou n'existe pas.

# 🚀 Appliquer le tracking des suppressions

## Problème

La migration `20260117120000_add_account_deletion_tracking.sql` n'a pas été appliquée sur ta base Supabase, donc :
- La table `account_deletion_log` n'existe pas
- La fonction `delete_user_account` ne logge pas les suppressions
- Le dashboard ne peut pas afficher les comptes supprimés

---

## ✅ Solution : Appliquer la migration

### Option 1 : Via Supabase Dashboard (Recommandé)

1. **Va sur [supabase.com/dashboard](https://supabase.com/dashboard)**
2. Sélectionne ton projet
3. Va dans **Database** → **Migrations**
4. Clique sur **"New migration"** ou **"Run SQL"**
5. **Copie-colle le contenu** du fichier `supabase/migrations/20260117120000_add_account_deletion_tracking.sql`
6. Clique sur **"Run"** pour exécuter

### Option 2 : Via Supabase CLI

```bash
# Si tu as le CLI configuré
npx supabase db push
```

---

## 📋 Contenu de la migration

Le fichier se trouve dans : `supabase/migrations/20260117120000_add_account_deletion_tracking.sql`

Il contient :
1. Création de la table `account_deletion_log`
2. Modification de la fonction `delete_user_account` pour logger les suppressions

---

## ✅ Vérification après application

Dans Supabase Dashboard → SQL Editor, exécute :

```sql
-- Vérifier que la table existe
SELECT * FROM account_deletion_log LIMIT 1;

-- Vérifier la fonction
SELECT pg_get_functiondef(oid) 
FROM pg_proc 
WHERE proname = 'delete_user_account';
```

Si ça fonctionne, tu verras la structure de la table et la fonction mise à jour.

---

## 🔄 Après l'application

1. **Les nouvelles suppressions** seront automatiquement trackées
2. **Le dashboard admin** pourra afficher les comptes supprimés
3. **Les suppressions passées** ne seront pas trackées (seulement les futures)

---

## ⚠️ Important

- Applique cette migration sur ta base de **production** (ou dev selon où tu testes)
- La migration est **sécurisée** (RLS activé, seulement service_role peut lire)
- Une fois appliquée, toutes les futures suppressions seront trackées automatiquement

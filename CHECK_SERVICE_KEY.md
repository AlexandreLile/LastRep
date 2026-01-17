# 🔑 Vérifier la Service Key

## ⚠️ Erreur : "Service key not configured"

Cette erreur signifie que `SUPABASE_SERVICE_KEY` n'est pas dans ton `.env.local` ou n'est pas accessible.

---

## ✅ Solution

### 1. Vérifier que `.env.local` contient la service key

Ouvre ton fichier `.env.local` et vérifie qu'il contient :

```env
SUPABASE_URL=https://ton-projet.supabase.co
SUPABASE_KEY=ton-anon-key
SUPABASE_SERVICE_KEY=ton-service-role-key  # ⚠️ IMPORTANT
```

### 2. Où trouver la Service Key ?

1. Va sur [supabase.com/dashboard](https://supabase.com/dashboard)
2. Sélectionne ton projet
3. Va dans **Settings** → **API**
4. Trouve la section **Project API keys**
5. Copie la clé **`service_role`** (⚠️ PAS la clé `anon` ou `public`)

### 3. Ajouter la service key dans `.env.local`

Ouvre `.env.local` et ajoute (ou modifie) :

```env
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (ta clé complète)
```

### 4. Redémarrer le serveur

**IMPORTANT** : Après avoir modifié `.env.local`, tu DOIS redémarrer le serveur :

```bash
# Arrête le serveur (Ctrl+C)
# Puis relance :
npm run dev
```

---

## 🔍 Vérification

Pour vérifier que la clé est bien chargée, tu peux ajouter temporairement dans `server/api/admin/users.get.ts` :

```typescript
console.log('Service key exists:', !!serviceKey)
```

Mais **ne laisse JAMAIS** cette ligne en production et ne log JAMAIS la clé complète !

---

## ⚠️ Sécurité

- ❌ **NE JAMAIS** commiter `.env.local` dans Git
- ❌ **NE JAMAIS** exposer la service key côté client
- ✅ La service key est **UNIQUEMENT** utilisée côté serveur dans l'API route
- ✅ Elle est automatiquement bloquée en production

---

## 🐛 Si ça ne fonctionne toujours pas

1. Vérifie que le fichier s'appelle bien `.env.local` (pas `.env` ou autre)
2. Vérifie qu'il n'y a pas d'espaces autour du `=` dans `.env.local`
3. Vérifie que la clé est complète (elle commence par `eyJ...` et fait ~200+ caractères)
4. Redémarre complètement le serveur (arrête et relance)
5. Vérifie dans la console du serveur s'il y a des erreurs au démarrage

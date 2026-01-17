# 🔑 Ajouter SUPABASE_SERVICE_KEY

## ⚠️ Problème détecté

La variable `SUPABASE_SERVICE_KEY` n'est **PAS** dans ton fichier `.env.local`.

---

## ✅ Solution : Ajouter la Service Key

### Étape 1 : Récupérer la Service Key

1. Va sur [supabase.com/dashboard](https://supabase.com/dashboard)
2. Sélectionne ton projet
3. Va dans **Settings** → **API**
4. Trouve la section **"Project API keys"**
5. Copie la clé **`service_role`** (⚠️ PAS `anon` ou `public`)

La clé ressemble à :
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdXJwcm9qZWN0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTYxNjIzOTAyMiwiZXhwIjoxOTMxODE1MDIyfQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Étape 2 : Ajouter dans `.env.local`

Ouvre ton fichier `.env.local` et ajoute cette ligne :

```env
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (colle ta clé complète ici)
```

**Exemple complet de `.env.local` :**

```env
SUPABASE_URL=https://ton-projet.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (anon key)
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (service_role key)
```

### Étape 3 : Redémarrer le serveur

**IMPORTANT** : Après avoir ajouté la clé, tu DOIS redémarrer le serveur :

```bash
# 1. Arrête le serveur (Ctrl+C dans le terminal où tourne npm run dev)
# 2. Relance :
npm run dev
```

### Étape 4 : Tester

Une fois le serveur redémarré, retourne sur `http://localhost:3000/admin/users`

---

## ⚠️ Points importants

1. **Pas d'espaces** autour du `=` : `SUPABASE_SERVICE_KEY=...` (pas `SUPABASE_SERVICE_KEY = ...`)
2. **Pas de guillemets** : `SUPABASE_SERVICE_KEY=eyJ...` (pas `SUPABASE_SERVICE_KEY="eyJ..."`)
3. **Clé complète** : La clé doit faire ~200+ caractères et commencer par `eyJ`
4. **Redémarrer** : Le serveur DOIT être redémarré après modification de `.env.local`

---

## 🔍 Vérification

Pour vérifier que la clé est bien ajoutée :

```bash
grep SUPABASE_SERVICE_KEY .env.local
```

Tu devrais voir la ligne avec ta clé.

---

## 🐛 Si ça ne fonctionne toujours pas

1. Vérifie que le fichier s'appelle bien `.env.local` (pas `.env`)
2. Vérifie qu'il n'y a pas de caractères invisibles ou d'espaces
3. Vérifie que la clé est complète (copie-colle depuis Supabase)
4. Redémarre complètement le serveur (arrête et relance)
5. Vérifie les logs du serveur au démarrage

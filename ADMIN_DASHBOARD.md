# 🔐 Dashboard Admin - Documentation

## ⚠️ IMPORTANT : LOCAL UNIQUEMENT

Ce dashboard admin est **UNIQUEMENT accessible en développement local** et ne doit **JAMAIS** être accessible en production.

---

## 📋 Fonctionnalités

Le dashboard admin permet de :
- ✅ Voir la liste de tous les utilisateurs
- ✅ Afficher email, prénom, nom de chaque utilisateur
- ✅ Voir les statistiques (total, actifs, emails confirmés)
- ✅ Voir la date d'inscription et dernière connexion
- ✅ Voir le statut de chaque compte (actif/inactif, email confirmé)

---

## 🚀 Utilisation

### Accéder au dashboard

1. Assure-toi d'être en **développement local** (`npm run dev`)
2. Connecte-toi avec un compte utilisateur
3. Va sur : `http://localhost:3000/admin/users`

### Prérequis

- ✅ Environnement de développement (pas de production)
- ✅ Variable `SUPABASE_SERVICE_KEY` configurée dans `.env.local`
- ✅ Être authentifié

---

## 🔒 Sécurité

### Protections mises en place

1. **Middleware `admin.ts`** :
   - ✅ Bloque automatiquement en production (`NODE_ENV === 'production'`)
   - ✅ Vérifie que l'utilisateur est authentifié
   - ✅ Redirige vers `/` si accès en production

2. **API Route `/api/admin/users.get.ts`** :
   - ✅ Vérifie l'environnement (bloque en production)
   - ✅ Utilise la service key (accès serveur uniquement)
   - ✅ Ne peut pas être appelée depuis le client directement

3. **Protection Nuxt** :
   - ✅ La route est dans `pages/admin/` (accessible uniquement si le middleware le permet)

### ⚠️ Ne JAMAIS :

- ❌ Déployer sans vérifier que `NODE_ENV === 'production'` bloque l'accès
- ❌ Exposer la `SUPABASE_SERVICE_KEY` côté client
- ❌ Retirer le middleware admin
- ❌ Modifier le code pour permettre l'accès en production

---

## 📁 Fichiers créés

```
middleware/
  └── admin.ts                    # Middleware de protection

server/
  └── api/
      └── admin/
          └── users.get.ts        # API route pour récupérer les utilisateurs

pages/
  └── admin/
      └── users.vue               # Page admin avec liste des utilisateurs
```

---

## 🧪 Test en local

1. Démarre le serveur de dev :
   ```bash
   npm run dev
   ```

2. Connecte-toi avec un compte

3. Va sur `http://localhost:3000/admin/users`

4. Tu devrais voir la liste des utilisateurs avec leurs informations

---

## 🚫 Vérification avant déploiement

Avant de déployer en production, vérifie que :

1. ✅ Le middleware `admin.ts` bloque bien en production
2. ✅ L'API route `/api/admin/users.get.ts` vérifie `NODE_ENV === 'production'`
3. ✅ Aucune route admin n'est accessible sans authentification
4. ✅ La `SUPABASE_SERVICE_KEY` n'est jamais exposée côté client

---

## 🔄 Améliorations futures (optionnel)

Si tu veux aller plus loin :

1. **Filtre par email** : Ajouter une recherche
2. **Export CSV** : Exporter la liste des utilisateurs
3. **Détails utilisateur** : Page de détail pour chaque utilisateur
4. **Actions admin** : Bannir/débannir, réinitialiser mot de passe, etc.
5. **Logs d'activité** : Voir les actions des utilisateurs

---

## 📝 Notes

- Le dashboard utilise la **service key** de Supabase pour accéder à `auth.users`
- Les données sont formatées pour afficher email, prénom, nom, dates, statuts
- L'interface est responsive et utilise les composants UI existants (shadcn)

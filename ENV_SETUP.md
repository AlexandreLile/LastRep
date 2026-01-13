# 🔧 Configuration des environnements Dev/Prod

Ce guide explique comment configurer des environnements séparés pour le développement et la production.

---

## 📋 Prérequis

Vous devez avoir **deux projets Supabase** :
1. **Un projet pour le développement** (dev)
2. **Un projet pour la production** (prod)

---

## 🚀 Configuration locale (Développement)

### 1. Créer le fichier `.env.local`

Copiez le fichier `.env.example` en `.env.local` :

```bash
cp .env.example .env.local
```

### 2. Remplir les variables d'environnement

Ouvrez `.env.local` et remplissez avec les valeurs de votre **projet Supabase DEV** :

```env
SUPABASE_URL=https://votre-projet-dev.supabase.co
SUPABASE_KEY=votre-anon-key-dev
SUPABASE_SERVICE_KEY=votre-service-role-key-dev
```

**Où trouver ces valeurs :**
- Dashboard Supabase → Votre projet DEV → Settings → API
- `SUPABASE_URL` : Project URL
- `SUPABASE_KEY` : anon/public key
- `SUPABASE_SERVICE_KEY` : service_role key (optionnel)

### 3. Vérifier que `.env.local` est dans `.gitignore`

Le fichier `.env.local` ne doit **jamais** être commité dans Git.

---

## 🌐 Configuration Vercel (Production)

### 1. Ajouter les variables d'environnement dans Vercel

1. Allez sur [vercel.com](https://vercel.com)
2. Sélectionnez votre projet
3. Allez dans **Settings** → **Environment Variables**
4. Ajoutez les variables suivantes avec les valeurs de votre **projet Supabase PROD** :

```
SUPABASE_URL = https://votre-projet-prod.supabase.co
SUPABASE_KEY = votre-anon-key-prod
SUPABASE_SERVICE_KEY = votre-service-role-key-prod (optionnel)
```

### 2. Assigner les variables aux environnements

Pour chaque variable, sélectionnez :
- ✅ **Production** (pour la prod)
- ✅ **Preview** (optionnel, pour les branches)
- ❌ **Development** (laisser vide, on utilise `.env.local` en local)

### 3. Redéployer

Après avoir ajouté les variables, redéployez votre application :
- Vercel → Deployments → Cliquez sur "..." → Redeploy

---

## 🔍 Vérification

### En développement local

```bash
npm run dev
```

Vérifiez dans la console que l'URL Supabase utilisée est celle de votre projet DEV.

### En production

1. Allez sur votre site en production
2. Ouvrez la console du navigateur (F12)
3. Vérifiez que l'URL Supabase utilisée est celle de votre projet PROD

---

## 📝 Structure des fichiers

```
LastRep/
├── .env.example          # Template (commité dans Git)
├── .env.local            # Variables locales DEV (dans .gitignore)
├── .env.production       # Variables prod (optionnel, dans .gitignore)
└── nuxt.config.ts        # Configuration Nuxt
```

---

## ⚠️ Important

### Sécurité

- ❌ **NE JAMAIS** commiter `.env.local` ou `.env.production` dans Git
- ❌ **NE JAMAIS** exposer `SUPABASE_SERVICE_KEY` côté client
- ✅ Toujours utiliser des projets Supabase séparés pour dev/prod
- ✅ Vérifier que les variables sont bien configurées avant de déployer

### Bonnes pratiques

1. **Base de données séparées** : Ne jamais utiliser la même base de données pour dev et prod
2. **Migrations** : Appliquer les migrations sur les deux projets
3. **Tests** : Toujours tester en dev avant de déployer en prod
4. **Backup** : Faire des backups réguliers de la base de données prod

---

## 🔄 Workflow recommandé

### Développement

1. Travailler en local avec `.env.local` (projet Supabase DEV)
2. Tester les migrations sur le projet DEV
3. Tester toutes les fonctionnalités en local

### Déploiement

1. Appliquer les migrations sur le projet PROD
2. Vérifier que les variables d'environnement sont bien configurées dans Vercel
3. Déployer sur Vercel
4. Tester en production

---

## 🐛 Dépannage

### Les variables ne sont pas chargées

1. Vérifiez que `.env.local` existe et contient les bonnes valeurs
2. Redémarrez le serveur de développement (`npm run dev`)
3. Vérifiez que les noms des variables sont corrects (sans espaces)

### Erreur "Invalid API key"

1. Vérifiez que vous utilisez la bonne clé (anon/public, pas service_role)
2. Vérifiez que l'URL du projet est correcte
3. Vérifiez que le projet Supabase est actif

### Erreur de connexion en production

1. Vérifiez les variables d'environnement dans Vercel
2. Vérifiez que les URLs de redirection sont bien configurées dans Supabase PROD
3. Redéployez l'application

---

## 📚 Ressources

- [Documentation Nuxt Environment Variables](https://nuxt.com/docs/guide/going-further/runtime-config)
- [Documentation Supabase Environment Variables](https://supabase.com/docs/guides/getting-started/local-development#environment-variables)
- [Documentation Vercel Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)

---

## ✅ Checklist

- [ ] Projet Supabase DEV créé
- [ ] Projet Supabase PROD créé
- [ ] `.env.local` créé avec les variables DEV
- [ ] Variables d'environnement ajoutées dans Vercel (PROD)
- [ ] `.env.local` dans `.gitignore`
- [ ] Testé en local avec le projet DEV
- [ ] Testé en production avec le projet PROD
- [ ] URLs de redirection configurées dans les deux projets Supabase

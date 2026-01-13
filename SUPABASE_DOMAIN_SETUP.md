# 🔧 Configuration Supabase pour app.lastrep.fr

## 📍 Étapes dans le Dashboard Supabase

### 1. Accéder à la Configuration d'Authentification

1. Allez sur [Supabase Dashboard](https://app.supabase.com)
2. **Sélectionnez votre projet de PRODUCTION** (pas le projet de dev)
3. Dans le menu de gauche, cliquez sur **Authentication**
4. Cliquez sur **URL Configuration** (dans le sous-menu)

### 2. Configurer le Site URL

Dans la section **Site URL** :
- Remplacez l'ancienne URL par : `https://app.lastrep.fr`
- ⚠️ **Important** : Gardez `http://localhost:3000` pour le développement local

### 3. Configurer les Redirect URLs

Dans la section **Redirect URLs**, vous devez avoir :

```
http://localhost:3000/auth/callback
http://127.0.0.1:3000/auth/callback
https://app.lastrep.fr/auth/callback
https://app.lastrep.fr/**
```

**Explication** :
- Les deux premières lignes sont pour le développement local
- `https://app.lastrep.fr/auth/callback` est l'URL exacte de callback
- `https://app.lastrep.fr/**` permet toutes les redirections sous ce domaine (utile pour les redirections internes)

### 4. Sauvegarder

1. Cliquez sur **Save** en bas de la page
2. Attendez la confirmation que les changements sont sauvegardés

## ⚠️ Points Importants

### Projet de Production vs Dev

Assurez-vous de modifier le **bon projet** :
- ✅ **PRODUCTION** : Le projet utilisé par Vercel en production
- ❌ **DEV** : Ne modifiez PAS le projet de dev (gardez localhost)

### Format des URLs

- ✅ **Correct** : `https://app.lastrep.fr/auth/callback`
- ❌ **Incorrect** : `app.lastrep.fr/auth/callback` (sans https)
- ❌ **Incorrect** : `https://app.lastrep.fr/auth/callback/` (avec slash final)

### Wildcards

- `https://app.lastrep.fr/**` permet toutes les redirections sous ce domaine
- Utile pour les redirections après connexion vers différentes pages

## 🧪 Vérification

Après avoir sauvegardé, testez :

1. Allez sur `https://app.lastrep.fr/login`
2. Cliquez sur "Se connecter avec Google" (ou autre méthode OAuth)
3. Après l'authentification, vous devriez être redirigé vers `https://app.lastrep.fr/auth/callback`
4. Puis automatiquement vers la page d'accueil

## 🐛 Dépannage

### Erreur "Invalid redirect URL"

Si vous voyez cette erreur :
1. Vérifiez que l'URL dans Supabase est **exactement** la même que celle utilisée dans le code
2. Vérifiez qu'il n'y a pas d'espace ou de caractère invisible
3. Vérifiez que vous avez bien sauvegardé les changements

### Redirection vers localhost en production

Si vous êtes redirigé vers localhost :
1. Vérifiez que vous avez bien modifié le projet de **PRODUCTION**
2. Vérifiez que les variables d'environnement Vercel sont correctes
3. Videz le cache du navigateur

### Erreur CORS

Si vous voyez des erreurs CORS :
1. Vérifiez que `https://app.lastrep.fr` est bien dans **Site URL**
2. Vérifiez que les variables d'environnement sont correctes

## 📸 Capture d'écran de Référence

La page devrait ressembler à ça :

```
┌─────────────────────────────────────────┐
│ Authentication > URL Configuration      │
├─────────────────────────────────────────┤
│                                         │
│ Site URL                                │
│ ┌─────────────────────────────────────┐ │
│ │ https://app.lastrep.fr              │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Redirect URLs                           │
│ ┌─────────────────────────────────────┐ │
│ │ http://localhost:3000/auth/callback│ │
│ │ http://127.0.0.1:3000/auth/callback │ │
│ │ https://app.lastrep.fr/auth/callback│ │
│ │ https://app.lastrep.fr/**           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│              [ Save ]                   │
└─────────────────────────────────────────┘
```

## ✅ Checklist

- [ ] Projet de PRODUCTION sélectionné (pas dev)
- [ ] Site URL mis à jour : `https://app.lastrep.fr`
- [ ] Redirect URLs contient : `https://app.lastrep.fr/auth/callback`
- [ ] Redirect URLs contient : `https://app.lastrep.fr/**`
- [ ] Les URLs de localhost sont toujours présentes pour le dev
- [ ] Changements sauvegardés
- [ ] Test effectué avec succès

# 🌐 Migration vers app.lastrep.fr

## 📋 Checklist de Migration

### 1. Configuration DNS
- [ ] Ajouter un enregistrement CNAME dans votre DNS pour `app.lastrep.fr`
- [ ] Pointer vers `cname.vercel-dns.com` (ou l'URL fournie par Vercel)
- [ ] Attendre la propagation DNS (peut prendre jusqu'à 48h, généralement quelques minutes)

### 2. Configuration Vercel
- [ ] Aller sur [Vercel Dashboard](https://vercel.com/dashboard)
- [ ] Sélectionner votre projet `LastRep`
- [ ] Aller dans **Settings** → **Domains**
- [ ] Ajouter le domaine `app.lastrep.fr`
- [ ] Vérifier que le domaine est validé et actif
- [ ] Vérifier que HTTPS est activé (automatique avec Vercel)

### 3. Configuration Supabase (CRITIQUE)
- [ ] Aller sur [Supabase Dashboard](https://app.supabase.com)
- [ ] Sélectionner votre projet de **PRODUCTION**
- [ ] Aller dans **Authentication** → **URL Configuration**
- [ ] Dans **Site URL**, mettre : `https://app.lastrep.fr`
- [ ] Dans **Redirect URLs**, ajouter :
  ```
  https://app.lastrep.fr/auth/callback
  https://app.lastrep.fr/**
  ```
- [ ] Supprimer l'ancien domaine si nécessaire (garder localhost pour le dev)
- [ ] Sauvegarder les changements

### 4. Configuration Google OAuth (si utilisé)
- [ ] Aller sur [Google Cloud Console](https://console.cloud.google.com)
- [ ] Sélectionner votre projet OAuth
- [ ] Aller dans **APIs & Services** → **Credentials**
- [ ] Modifier votre OAuth 2.0 Client ID
- [ ] Dans **Authorized JavaScript origins**, ajouter :
  ```
  https://app.lastrep.fr
  ```
- [ ] Dans **Authorized redirect URIs**, ajouter :
  ```
  https://app.lastrep.fr/auth/callback
  ```
- [ ] Sauvegarder les changements

### 5. Vérification du Code
Le code utilise déjà `window.location.origin`, donc il devrait automatiquement utiliser le bon domaine. Vérifiez que :
- [ ] `composables/useAuth.js` utilise `window.location.origin` pour les redirections
- [ ] Aucune URL codée en dur dans le code
- [ ] Les variables d'environnement Vercel sont correctes

### 6. Variables d'Environnement Vercel
Vérifiez que toutes les variables sont correctes dans Vercel :
- [ ] `SUPABASE_URL` : URL de votre projet Supabase PROD
- [ ] `SUPABASE_ANON_KEY` : Clé anonyme Supabase PROD
- [ ] `NUXT_PUBLIC_SUPABASE_URL` : Même que SUPABASE_URL
- [ ] `NUXT_PUBLIC_SUPABASE_KEY` : Même que SUPABASE_ANON_KEY

### 7. Tests Post-Migration
- [ ] Tester la connexion : `https://app.lastrep.fr/login`
- [ ] Tester l'inscription : `https://app.lastrep.fr/register`
- [ ] Tester OAuth Google : `https://app.lastrep.fr/login` → "Se connecter avec Google"
- [ ] Vérifier que la redirection après OAuth fonctionne
- [ ] Tester toutes les pages principales
- [ ] Vérifier que les images et assets se chargent correctement

## 🔧 Configuration DNS Détaillée

### Chez votre registrar DNS (ex: OVH, Cloudflare, etc.)

Ajoutez un enregistrement CNAME :
```
Type: CNAME
Nom: app
Valeur: cname.vercel-dns.com
TTL: 3600 (ou Auto)
```

**Note** : Vercel vous donnera l'URL exacte à utiliser lors de l'ajout du domaine dans leur dashboard.

## ⚠️ Points d'Attention

1. **Propagation DNS** : Peut prendre jusqu'à 48h, mais généralement quelques minutes
2. **Cache DNS** : Videz votre cache DNS local si nécessaire (`sudo dscacheutil -flushcache` sur Mac)
3. **HTTPS** : Vercel configure automatiquement HTTPS avec Let's Encrypt
4. **Ancien domaine** : Gardez l'ancien domaine actif pendant quelques jours pour la transition
5. **Emails** : Les emails de confirmation Supabase utiliseront le nouveau domaine

## 🐛 Dépannage

### Le domaine ne fonctionne pas
1. Vérifiez que le DNS est propagé : `dig app.lastrep.fr` ou `nslookup app.lastrep.fr`
2. Vérifiez que le domaine est validé dans Vercel
3. Vérifiez que HTTPS est activé

### Les redirections OAuth ne fonctionnent pas
1. Vérifiez que `https://app.lastrep.fr/auth/callback` est dans Supabase Redirect URLs
2. Vérifiez que Google OAuth a le bon domaine configuré
3. Vérifiez la console du navigateur pour les erreurs

### Erreurs CORS
1. Vérifiez que `https://app.lastrep.fr` est dans Supabase Site URL
2. Vérifiez que les variables d'environnement Vercel sont correctes

## 📝 Notes

- ✅ Le code actuel utilise `window.location.origin` dans `composables/useAuth.js` (ligne 190)
- ✅ Aucune modification de code n'est nécessaire pour le changement de domaine
- ✅ Le code s'adaptera automatiquement au nouveau domaine
- Assurez-vous de tester en production après la migration

## 🔍 Vérification du Code

Le code vérifié utilise déjà les bonnes pratiques :
- `composables/useAuth.js` : Utilise `window.location.origin` pour les redirections OAuth
- Aucune URL codée en dur trouvée dans le code
- Les redirections s'adapteront automatiquement au nouveau domaine

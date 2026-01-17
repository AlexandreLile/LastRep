# 🔒 Protection Dashboard Admin en Production

## ✅ Protections mises en place

Le dashboard admin est **triplement protégé** pour ne JAMAIS être accessible en production :

### 1. Middleware (`middleware/admin.ts`)
```typescript
if (process.env.NODE_ENV === 'production') {
  return navigateTo('/') // Redirige automatiquement
}
```

### 2. API Route (`server/api/admin/users.get.ts`)
```typescript
if (process.env.NODE_ENV === 'production') {
  throw createError({ statusCode: 403, ... }) // Bloque l'API
}
```

### 3. Route Rules (`nuxt.config.ts`)
```typescript
'/admin/**': process.env.NODE_ENV === 'production' 
  ? { redirect: { to: '/', statusCode: 404 } }
  : { ssr: false }
```

### 4. Build Exclusion (`nuxt.config.ts`)
- Les routes admin sont exclues du prerender en production
- Les fichiers admin ne sont pas inclus dans le build de production

---

## 🚀 Avant de déployer en production

### Checklist de sécurité

- [ ] Vérifier que `NODE_ENV=production` est bien défini en production
- [ ] Vérifier que les route rules bloquent bien `/admin/**` et `/api/admin/**`
- [ ] Tester que l'accès à `/admin/users` retourne une 404 en production
- [ ] Vérifier que `SUPABASE_SERVICE_KEY` n'est **PAS** dans les variables d'environnement de production
- [ ] S'assurer que le middleware `admin.ts` bloque bien en production

### Test en production

1. Déploie l'application
2. Essaie d'accéder à `https://ton-site.com/admin/users`
3. Tu devrais être redirigé vers `/` ou voir une 404
4. L'API `/api/admin/users` devrait retourner une erreur 403

---

## ⚠️ Important

- ❌ **NE JAMAIS** retirer les protections
- ❌ **NE JAMAIS** mettre `SUPABASE_SERVICE_KEY` en production
- ❌ **NE JAMAIS** modifier le middleware pour permettre l'accès en production
- ✅ Le dashboard admin est **UNIQUEMENT** pour le développement local

---

## 📁 Fichiers concernés

Ces fichiers sont **sécurisés** mais **seront dans le repo** :
- `pages/admin/users.vue` - Page admin (bloquée par middleware)
- `server/api/admin/users.get.ts` - API admin (bloquée par vérification)
- `middleware/admin.ts` - Middleware de protection

**C'est normal** qu'ils soient dans le repo, car les protections empêchent leur utilisation en production.

---

## 🔍 Vérification post-déploiement

Après déploiement, vérifie dans les logs :

```bash
# Si quelqu'un essaie d'accéder au dashboard admin
🚫 ADMIN DASHBOARD: Accès bloqué en production
```

Si tu vois ce message, les protections fonctionnent ! ✅

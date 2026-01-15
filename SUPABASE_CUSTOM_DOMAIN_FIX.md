# 🔧 Correction : URLs Supabase par défaut dans les emails et OAuth

## 🐛 Problème

Vous voyez des URLs comme `jlfiuwpuixzvwcnsyxzw.supabase.co` dans :
- Les emails de confirmation
- Les emails de réinitialisation de mot de passe
- Les redirections OAuth (Google, etc.)

Au lieu de votre domaine personnalisé `app.lastrep.fr`.

---

## ✅ Solution 1 : Vérifier la configuration Site URL (Gratuit)

### Dans le Dashboard Supabase

1. Allez sur [app.supabase.com](https://app.supabase.com)
2. Sélectionnez votre projet de **PRODUCTION**
3. **Authentication** → **URL Configuration**
4. Vérifiez que **Site URL** est bien : `https://app.lastrep.fr`
5. Vérifiez que **Redirect URLs** contient :
   ```
   https://app.lastrep.fr/auth/callback
   https://app.lastrep.fr/**
   ```

**Important :** Cette configuration contrôle où les utilisateurs sont redirigés APRÈS authentification, mais les liens dans les emails utilisent toujours le domaine Supabase par défaut.

---

## 💰 Solution 2 : Domaine personnalisé Supabase (Payant)

Pour que les emails et toutes les URLs utilisent votre domaine personnalisé, vous devez configurer un **Custom Domain** dans Supabase.

### Prérequis
- Plan Supabase Pro ou supérieur (ou add-on Custom Domain)
- Un sous-domaine disponible (ex: `api.lastrep.fr` ou `auth.lastrep.fr`)

### Configuration

1. **Dashboard Supabase** → **Settings** → **General** → **Custom Domains**
2. Ajoutez votre sous-domaine (ex: `api.lastrep.fr`)
3. Configurez le DNS avec un CNAME pointant vers votre projet Supabase
4. Vérifiez la propriété avec les enregistrements TXT fournis
5. Activez le domaine personnalisé

### Mise à jour des variables d'environnement

Une fois le domaine personnalisé activé, mettez à jour vos variables d'environnement :

**Vercel (Production) :**
```
SUPABASE_URL=https://api.lastrep.fr  (au lieu de https://jlfiuwpuixzvwcnsyxzw.supabase.co)
SUPABASE_KEY=votre-anon-key (reste identique)
```

**Note :** Le `SUPABASE_KEY` reste le même, seule l'URL change.

---

## 🔍 Vérification actuelle

### Vérifier quelle URL Supabase est utilisée

Dans votre console navigateur (F12), tapez :
```javascript
const supabase = useSupabaseClient()
console.log('Supabase URL:', supabase.supabaseUrl)
```

Cela vous montrera quelle URL Supabase est actuellement utilisée par votre application.

---

## ⚠️ Limitation actuelle

**Sans Custom Domain :**
- ✅ Les redirections OAuth peuvent utiliser `app.lastrep.fr` (si Site URL est bien configuré)
- ❌ Les liens dans les emails utilisent toujours `jlfiuwpuixzvwcnsyxzw.supabase.co`
- ❌ Les URLs de callback dans les emails utilisent le domaine Supabase par défaut

**Avec Custom Domain :**
- ✅ Toutes les URLs utilisent votre domaine personnalisé
- ✅ Les emails contiennent des liens avec votre domaine
- ✅ Expérience utilisateur cohérente

---

## 🎯 Recommandation

Pour l'instant, vous pouvez :
1. **Vérifier que Site URL est bien configuré** dans Supabase Dashboard
2. **Accepter que les emails contiennent l'URL Supabase** (c'est normal sans Custom Domain)
3. **Les utilisateurs seront quand même redirigés vers `app.lastrep.fr`** après avoir cliqué sur les liens dans les emails

Si vous voulez une expérience 100% avec votre domaine, il faudra configurer un Custom Domain Supabase (payant).

---

## 📝 Checklist

- [ ] Vérifier que Site URL = `https://app.lastrep.fr` dans Supabase Dashboard
- [ ] Vérifier que Redirect URLs contient `https://app.lastrep.fr/**`
- [ ] Tester une connexion OAuth (Google) - doit rediriger vers `app.lastrep.fr`
- [ ] Tester un email de réinitialisation - le lien fonctionne mais contient l'URL Supabase
- [ ] (Optionnel) Configurer Custom Domain si vous voulez que les emails utilisent votre domaine

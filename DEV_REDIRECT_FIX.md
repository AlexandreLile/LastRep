# 🔧 Fix : Redirection vers production en dev

## 🐛 Problème

Quand vous testez l'app en local, les redirections OAuth (Google) vous envoient toujours vers l'application en production au lieu de rester en local.

## 🔍 Cause

Supabase vérifie que l'URL de redirection est dans la liste des URLs autorisées. Si votre URL locale (`http://localhost:3000`) n'est pas dans cette liste, Supabase redirige vers l'URL de production par défaut.

## ✅ Solution

### Étape 1 : Ajouter l'URL locale dans Supabase Dashboard

1. Allez sur [Supabase Dashboard](https://app.supabase.com)
2. Sélectionnez votre projet
3. Allez dans **Authentication** > **URL Configuration**
4. Dans la section **Redirect URLs**, ajoutez :
   ```
   http://localhost:3000/auth/callback
   http://127.0.0.1:3000/auth/callback
   ```
5. Cliquez sur **Save**

### Étape 2 : Vérifier la configuration dans le code

Le code dans `composables/useAuth.js` utilise déjà `window.location.origin`, ce qui est correct :

```javascript
redirectTo: `${window.location.origin}/auth/callback`,
```

Cela devrait automatiquement utiliser :
- `http://localhost:3000/auth/callback` en local
- `https://votre-domaine.com/auth/callback` en production

### Étape 3 : Vérifier les variables d'environnement

Assurez-vous que vous utilisez bien les bonnes variables d'environnement en local.

Créez un fichier `.env.local` (si ce n'est pas déjà fait) :

```env
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=votre-clé-anon
```

**Important :** Ne commitez PAS ce fichier (il doit être dans `.gitignore`).

### Étape 4 : Vérifier le port local

Si vous utilisez un port différent de 3000, ajoutez-le aussi dans Supabase :

```
http://localhost:5173/auth/callback  # Si vous utilisez Vite avec port 5173
http://localhost:8080/auth/callback   # Si vous utilisez un autre port
```

## 🧪 Test

1. Démarrez votre app en local : `npm run dev`
2. Allez sur `http://localhost:3000/login`
3. Cliquez sur "Se connecter avec Google"
4. Après l'authentification Google, vous devriez être redirigé vers `http://localhost:3000/auth/callback` et non vers la production

## 🔍 Debug

Si ça ne fonctionne toujours pas :

1. **Vérifiez la console du navigateur** pour voir les erreurs
2. **Vérifiez l'URL de redirection** dans la requête OAuth :
   - Ouvrez les DevTools (F12)
   - Onglet Network
   - Cherchez la requête vers `supabase.co/auth/v1/authorize`
   - Vérifiez le paramètre `redirect_to` dans l'URL

3. **Vérifiez que vous êtes bien connecté au bon projet Supabase** :
   - Vérifiez que `SUPABASE_URL` dans votre `.env.local` correspond au projet de dev
   - Si vous avez plusieurs projets (dev/prod), assurez-vous d'utiliser le bon

## 📝 Note importante

**Les URLs de redirection doivent être exactement identiques** entre :
- Ce que vous passez dans `redirectTo`
- Ce qui est configuré dans Supabase Dashboard

Par exemple, si vous avez configuré `http://localhost:3000/auth/callback` dans Supabase, mais que votre app tourne sur `http://127.0.0.1:3000`, ça ne fonctionnera pas (même si c'est la même machine).

## 🚀 Solution alternative : Utiliser des variables d'environnement

Si vous voulez être plus explicite, vous pouvez utiliser une variable d'environnement :

```javascript
// composables/useAuth.js
const handleGoogleLogin = async () => {
  const redirectUrl = process.env.NODE_ENV === 'development'
    ? 'http://localhost:3000/auth/callback'
    : `${window.location.origin}/auth/callback`;
  
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: redirectUrl,
      // ...
    }
  });
};
```

Mais la solution avec `window.location.origin` devrait fonctionner si les URLs sont bien configurées dans Supabase.

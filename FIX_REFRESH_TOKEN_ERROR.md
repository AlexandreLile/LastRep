# 🔧 Fix : Erreur Refresh Token

## ⚠️ Erreur rencontrée

```
AuthApiError: Invalid Refresh Token: Refresh Token Not Found
```

Cette erreur se produit quand le refresh token stocké dans le localStorage est invalide ou expiré.

---

## ✅ Solutions

### Solution 1 : Nettoyer le localStorage (IMMÉDIAT)

**Dans la console du navigateur (F12)** :

```javascript
// Nettoyer tous les tokens Supabase
Object.keys(localStorage).forEach(key => {
  if (key.startsWith('sb-') || key.includes('supabase')) {
    localStorage.removeItem(key)
  }
})

// Nettoyer aussi les clés custom
localStorage.removeItem('authenticated')
localStorage.removeItem('auth_timestamp')

// Recharger la page
window.location.reload()
```

### Solution 2 : Se déconnecter et se reconnecter

1. Va sur `/login`
2. Clique sur "Se déconnecter" (si visible)
3. Ou vide manuellement le localStorage (Solution 1)
4. Reconnecte-toi

### Solution 3 : Mode navigation privée

1. Ouvre une fenêtre de navigation privée
2. Va sur ton site
3. Connecte-toi normalement

---

## 🔄 Ce qui a été corrigé automatiquement

Un plugin a été créé (`plugins/supabase-handle-refresh-error.client.js`) qui :
- ✅ Détecte automatiquement les erreurs de refresh token invalide
- ✅ Nettoie le localStorage automatiquement
- ✅ Redirige vers `/login` si nécessaire

**Mais** : Si l'erreur persiste, utilise la Solution 1 ci-dessus.

---

## 📋 Correction du Manifest

Le manifest.json a aussi été corrigé pour utiliser les bonnes tailles d'icônes (66x113 au lieu de 192x192/512x512).

---

## 🚀 Pour éviter ce problème à l'avenir

1. **Ne pas modifier manuellement le localStorage** des tokens Supabase
2. **Utiliser toujours `supabase.auth.signOut()`** pour se déconnecter
3. **Ne pas laisser les sessions expirer trop longtemps** (reconnecte-toi régulièrement)

---

## 🐛 Si le problème persiste

1. Vérifie que tu es bien connecté à la bonne instance Supabase (dev vs prod)
2. Vérifie que les variables d'environnement sont correctes
3. Vérifie que le projet Supabase est actif et accessible

# 🌐 Clarification : Domaines et Sous-domaines

## 📍 Différence entre les domaines

### `app.lastrep.fr` (Sous-domaine)
- **Usage** : Application web (Vercel)
- **Où configurer** : Vercel Dashboard → Domains
- **DNS** : CNAME pointant vers Vercel
- **Exemple** : `https://app.lastrep.fr`

### `lastrep.fr` (Domaine racine)
- **Usage** : Emails (Resend/SMTP)
- **Où configurer** : Resend Dashboard → Domains
- **DNS** : Enregistrements SPF, DKIM, DMARC pour les emails
- **Exemple** : `noreply@lastrep.fr`

---

## 🎯 Configuration par Service

### Vercel (Application Web)
- **Domaine à ajouter** : `app.lastrep.fr`
- **Type DNS** : CNAME
- **Valeur** : `cname.vercel-dns.com` (ou URL fournie par Vercel)
- **Où** : Chez votre registrar DNS (OVH, Cloudflare, etc.)

### Supabase (Authentification)
- **Site URL** : `https://app.lastrep.fr`
- **Redirect URLs** : `https://app.lastrep.fr/auth/callback`
- **Où** : Dashboard Supabase → Authentication → URL Configuration

### Resend (Emails SMTP)
- **Domaine à ajouter** : `lastrep.fr` (domaine racine)
- **Type DNS** : Enregistrements SPF, DKIM, DMARC
- **Sender email** : `noreply@lastrep.fr` (pas `noreply@app.lastrep.fr`)
- **Où** : Dashboard Resend → Domains → Add Domain

### Google OAuth (si utilisé)
- **Authorized JavaScript origins** : `https://app.lastrep.fr`
- **Authorized redirect URIs** : `https://app.lastrep.fr/auth/callback`
- **Où** : Google Cloud Console → Credentials

---

## 📋 Résumé Visuel

```
lastrep.fr (domaine racine)
├── app.lastrep.fr (sous-domaine)
│   └── Application web (Vercel)
│   └── Supabase Site URL
│   └── Google OAuth origins
│
└── lastrep.fr (domaine racine)
    └── Emails (Resend)
    └── noreply@lastrep.fr
    └── DNS: SPF, DKIM, DMARC
```

---

## ✅ Checklist

### Pour l'application web :
- [ ] `app.lastrep.fr` configuré dans Vercel
- [ ] CNAME DNS pointant vers Vercel
- [ ] `https://app.lastrep.fr` dans Supabase Site URL
- [ ] `https://app.lastrep.fr/auth/callback` dans Supabase Redirect URLs
- [ ] `https://app.lastrep.fr` dans Google OAuth

### Pour les emails :
- [ ] `lastrep.fr` configuré dans Resend
- [ ] Enregistrements DNS SPF/DKIM/DMARC ajoutés
- [ ] Domaine vérifié dans Resend (✅ vert)
- [ ] `noreply@lastrep.fr` configuré dans Supabase SMTP

---

## ⚠️ Erreurs Courantes

### ❌ Ne PAS faire :
- Ajouter `app.lastrep.fr` dans Resend (ça ne fonctionnera pas)
- Utiliser `noreply@app.lastrep.fr` comme sender email
- Mettre `lastrep.fr` dans Vercel (utilisez `app.lastrep.fr`)

### ✅ À faire :
- `app.lastrep.fr` → Vercel (application)
- `lastrep.fr` → Resend (emails)
- `noreply@lastrep.fr` → Sender email dans Supabase

---

## 🔍 Vérification

### Vérifier que tout est correct :

1. **Application web** :
   - `https://app.lastrep.fr` fonctionne ✅
   - OAuth redirige vers `https://app.lastrep.fr/auth/callback` ✅

2. **Emails** :
   - Emails envoyés depuis `noreply@lastrep.fr` ✅
   - Domaine `lastrep.fr` vérifié dans Resend ✅
   - DNS SPF/DKIM configurés ✅

---

## 💡 Pourquoi cette séparation ?

- **Séparation des responsabilités** : Web vs Email
- **Sécurité** : Les DNS pour emails sont différents de ceux pour le web
- **Flexibilité** : Vous pouvez changer de sous-domaine web sans affecter les emails
- **Bonnes pratiques** : Standard de l'industrie

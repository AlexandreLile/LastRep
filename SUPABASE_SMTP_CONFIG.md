# 📧 Configuration SMTP dans Supabase pour Resend

## 🎯 Où Aller dans Supabase

1. Allez sur [app.supabase.com](https://app.supabase.com)
2. **Sélectionnez votre projet de PRODUCTION**
3. Menu de gauche → **Authentication**
4. Cliquez sur **Settings** (ou cherchez "SMTP Settings")
5. Faites défiler jusqu'à **"SMTP Settings"**

---

## ✅ Ce qu'il faut Mettre dans Chaque Champ

### 1. Activez le Toggle
- ✅ **Enable Custom SMTP** : **ACTIVÉ** (toggle en haut)

### 2. Remplissez les Champs

```
┌─────────────────────────────────────────────────┐
│ Host: smtp.resend.com                          │
├─────────────────────────────────────────────────┤
│ Port: 587                                      │
├─────────────────────────────────────────────────┤
│ Username: resend                               │
├─────────────────────────────────────────────────┤
│ Password: [Collez votre API Key Resend ici]    │
│         (Format: re_xxxxxxxxxxxxxxxxxxxxx)     │
├─────────────────────────────────────────────────┤
│ Sender email:                                  │
│   • Si domaine PAS encore vérifié :            │
│     onboarding@resend.dev                      │
│   • Si domaine vérifié ✅ :                    │
│     noreply@lastrep.fr                         │
├─────────────────────────────────────────────────┤
│ Sender name: LastRep                           │
└─────────────────────────────────────────────────┘
```

---

## 📋 Valeurs Exactes à Copier-Coller

### Configuration de Base (toujours la même)

| Champ | Valeur |
|-------|--------|
| **Host** | `smtp.resend.com` |
| **Port** | `587` |
| **Username** | `resend` |
| **Password** | `[Votre API Key Resend]` (à copier depuis Resend Dashboard) |

### Sender Email (dépend de votre situation)

**Option 1 : Domaine de test (pour tester maintenant)**
```
Sender email: onboarding@resend.dev
```

**Option 2 : Domaine vérifié (une fois DNS OK)**
```
Sender email: noreply@lastrep.fr
```

### Sender Name (toujours la même)
```
Sender name: LastRep
```

---

## 🔑 Où Trouver votre API Key Resend

1. Allez sur [resend.com/emails](https://resend.com/emails)
2. Menu de gauche → **API Keys**
3. Vous verrez votre clé API (format : `re_xxxxxxxxxxxxxxxxxxxxx`)
4. **Cliquez sur "Copy"** ou **"Show"** pour la voir
5. **Collez-la dans le champ "Password" de Supabase**

⚠️ **IMPORTANT** : 
- La clé API commence toujours par `re_`
- Ne mettez PAS d'espaces avant/après
- Copiez toute la clé (elle est longue)

---

## 🎯 Configuration Complète Exemple

### Si vous utilisez le domaine de test (pour commencer)

```
✅ Enable Custom SMTP: ACTIVÉ

Host: smtp.resend.com
Port: 587
Username: resend
Password: re_AbCdEfGhIjKlMnOpQrStUvWxYz123456789
Sender email: onboarding@resend.dev
Sender name: LastRep
```

### Si votre domaine est vérifié (production)

```
✅ Enable Custom SMTP: ACTIVÉ

Host: smtp.resend.com
Port: 587
Username: resend
Password: re_AbCdEfGhIjKlMnOpQrStUvWxYz123456789
Sender email: noreply@lastrep.fr
Sender name: LastRep
```

---

## ✅ Checklist

Avant de sauvegarder, vérifiez :

- [ ] **Enable Custom SMTP** est bien activé (toggle vert)
- [ ] **Host** : `smtp.resend.com` (exactement comme ça)
- [ ] **Port** : `587` (chiffres uniquement)
- [ ] **Username** : `resend` (en minuscules)
- [ ] **Password** : Votre API Key Resend (commence par `re_`)
- [ ] **Sender email** : `onboarding@resend.dev` OU `noreply@lastrep.fr`
- [ ] **Sender name** : `LastRep` (ou autre nom de votre choix)

---

## 💾 Sauvegarder

1. Cliquez sur **"Save"** ou **"Update"** en bas de la page
2. Attendez le message de confirmation
3. ✅ C'est fait !

---

## 🧪 Tester la Configuration

### Test 1 : Email de test (si disponible dans Supabase)

1. Dans Supabase → Authentication → Settings → SMTP Settings
2. Cherchez un bouton **"Send test email"** ou **"Test SMTP"**
3. Entrez votre email personnel
4. Cliquez sur **"Send"**
5. Vérifiez votre boîte mail (et le dossier spam)

### Test 2 : Créer un compte de test

1. Allez sur `https://app.lastrep.fr/register`
2. Créez un compte avec un email valide
3. Vérifiez que l'email de confirmation arrive
4. Vérifiez qu'il n'est pas en spam

---

## ⚠️ Erreurs Courantes

### "Invalid credentials"
- ✅ Vérifiez que l'API Key est correcte (commence par `re_`)
- ✅ Vérifiez qu'il n'y a pas d'espaces avant/après
- ✅ Vérifiez que vous avez copié toute la clé

### "Connection timeout"
- ✅ Vérifiez que le Host est bien `smtp.resend.com`
- ✅ Vérifiez que le Port est bien `587`
- ✅ Vérifiez votre connexion internet

### "Sender email not verified"
- ✅ Si vous utilisez `noreply@lastrep.fr`, vérifiez que le domaine est vérifié dans Resend
- ✅ Si le domaine n'est pas encore vérifié, utilisez `onboarding@resend.dev` temporairement

---

## 🔄 Changer le Sender Email Plus Tard

Une fois votre domaine `lastrep.fr` vérifié dans Resend :

1. Retournez dans Supabase → Authentication → Settings → SMTP Settings
2. Changez **Sender email** de `onboarding@resend.dev` à `noreply@lastrep.fr`
3. Cliquez sur **"Save"**
4. ✅ C'est fait !

---

## 📞 Besoin d'Aide ?

Si ça ne fonctionne pas :
- Vérifiez les logs dans Resend Dashboard → Logs
- Vérifiez les logs dans Supabase Dashboard → Logs → Auth Logs
- Vérifiez que l'API Key est bien active dans Resend

---

## ✅ Résumé Ultra-Rapide

1. **Supabase** → Authentication → Settings → SMTP Settings
2. **Activer** "Enable Custom SMTP"
3. **Remplir** :
   - Host: `smtp.resend.com`
   - Port: `587`
   - Username: `resend`
   - Password: `[Votre API Key Resend]`
   - Sender: `onboarding@resend.dev` (test) ou `noreply@lastrep.fr` (prod)
   - Name: `LastRep`
4. **Sauvegarder**
5. **Tester** en créant un compte

**C'est tout !** 🎉

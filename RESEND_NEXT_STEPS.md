# ✅ Prochaines Étapes après Configuration DNS Resend

## 🔍 Étape 1 : Vérifier le Domaine dans Resend

1. Allez sur [Resend Dashboard](https://resend.com/domains)
2. Cliquez sur votre domaine **`lastrep.fr`**
3. Vérifiez que tous les enregistrements sont marqués ✅ verts :
   - ✅ Domain Verification (DKIM)
   - ✅ Enable Sending (SPF)
   - ✅ Enable Sending (MX)
   - ✅ DMARC (optionnel)

**⏱️ Temps** : La vérification peut prendre 5-30 minutes (parfois jusqu'à 48h)

**Si ce n'est pas encore vérifié** :
- Attendez quelques minutes
- Cliquez sur **"Verify"** ou **"Refresh"**
- Vérifiez que les enregistrements DNS sont corrects

---

## 🔧 Étape 2 : Mettre à Jour Supabase SMTP

Une fois le domaine vérifié dans Resend :

1. Allez sur [Supabase Dashboard](https://app.supabase.com)
2. Sélectionnez votre projet de **PRODUCTION**
3. Menu gauche → **Authentication** → **Settings**
4. Faites défiler jusqu'à **"SMTP Settings"**
5. Vérifiez que **"Enable Custom SMTP"** est activé
6. **Changez le Sender email** :
   - **Avant** : `onboarding@resend.dev` (domaine de test)
   - **Après** : `noreply@lastrep.fr` (votre domaine vérifié)
7. Cliquez sur **"Save"** ou **"Update"**

**Configuration complète :**
```
Host: smtp.resend.com
Port: 587
Username: resend
Password: [Votre API Key Resend]
Sender email: noreply@lastrep.fr  ← Changez ça !
Sender name: LastRep
```

---

## 🧪 Étape 3 : Tester

### Test 1 : Email de Confirmation

1. Allez sur `https://app.lastrep.fr/register`
2. Créez un compte avec un email valide
3. Vérifiez votre boîte mail
4. **Vérifiez que l'email vient de** `noreply@lastrep.fr` (pas `onboarding@resend.dev`)
5. Vérifiez qu'il n'est pas en spam
6. Cliquez sur le lien de confirmation
7. Vérifiez que le compte est bien activé

### Test 2 : Réinitialisation de Mot de Passe

1. Allez sur `https://app.lastrep.fr/reset-password`
2. Entrez votre email
3. Vérifiez que l'email arrive
4. Vérifiez que l'expéditeur est `noreply@lastrep.fr`
5. Cliquez sur le lien
6. Vérifiez que vous pouvez réinitialiser le mot de passe

---

## ✅ Checklist Finale

### DNS :
- [ ] Enregistrements DNS ajoutés chez votre registrar
- [ ] Propagation DNS terminée (5-30 min)
- [ ] Domaine vérifié dans Resend (✅ verts)

### Supabase :
- [ ] SMTP activé dans Supabase
- [ ] Sender email changé pour `noreply@lastrep.fr`
- [ ] Configuration sauvegardée

### Tests :
- [ ] Email de confirmation arrive bien
- [ ] Email vient de `noreply@lastrep.fr`
- [ ] Email de réinitialisation fonctionne
- [ ] Les emails ne vont pas en spam

---

## 🎉 Félicitations !

Une fois tout cela fait, votre configuration email est complète et professionnelle :
- ✅ Emails envoyés depuis votre propre domaine
- ✅ Meilleure réputation de délivrabilité
- ✅ Plus professionnel pour vos utilisateurs
- ✅ Prêt pour la production !

---

## 🐛 Si quelque chose ne fonctionne pas

### Le domaine ne se vérifie pas dans Resend

1. **Vérifiez les enregistrements DNS** :
   - Utilisez [mxtoolbox.com](https://mxtoolbox.com)
   - Tapez `resend._domainkey.lastrep.fr` → DNS Lookup
   - Vérifiez que l'enregistrement TXT apparaît

2. **Attendez la propagation** :
   - Peut prendre jusqu'à 48h
   - Généralement 5-30 minutes

3. **Vérifiez les valeurs** :
   - Pas d'espaces supplémentaires
   - Valeurs exactement comme indiqué
   - Types corrects (TXT, MX)

### Les emails n'arrivent pas

1. **Vérifiez les logs Resend** :
   - Dashboard Resend → **Logs** ou **Emails**
   - Vérifiez le statut des emails

2. **Vérifiez la configuration Supabase** :
   - Sender email correct (`noreply@lastrep.fr`)
   - API Key correcte
   - SMTP activé

3. **Vérifiez le dossier spam** :
   - Les emails peuvent arriver en spam au début
   - Ajoutez `noreply@lastrep.fr` à vos contacts

---

## 📊 Monitoring

### Dans Resend Dashboard

Vous pouvez surveiller :
- Nombre d'emails envoyés
- Taux de délivrabilité
- Bounces (emails non livrés)
- Plaintes de spam
- Statistiques par jour/mois

**Où** : Dashboard Resend → **Analytics** ou **Emails**

---

## 🚀 C'est tout !

Votre configuration email est maintenant complète. Les emails seront envoyés depuis `noreply@lastrep.fr` avec une bonne réputation de délivrabilité.

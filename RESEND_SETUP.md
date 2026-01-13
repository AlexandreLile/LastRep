# 📧 Configuration Resend pour app.lastrep.fr

## 🎯 Guide étape par étape

### Étape 1 : Créer un compte Resend

1. Allez sur [resend.com](https://resend.com)
2. Cliquez sur **"Sign Up"** ou **"Get Started"**
3. Créez un compte (email + mot de passe)
4. Vérifiez votre email

**⏱️ Temps estimé : 2 minutes**

---

### Étape 2 : Créer une API Key

1. Une fois connecté, allez dans **API Keys** (menu de gauche)
2. Cliquez sur **"Create API Key"**
3. Donnez un nom : `LastRep Production` (ou autre nom descriptif)
4. Sélectionnez les permissions : **"Sending access"** (par défaut)
5. Cliquez sur **"Add"**
6. **⚠️ IMPORTANT** : Copiez la clé API immédiatement (elle ne sera affichée qu'une seule fois !)
   - Format : `re_xxxxxxxxxxxxxxxxxxxxx`
   - Sauvegardez-la dans un gestionnaire de mots de passe ou fichier sécurisé

**⏱️ Temps estimé : 1 minute**

---

### Étape 3 : Ajouter votre domaine (app.lastrep.fr)

#### Option A : Utiliser le domaine de test (pour commencer rapidement)

1. Dans Resend, allez dans **Domains** (menu de gauche)
2. Vous verrez un domaine de test : `onboarding.resend.dev`
3. Vous pouvez l'utiliser pour tester immédiatement
4. **Sender email** : `onboarding@resend.dev`

**⏱️ Temps estimé : 0 minute (déjà disponible)**

#### Option B : Ajouter votre propre domaine (recommandé pour production)

1. Dans Resend, allez dans **Domains** (menu de gauche)
2. Cliquez sur **"Add Domain"**
3. Entrez votre domaine : `lastrep.fr` (sans le sous-domaine `app`)
4. Cliquez sur **"Add"**
5. Resend vous donnera des enregistrements DNS à ajouter :
   - **DKIM** : 3 enregistrements CNAME
   - **SPF** : 1 enregistrement TXT
   - **DMARC** : 1 enregistrement TXT (optionnel mais recommandé)

6. **Ajoutez ces enregistrements dans votre DNS** (chez votre registrar) :
   - Allez dans votre gestionnaire DNS (OVH, Cloudflare, etc.)
   - Ajoutez les enregistrements fournis par Resend
   - Attendez la propagation DNS (5-30 minutes généralement)

7. **Vérifiez le domaine** :
   - Retournez dans Resend → Domains
   - Cliquez sur **"Verify"** ou attendez la vérification automatique
   - Une fois vérifié, vous verrez un ✅ vert

8. **Sender email** : `noreply@lastrep.fr` ou `no-reply@lastrep.fr`

**⏱️ Temps estimé : 15-30 minutes (selon la propagation DNS)**

---

### Étape 4 : Configurer dans Supabase

1. Allez sur [Supabase Dashboard](https://app.supabase.com)
2. **Sélectionnez votre projet de PRODUCTION**
3. Menu de gauche → **Authentication**
4. Cliquez sur **Settings** (ou cherchez "SMTP Settings")
5. Faites défiler jusqu'à **"SMTP Settings"**
6. Activez **"Enable Custom SMTP"** (toggle en haut)

7. **Remplissez les champs** :

   ```
   Host: smtp.resend.com
   Port: 587
   Username: resend
   Password: [Collez votre API Key Resend ici]
   Sender email: onboarding@resend.dev (si domaine de test)
                  OU
                  noreply@lastrep.fr (si domaine vérifié)
   Sender name: LastRep
   ```

8. Cliquez sur **"Save"** ou **"Update"**

**⏱️ Temps estimé : 2 minutes**

---

### Étape 5 : Tester la configuration

#### Test 1 : Email de test dans Supabase (si disponible)

1. Dans Supabase → Authentication → Settings → SMTP Settings
2. Cherchez un bouton **"Send test email"** ou **"Test SMTP"**
3. Entrez votre email
4. Cliquez sur **"Send"**
5. Vérifiez votre boîte mail (et le dossier spam)

#### Test 2 : Créer un compte de test

1. Allez sur `https://app.lastrep.fr/register`
2. Créez un compte avec un email valide
3. Vérifiez que l'email de confirmation arrive
4. Vérifiez qu'il n'est pas en spam
5. Cliquez sur le lien de confirmation
6. Vérifiez que le compte est bien activé

#### Test 3 : Réinitialisation de mot de passe

1. Allez sur `https://app.lastrep.fr/reset-password`
2. Entrez votre email
3. Vérifiez que l'email arrive
4. Cliquez sur le lien
5. Vérifiez que vous pouvez réinitialiser le mot de passe

**⏱️ Temps estimé : 5 minutes**

---

## 📋 Checklist Complète

### Dans Resend :
- [ ] Compte créé sur resend.com
- [ ] API Key créée et copiée
- [ ] Domaine de test utilisé OU domaine personnalisé ajouté
- [ ] Si domaine personnalisé : enregistrements DNS ajoutés
- [ ] Si domaine personnalisé : domaine vérifié (✅ vert)

### Dans Supabase :
- [ ] Projet de PRODUCTION sélectionné
- [ ] Authentication → Settings → SMTP Settings
- [ ] "Enable Custom SMTP" activé
- [ ] Host : `smtp.resend.com`
- [ ] Port : `587`
- [ ] Username : `resend`
- [ ] Password : API Key Resend collée
- [ ] Sender email : configuré
- [ ] Sender name : `LastRep`
- [ ] Configuration sauvegardée

### Tests :
- [ ] Email de test envoyé avec succès
- [ ] Email de confirmation arrive bien
- [ ] Email de réinitialisation arrive bien
- [ ] Les emails ne vont pas en spam
- [ ] Les liens dans les emails fonctionnent

---

## 🔧 Configuration DNS pour votre domaine (Optionnel mais recommandé)

Si vous ajoutez `lastrep.fr` dans Resend, vous devrez ajouter ces enregistrements DNS :

### Exemple d'enregistrements (Resend vous donnera les vrais) :

```
Type: CNAME
Nom: resend._domainkey
Valeur: [valeur fournie par Resend]

Type: CNAME  
Nom: [autre clé DKIM]
Valeur: [valeur fournie par Resend]

Type: TXT
Nom: @
Valeur: v=spf1 include:resend.net ~all

Type: TXT
Nom: _dmarc
Valeur: v=DMARC1; p=none; rua=mailto:dmarc@lastrep.fr
```

**Où ajouter** : Chez votre registrar DNS (OVH, Cloudflare, etc.)

---

## ⚠️ Points Importants

### Sécurité
- ✅ **Ne partagez JAMAIS votre API Key Resend**
- ✅ Ne la commitez pas dans Git
- ✅ Stockez-la uniquement dans Supabase (champ Password)
- ✅ Si elle est compromise, supprimez-la et créez-en une nouvelle

### Domaines
- ✅ Pour tester rapidement : utilisez `onboarding@resend.dev`
- ✅ Pour la production : configurez `lastrep.fr` avec les DNS
- ✅ Une fois le domaine vérifié, changez le sender email dans Supabase

### Limites du plan gratuit
- ✅ **3,000 emails/mois** (gratuit)
- ✅ **100 emails/jour** (gratuit)
- ✅ Parfait pour commencer !

### Si vous dépassez les limites
- Resend vous enverra un email
- Vous pouvez passer au plan payant ($20/mois pour 50k emails)
- Ou utiliser un autre service (SendGrid, AWS SES)

---

## 🐛 Dépannage

### Les emails n'arrivent pas

1. **Vérifiez les logs Resend** :
   - Dashboard Resend → **Logs** ou **Emails**
   - Vérifiez le statut des emails envoyés
   - Regardez les erreurs éventuelles

2. **Vérifiez la configuration Supabase** :
   - Vérifiez que "Enable Custom SMTP" est bien activé
   - Vérifiez que tous les champs sont corrects
   - Vérifiez que l'API Key est bien collée (sans espaces)

3. **Vérifiez le dossier spam** :
   - Les emails peuvent arriver en spam au début
   - Ajoutez `noreply@lastrep.fr` à vos contacts

4. **Vérifiez les logs Supabase** :
   - Dashboard Supabase → **Logs** → **Auth Logs**
   - Cherchez les erreurs d'envoi d'email

### Erreur "Invalid credentials"

- Vérifiez que l'API Key est correcte
- Vérifiez que vous avez copié toute la clé (commence par `re_`)
- Vérifiez qu'il n'y a pas d'espaces avant/après

### Erreur "Domain not verified"

- Si vous utilisez un domaine personnalisé, vérifiez qu'il est bien vérifié dans Resend
- Vérifiez que les enregistrements DNS sont corrects
- Attendez la propagation DNS (peut prendre jusqu'à 48h)

---

## 📊 Monitoring

### Dans Resend Dashboard

Vous pouvez voir :
- Nombre d'emails envoyés
- Taux de délivrabilité
- Bounces (emails non livrés)
- Plaintes de spam
- Statistiques par jour/mois

**Où** : Dashboard Resend → **Analytics** ou **Emails**

---

## 🚀 Prochaines Étapes

Une fois Resend configuré :

1. ✅ **Personnaliser les templates d'email** dans Supabase
   - Dashboard Supabase → Authentication → Email Templates
   - Personnalisez les emails de confirmation, reset password, etc.

2. ✅ **Monitorer les envois**
   - Vérifiez régulièrement les logs Resend
   - Surveillez le taux de délivrabilité

3. ✅ **Configurer DMARC** (optionnel mais recommandé)
   - Améliore la réputation de votre domaine
   - Réduit les risques de spam

---

## 💡 Astuce

**Pour tester rapidement sans configurer de domaine** :
- Utilisez `onboarding@resend.dev` comme sender email
- Ça fonctionne immédiatement
- Vous pourrez changer pour votre domaine plus tard

---

## 🔗 Ressources

- [Resend Documentation](https://resend.com/docs)
- [Resend Dashboard](https://resend.com/emails)
- [Supabase SMTP Documentation](https://supabase.com/docs/guides/auth/auth-smtp)
- [Guide DNS Resend](https://resend.com/docs/dashboard/domains/introduction)

---

## ✅ Résumé Rapide

1. Créer compte Resend → Créer API Key
2. Dans Supabase → Authentication → Settings → SMTP Settings
3. Activer "Enable Custom SMTP"
4. Remplir :
   - Host: `smtp.resend.com`
   - Port: `587`
   - Username: `resend`
   - Password: `[Votre API Key]`
   - Sender: `onboarding@resend.dev` (test) ou `noreply@lastrep.fr` (prod)
5. Sauvegarder et tester !

**Total : ~10-15 minutes** 🎉

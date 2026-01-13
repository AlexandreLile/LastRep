# 📧 Configuration SMTP personnalisé pour Supabase

## ⚠️ Problème actuel

Vous utilisez actuellement le service email intégré de Supabase, qui :
- ✅ Fonctionne pour le développement et les tests
- ❌ A des **limites de taux** (rate limits)
- ❌ N'est **pas recommandé pour la production**
- ❌ Peut causer des emails non livrés si vous avez beaucoup d'utilisateurs

---

## 🎯 Solution : Configurer un SMTP personnalisé

Supabase permet de configurer votre propre service SMTP pour envoyer les emails d'authentification.

---

## 🚀 Options recommandées

### Option 1 : Resend (⭐ Recommandé - Simple et gratuit)

**Avantages :**
- ✅ Plan gratuit généreux (3,000 emails/mois)
- ✅ Très simple à configurer
- ✅ Interface moderne
- ✅ Excellent pour les startups
- ✅ Support français disponible

**Étapes :**

1. **Créer un compte Resend**
   - Allez sur [resend.com](https://resend.com)
   - Créez un compte gratuit
   - Vérifiez votre domaine (ou utilisez le domaine de test)

2. **Obtenir les credentials SMTP**
   - Dashboard Resend → **API Keys** → Créer une clé
   - Dashboard Resend → **Domains** → Ajouter votre domaine (ou utiliser le domaine de test)

3. **Configurer dans Supabase**
   - Dashboard Supabase → **Authentication** → **Settings** → **SMTP Settings**
   - Activez **"Enable Custom SMTP"**
   - Remplissez les champs :
     ```
     Host: smtp.resend.com
     Port: 587 (ou 465 pour SSL)
     Username: resend
     Password: [Votre API Key Resend]
     Sender email: noreply@votredomaine.com (ou onboarding@resend.dev pour test)
     Sender name: LastRep (ou le nom de votre app)
     ```

4. **Tester**
   - Créez un nouveau compte de test
   - Vérifiez que l'email arrive bien

**Limites du plan gratuit :**
- 3,000 emails/mois
- 100 emails/jour
- Parfait pour commencer !

**Prix après le gratuit :**
- $20/mois pour 50,000 emails
- $80/mois pour 200,000 emails

---

### Option 2 : SendGrid (⭐ Populaire - Très fiable)

**Avantages :**
- ✅ Plan gratuit : 100 emails/jour (3,000/mois)
- ✅ Très fiable et performant
- ✅ Bonne réputation de délivrabilité
- ✅ Analytics détaillées

**Étapes :**

1. **Créer un compte SendGrid**
   - Allez sur [sendgrid.com](https://sendgrid.com)
   - Créez un compte gratuit
   - Vérifiez votre email

2. **Créer une API Key**
   - Dashboard SendGrid → **Settings** → **API Keys**
   - Créez une clé avec les permissions "Mail Send"

3. **Configurer dans Supabase**
   - Dashboard Supabase → **Authentication** → **Settings** → **SMTP Settings**
   - Activez **"Enable Custom SMTP"**
   - Remplissez les champs :
     ```
     Host: smtp.sendgrid.net
     Port: 587
     Username: apikey
     Password: [Votre API Key SendGrid]
     Sender email: noreply@votredomaine.com
     Sender name: LastRep
     ```

**Limites du plan gratuit :**
- 100 emails/jour
- 3,000 emails/mois

**Prix après le gratuit :**
- $19.95/mois pour 50,000 emails

---

### Option 3 : Mailgun (⭐ Flexible)

**Avantages :**
- ✅ Plan gratuit : 5,000 emails/mois (3 mois)
- ✅ Très flexible
- ✅ Bonne API

**Étapes :**

1. **Créer un compte Mailgun**
   - Allez sur [mailgun.com](https://mailgun.com)
   - Créez un compte
   - Vérifiez votre domaine

2. **Obtenir les credentials SMTP**
   - Dashboard Mailgun → **Sending** → **Domain Settings**
   - Copiez les credentials SMTP

3. **Configurer dans Supabase**
   - Dashboard Supabase → **Authentication** → **Settings** → **SMTP Settings**
   - Activez **"Enable Custom SMTP"**
   - Utilisez les credentials de Mailgun

**Limites du plan gratuit :**
- 5,000 emails/mois (pendant 3 mois)
- Ensuite payant

---

### Option 4 : AWS SES (⭐ Économique à grande échelle)

**Avantages :**
- ✅ Très économique ($0.10 pour 1,000 emails)
- ✅ Très fiable (infrastructure AWS)
- ✅ Pas de limite sur le plan payant

**Inconvénients :**
- ❌ Plus complexe à configurer
- ❌ Nécessite un compte AWS
- ❌ Mode "sandbox" au début (limite d'envoi)

**Étapes :**

1. **Créer un compte AWS**
   - Allez sur [aws.amazon.com](https://aws.amazon.com)
   - Créez un compte AWS
   - Accédez à **SES (Simple Email Service)**

2. **Vérifier votre domaine**
   - AWS SES → **Verified identities** → Ajouter votre domaine
   - Configurez les enregistrements DNS

3. **Créer des credentials SMTP**
   - AWS SES → **SMTP settings** → Créer des credentials

4. **Configurer dans Supabase**
   - Utilisez les credentials SMTP d'AWS SES

**Prix :**
- $0.10 pour 1,000 emails
- Très économique à grande échelle

---

## 🎯 Recommandation pour votre projet

### Pour commencer (0-1,000 utilisateurs) :
**👉 Resend** ou **SendGrid** (plan gratuit)

**Pourquoi :**
- ✅ Simple à configurer
- ✅ Plan gratuit généreux
- ✅ Parfait pour valider votre produit
- ✅ Pas de carte bancaire nécessaire (pour Resend)

### Pour la croissance (1,000+ utilisateurs) :
**👉 Resend** (plan payant) ou **AWS SES**

**Pourquoi :**
- ✅ Économique
- ✅ Scalable
- ✅ Fiable

---

## 📋 Configuration dans Supabase - Étapes détaillées

### 1. Accéder aux paramètres SMTP

1. Connectez-vous à [supabase.com/dashboard](https://supabase.com/dashboard)
2. Sélectionnez votre projet
3. Allez dans **Authentication** → **Settings**
4. Faites défiler jusqu'à **"SMTP Settings"**
5. Cliquez sur **"Enable Custom SMTP"**

### 2. Remplir les champs

**Champs requis :**

- **Host** : L'adresse du serveur SMTP (ex: `smtp.resend.com`)
- **Port** : Le port SMTP (généralement `587` pour TLS ou `465` pour SSL)
- **Username** : Votre nom d'utilisateur SMTP
- **Password** : Votre mot de passe/clé API SMTP
- **Sender email** : L'email qui enverra les emails (ex: `noreply@votredomaine.com`)
- **Sender name** : Le nom affiché dans les emails (ex: `LastRep`)

### 3. Tester la configuration

1. Cliquez sur **"Send test email"** (si disponible)
2. Ou créez un nouveau compte de test
3. Vérifiez que l'email arrive bien
4. Vérifiez le dossier spam si nécessaire

### 4. Personnaliser les templates (optionnel)

Supabase permet de personnaliser les templates d'email :
- Email de confirmation
- Email de réinitialisation de mot de passe
- Email de changement d'email

**Où :** Dashboard Supabase → **Authentication** → **Email Templates**

---

## 🔒 Sécurité et bonnes pratiques

### 1. Utiliser un domaine personnalisé

**Pourquoi :**
- ✅ Meilleure réputation de délivrabilité
- ✅ Plus professionnel
- ✅ Moins de risque de spam

**Comment :**
- Configurez votre domaine dans votre service SMTP
- Ajoutez les enregistrements DNS requis
- Utilisez `noreply@votredomaine.com` comme sender email

### 2. Vérifier les emails de test

- ✅ Testez tous les types d'emails (confirmation, reset password, etc.)
- ✅ Vérifiez qu'ils arrivent bien
- ✅ Vérifiez qu'ils ne vont pas en spam
- ✅ Vérifiez le rendu sur mobile et desktop

### 3. Monitorer les envois

- Surveillez le taux de délivrabilité
- Surveillez les bounces (emails non livrés)
- Surveillez les plaintes de spam
- Ajustez si nécessaire

---

## 🧪 Test de la configuration

### Test 1 : Email de confirmation

1. Créez un nouveau compte avec un email valide
2. Vérifiez que l'email de confirmation arrive
3. Cliquez sur le lien de confirmation
4. Vérifiez que le compte est bien activé

### Test 2 : Réinitialisation de mot de passe

1. Allez sur la page de réinitialisation
2. Entrez votre email
3. Vérifiez que l'email arrive
4. Cliquez sur le lien
5. Vérifiez que vous pouvez réinitialiser le mot de passe

### Test 3 : Vérifier le spam

1. Vérifiez que les emails n'arrivent pas en spam
2. Si oui, configurez SPF, DKIM, DMARC (via votre service SMTP)

---

## 📊 Comparaison rapide

| Service | Plan gratuit | Prix après | Facilité | Recommandation |
|---------|--------------|------------|----------|----------------|
| **Resend** | 3,000/mois | $20/mois (50k) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ Début |
| **SendGrid** | 3,000/mois | $20/mois (50k) | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ Début |
| **Mailgun** | 5,000/mois (3 mois) | Payant après | ⭐⭐⭐ | ⭐⭐⭐ Court terme |
| **AWS SES** | Payant | $0.10/1k | ⭐⭐ | ⭐⭐⭐⭐ Grande échelle |

---

## 🚀 Action immédiate recommandée

**Pour votre projet, je recommande Resend :**

1. ✅ **Créer un compte Resend** (5 min)
   - [resend.com](https://resend.com)
   - Utilisez le domaine de test pour commencer

2. ✅ **Configurer dans Supabase** (5 min)
   - Dashboard Supabase → Authentication → Settings → SMTP Settings
   - Utilisez les credentials Resend

3. ✅ **Tester** (5 min)
   - Créez un compte de test
   - Vérifiez que l'email arrive

**Total : ~15 minutes** pour avoir un SMTP de production configuré ! 🎉

---

## 📝 Checklist

- [ ] Choisir un service SMTP (Resend recommandé)
- [ ] Créer un compte sur le service choisi
- [ ] Obtenir les credentials SMTP
- [ ] Configurer dans Supabase Dashboard
- [ ] Tester l'email de confirmation
- [ ] Tester l'email de réinitialisation
- [ ] Vérifier que les emails n'arrivent pas en spam
- [ ] (Optionnel) Configurer un domaine personnalisé
- [ ] (Optionnel) Personnaliser les templates d'email

---

## 🔗 Ressources

- [Documentation Supabase SMTP](https://supabase.com/docs/guides/auth/auth-smtp)
- [Resend Documentation](https://resend.com/docs)
- [SendGrid Documentation](https://docs.sendgrid.com)
- [Mailgun Documentation](https://documentation.mailgun.com)
- [AWS SES Documentation](https://docs.aws.amazon.com/ses)

---

## 💡 Note importante

**Même avec un SMTP personnalisé, vous devez toujours :**
- ✅ Activer la validation email (déjà fait ✅)
- ✅ Activer la vérification des mots de passe compromis
- ✅ Tester régulièrement que les emails arrivent bien
- ✅ Monitorer les taux de délivrabilité

Une fois le SMTP configuré, vous pourrez retirer l'avertissement dans Supabase ! 🎉

# Déploiement — LastRep

## Architecture des environnements

| Environnement | Branche Git | Supabase | Vercel | URL |
|---|---|---|---|---|
| Dev (local) | `develop` | Projet DEV | — | `localhost:3000` |
| Staging (preview) | `develop` | Projet DEV | Preview auto | URL Vercel preview |
| Production | `main` | Projet PROD | Production | `app.lastrep.fr` |

**Deux projets Supabase distincts sont nécessaires** — ne jamais utiliser le projet prod en local.

---

## Configuration locale

### 1. Variables d'environnement

```bash
cp .env.example .env.local
```

Remplir `.env.local` avec les valeurs du **projet Supabase DEV** :

```env
SUPABASE_URL=https://votre-projet-dev.supabase.co
SUPABASE_KEY=votre-anon-key-dev
SUPABASE_SERVICE_KEY=votre-service-role-key-dev
```

Ces valeurs se trouvent dans le Dashboard Supabase → Settings → API.

**Important :** `.env.local` ne doit jamais être commité (déjà dans `.gitignore`).

### 2. Démarrer

```bash
npm install
npm run dev
```

### 3. Appliquer les migrations sur le projet DEV

```bash
npm run db:link    # Lier au projet Supabase DEV (une seule fois)
npm run db:push    # Appliquer les migrations
```

---

## Déploiement production (Vercel)

### Variables d'environnement Vercel

Dans Vercel → Project Settings → Environment Variables, ajouter pour l'environnement **Production** :

```
NUXT_PUBLIC_SUPABASE_URL      = https://votre-projet-prod.supabase.co
NUXT_PUBLIC_SUPABASE_KEY      = votre-anon-key-prod
SUPABASE_SERVICE_KEY          = votre-service-role-key-prod
```

### Secrets GitHub Actions

Dans GitHub → Settings → Secrets and variables → Actions :

```
VERCEL_TOKEN          ← vercel.com → Account Settings → Tokens
VERCEL_ORG_ID         ← .vercel/project.json après `npx vercel link`
VERCEL_PROJECT_ID     ← idem

DEV_SUPABASE_URL          ← URL projet Supabase DEV
DEV_SUPABASE_ANON_KEY     ← clé anon DEV
DEV_SUPABASE_SERVICE_KEY  ← service key DEV

PROD_SUPABASE_URL         ← URL projet Supabase PROD
PROD_SUPABASE_ANON_KEY    ← clé anon PROD
PROD_SUPABASE_SERVICE_KEY ← service key PROD
```

Pour obtenir `VERCEL_ORG_ID` et `VERCEL_PROJECT_ID` :
```bash
npx vercel link
cat .vercel/project.json
```

### Désactiver l'auto-deploy Vercel

Pour éviter les doubles déploiements avec GitHub Actions :
Vercel → Project Settings → Git → décocher "Auto-deploy on push to main".

### GitHub Environments

Créer deux environnements dans GitHub → Settings → Environments :
- `development` — aucune restriction (déploiement automatique sur push `develop`)
- `production` — Required reviewers : toi → active le bouton de validation manuelle avant chaque déploiement prod

### Workflow de déploiement

```
PR vers develop → CI build check
Merge dans develop → deploy-dev.yml → Vercel preview

PR develop → main → CI build check + review manuelle
Merge dans main → deploy-prod.yml → validation GitHub Environment → Vercel prod
```

### Appliquer les migrations en production

Avant ou après le déploiement (selon le type de migration) :

```bash
# Lier au projet PROD (si pas déjà fait)
npx supabase link --project-ref <ref-prod>

# Appliquer
npm run db:push

# Vérifier
npm run db:status
```

---

## Configuration Supabase (projet PROD)

### URL et redirections Auth

Dans Supabase Dashboard → Authentication → URL Configuration :

```
Site URL :
  https://app.lastrep.fr

Redirect URLs :
  http://localhost:3000/auth/callback
  http://127.0.0.1:3000/auth/callback
  https://app.lastrep.fr/auth/callback
  https://app.lastrep.fr/**
```

### Confirmation email

Dans Authentication → Settings → activer **Enable email confirmations**.

### Sécurité supplémentaire (recommandé)

- Authentication → Settings → activer **Enable password breach detection** (HaveIBeenPwned)
- Settings → Infrastructure → vérifier les mises à jour PostgreSQL disponibles

---

## Email transactionnel — Resend

Les emails (confirmation, reset password) passent par Resend configuré comme SMTP dans Supabase.

### Setup initial Resend

1. Créer un compte sur [resend.com](https://resend.com)
2. Créer une API Key (permissions : Sending access)
3. Ajouter le domaine `lastrep.fr` dans Domains (pas `app.lastrep.fr`)
4. Configurer les enregistrements DNS (voir section ci-dessous)

### Configuration SMTP dans Supabase

Supabase Dashboard → Authentication → Settings → SMTP Settings :

```
Enable Custom SMTP : ON

Host     : smtp.resend.com
Port     : 587
Username : resend
Password : [API Key Resend]
Sender   : noreply@lastrep.fr
Name     : LastRep
```

### Enregistrements DNS pour `lastrep.fr`

À ajouter chez ton registrar (OVH, Cloudflare, etc.) :

| Type | Nom | Valeur |
|---|---|---|
| TXT | `resend._domainkey` | Clé DKIM fournie par Resend |
| TXT | `send` | `v=spf1 include:amazonses.com ~all` |
| MX | `send` | `feedback-smtp.eu-west-1.amazonses.com` (priorité 10) |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc@lastrep.fr;` |

Une fois les DNS ajoutés, vérifier dans Resend → Domains que tous les enregistrements sont **Verified** (vert). La propagation DNS peut prendre 15-30 minutes.

### Délivrabilité

- Démarrer avec 10-20 emails/jour les premières semaines (warm-up du domaine)
- Tester le score avec [mail-tester.com](https://mail-tester.com) (objectif > 8/10)
- Vérifier les blacklists avec [mxtoolbox.com](https://mxtoolbox.com)
- Une fois stable, passer DMARC à `p=quarantine`

### Templates email

Les templates personnalisés sont dans `supabase/templates/` et configurés dans Supabase → Authentication → Email Templates.

---

## Dépannage fréquent

**Variables d'env non chargées en local**
→ Vérifier que `.env.local` existe et relancer `npm run dev`

**"Invalid API key" Supabase**
→ Vérifier que tu utilises la clé `anon/public` (pas `service_role`) côté client

**Erreur de connexion en production**
→ Vérifier les variables dans Vercel + que les URLs de redirection sont dans Supabase PROD

**Emails qui arrivent en spam**
→ Vérifier que tous les DNS Resend sont **Verified** + tester sur mail-tester.com

**"DNS Record not found" dans Resend**
→ Attendre la propagation (jusqu'à 48h) + vérifier l'exactitude des enregistrements avec mxtoolbox.com

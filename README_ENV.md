# 🚀 Configuration rapide des environnements

## ⚡ Démarrage rapide

### 1. Créer le fichier `.env.local`

```bash
cp .env.example .env.local
```

### 2. Remplir avec vos credentials DEV

Ouvrez `.env.local` et remplissez avec les valeurs de votre **projet Supabase DEV** :

```env
SUPABASE_URL=https://votre-projet-dev.supabase.co
SUPABASE_KEY=votre-anon-key-dev
SUPABASE_SERVICE_KEY=votre-service-role-key-dev
```

**Où trouver ces valeurs :**
- Dashboard Supabase → Votre projet DEV → Settings → API

### 3. Configurer Vercel (Production)

1. Vercel → Settings → Environment Variables
2. Ajoutez les mêmes variables avec les valeurs de votre **projet Supabase PROD**
3. Assignez-les à **Production** uniquement

### 4. C'est tout ! 🎉

- En local : utilise automatiquement `.env.local` (DEV)
- En production : utilise les variables Vercel (PROD)

---

📖 Pour plus de détails, voir [ENV_SETUP.md](./ENV_SETUP.md)

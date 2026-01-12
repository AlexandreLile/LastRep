# Guide des Migrations Supabase

Ce projet utilise Supabase CLI pour gérer les migrations de base de données de manière versionnée et sécurisée.

## 📋 Prérequis

1. Avoir un projet Supabase créé sur [supabase.com](https://supabase.com)
2. Avoir les credentials de votre projet (URL et clé API)

## 🚀 Configuration initiale

### 1. Lier votre projet Supabase

```bash
npm run db:link
```

Vous devrez entrer :
- **Project Reference ID** : Trouvable dans les paramètres de votre projet Supabase (Settings > General > Reference ID)
- **Database Password** : Le mot de passe de votre base de données

### 2. Créer une migration initiale à partir de votre base existante

Si vous avez déjà une base de données avec des tables, récupérez le schéma actuel :

```bash
npm run db:dump
```

Cela créera une migration initiale dans `supabase/migrations/` avec l'état actuel de votre base.

## 📝 Utilisation quotidienne

### Créer une nouvelle migration

Quand vous voulez modifier la structure de la base de données :

```bash
npm run db:new nom_de_la_migration
```

Exemple :
```bash
npm run db:new add_user_profile_table
```

Cela créera un fichier dans `supabase/migrations/` avec un timestamp, par exemple :
```
supabase/migrations/20240115120000_add_user_profile_table.sql
```

### Éditer la migration

Ouvrez le fichier créé et ajoutez votre SQL :

```sql
-- Exemple : Ajouter une table
CREATE TABLE user_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  bio TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Exemple : Ajouter une colonne
ALTER TABLE workoutsession 
ADD COLUMN duration_minutes INTEGER;
```

### Appliquer les migrations en production

Une fois votre migration prête :

```bash
npm run db:push
```

⚠️ **Attention** : Cette commande applique les migrations directement sur votre base de production. Assurez-vous d'avoir testé votre migration en local d'abord.

### Voir l'état des migrations

```bash
npm run db:status
```

Affiche la liste de toutes les migrations et leur statut.

## 🔄 Workflow recommandé

1. **Créer la migration** : `npm run db:new ma_modification`
2. **Éditer le fichier SQL** dans `supabase/migrations/`
3. **Tester en local** (optionnel, nécessite Supabase local)
4. **Appliquer en production** : `npm run db:push`
5. **Vérifier** : `npm run db:status`

## 📁 Structure des fichiers

```
supabase/
├── config.toml          # Configuration Supabase
└── migrations/          # Vos migrations SQL versionnées
    ├── 20240101000000_initial_schema.sql
    ├── 20240115000000_add_user_profile.sql
    └── ...
```

## ⚠️ Bonnes pratiques

1. **Une migration = une modification logique**
   - Ne mélangez pas plusieurs modifications non liées dans une seule migration

2. **Nommez clairement vos migrations**
   - Utilisez des noms descriptifs : `add_user_profile_table` plutôt que `migration1`

3. **Testez avant de pousser**
   - Vérifiez votre SQL avant d'exécuter `db:push`

4. **Versionnez dans Git**
   - Commitez toujours vos migrations dans Git pour garder l'historique

5. **Ne modifiez jamais une migration déjà appliquée**
   - Créez une nouvelle migration pour corriger ou modifier

## 🔧 Commandes disponibles

| Commande | Description |
|----------|-------------|
| `npm run db:new <nom>` | Créer une nouvelle migration |
| `npm run db:push` | Appliquer les migrations en production |
| `npm run db:status` | Voir l'état des migrations |
| `npm run db:dump` | Récupérer le schéma actuel |
| `npm run db:link` | Lier le projet à Supabase |
| `npm run db:reset` | Réinitialiser la base locale (dev uniquement) |

## 📚 Documentation officielle

- [Supabase CLI Documentation](https://supabase.com/docs/guides/cli)
- [Migrations Guide](https://supabase.com/docs/guides/cli/local-development#database-migrations)

## 🆘 Dépannage

### Erreur "Project not linked"
Exécutez `npm run db:link` pour lier votre projet.

### Erreur de connexion
Vérifiez que vos credentials Supabase sont corrects dans `.env` ou via `supabase link`.

### Migration en conflit
Si deux développeurs créent des migrations en même temps, Supabase les appliquera dans l'ordre chronologique (timestamp).

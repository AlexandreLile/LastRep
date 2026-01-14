# 🏋️ Analyse : Ajout de fonctionnalités sociales (style Strava)

## 📊 Complexité globale : **MOYENNE** ⚠️

**Verdict :** C'est faisable, mais nécessite plusieurs ajouts importants à l'architecture actuelle.

---

## ✅ CE QUI EST DÉJÀ EN PLACE (Avantages)

1. ✅ **RLS bien configuré** - Base solide pour la sécurité
2. ✅ **Système de migrations** - Facilite l'ajout de nouvelles tables
3. ✅ **Authentification fonctionnelle** - Les utilisateurs existent déjà
4. ✅ **Architecture modulaire** - Facile d'ajouter de nouvelles fonctionnalités
5. ✅ **Performance optimisée** - Index déjà en place

---

## 🆕 CE QU'IL FAUDRAIT AJOUTER

### 1. Tables de base de données (Complexité : ⭐⭐ Facile)

#### Table `user_profile`
```sql
CREATE TABLE user_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  username VARCHAR(50) UNIQUE,
  display_name VARCHAR(100),
  bio TEXT,
  avatar_url TEXT,
  is_public BOOLEAN DEFAULT false, -- Séances publiques ou privées
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### Table `user_follows` (Système de suivi)
```sql
CREATE TABLE user_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id) -- Ne peut pas se suivre soi-même
);
```

#### Table `session_comments` (Commentaires sur les séances)
```sql
CREATE TABLE session_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  performed_session_id UUID REFERENCES performedsession(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### Table `session_likes` (Encouragements/Kudos)
```sql
CREATE TABLE session_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  performed_session_id UUID REFERENCES performedsession(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(performed_session_id, user_id) -- Un like par utilisateur
);
```

#### Table `challenges` (Défis entre utilisateurs)
```sql
CREATE TABLE challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  exercise_id UUID REFERENCES exercise(id),
  target_reps INTEGER,
  target_weight_kg NUMERIC,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);
```

### 2. Modifications des tables existantes (Complexité : ⭐ Facile)

#### Ajouter `is_public` à `performedsession`
```sql
ALTER TABLE performedsession 
ADD COLUMN is_public BOOLEAN DEFAULT false;
```

---

## 🔒 SÉCURITÉ (RLS) - Complexité : ⭐⭐⭐ Moyenne

Il faudra créer de nouvelles policies RLS pour chaque nouvelle table :

### Exemples de policies nécessaires :

**user_profile :**
- Les utilisateurs peuvent voir leur propre profil
- Les utilisateurs peuvent voir les profils publics
- Les utilisateurs peuvent voir les profils des personnes qu'ils suivent

**user_follows :**
- Les utilisateurs peuvent voir qui ils suivent
- Les utilisateurs peuvent voir qui les suit
- Les utilisateurs peuvent suivre/défollow uniquement eux-mêmes

**session_comments :**
- Les utilisateurs peuvent voir les commentaires sur les séances publiques
- Les utilisateurs peuvent commenter les séances publiques
- Les utilisateurs peuvent modifier/supprimer leurs propres commentaires

**session_likes :**
- Les utilisateurs peuvent voir les likes sur les séances publiques
- Les utilisateurs peuvent liker les séances publiques
- Les utilisateurs peuvent retirer leurs likes

---

## 🎨 INTERFACE UTILISATEUR - Complexité : ⭐⭐⭐⭐ Difficile

### Pages/Composants à créer :

1. **Page de profil utilisateur** (`/users/[username]`)
   - Affichage du profil
   - Statistiques publiques
   - Séances publiques
   - Bouton "Suivre"/"Ne plus suivre"

2. **Feed social** (`/feed`)
   - Liste des séances publiques des personnes suivies
   - Système de likes/commentaires
   - Filtres et tri

3. **Page de découverte** (`/discover`)
   - Utilisateurs à suivre
   - Séances publiques populaires
   - Défis actifs

4. **Page de défis** (`/challenges`)
   - Liste des défis
   - Création de défis
   - Participation aux défis

5. **Composants réutilisables :**
   - `UserCard.vue` - Carte utilisateur
   - `SessionCard.vue` - Carte de séance avec likes/comments
   - `FollowButton.vue` - Bouton suivre
   - `LikeButton.vue` - Bouton like
   - `CommentSection.vue` - Section commentaires

---

## 📱 FONCTIONNALITÉS À IMPLÉMENTER

### Niveau 1 - Basique (⭐ Facile, ~1-2 semaines)
- [ ] Profils utilisateurs publics/privés
- [ ] Système de suivi (follow/unfollow)
- [ ] Rendre les séances publiques/privées
- [ ] Feed des personnes suivies

### Niveau 2 - Intermédiaire (⭐⭐ Moyen, ~2-3 semaines)
- [ ] Système de likes sur les séances
- [ ] Commentaires sur les séances
- [ ] Notifications (nouvelles séances, likes, commentaires)
- [ ] Page de découverte d'utilisateurs

### Niveau 3 - Avancé (⭐⭐⭐ Difficile, ~3-4 semaines)
- [ ] Défis entre utilisateurs
- [ ] Leaderboards (classements)
- [ ] Groupes/Clubs
- [ ] Partage de séances
- [ ] Statistiques comparatives

---

## ⚠️ DÉFIS ET CONSIDÉRATIONS

### 1. Performance
- **Problème :** Le feed peut devenir lent avec beaucoup d'utilisateurs
- **Solution :** Pagination, cache, index supplémentaires

### 2. Notifications en temps réel
- **Problème :** Comment notifier les utilisateurs ?
- **Solution :** Supabase Realtime ou système de notifications push

### 3. Modération
- **Problème :** Comment gérer les commentaires inappropriés ?
- **Solution :** Système de signalement, modération manuelle

### 4. Vie privée
- **Problème :** Les utilisateurs veulent contrôler leur visibilité
- **Solution :** Options de confidentialité granulaires

### 5. Spam et abus
- **Problème :** Comment éviter le spam de follows/likes ?
- **Solution :** Rate limiting, détection de comportement suspect

---

## 💰 COÛT EN TEMPS ESTIMÉ

### Phase 1 - Fondations (2-3 semaines)
- Tables de base de données
- RLS policies
- Profils utilisateurs basiques
- Système de suivi

### Phase 2 - Interactions (2-3 semaines)
- Likes et commentaires
- Feed social
- Notifications basiques

### Phase 3 - Fonctionnalités avancées (3-4 semaines)
- Défis
- Leaderboards
- Optimisations

**Total estimé : 7-10 semaines** pour une implémentation complète

---

## 🚀 RECOMMANDATION

### Approche progressive :

1. **Commencez simple :**
   - Ajoutez les profils utilisateurs
   - Ajoutez le système de suivi
   - Rendez les séances publiques/privées optionnelles

2. **Testez avec des utilisateurs bêta :**
   - Collectez du feedback
   - Identifiez les fonctionnalités les plus demandées

3. **Ajoutez les interactions :**
   - Likes
   - Commentaires
   - Feed

4. **Fonctionnalités avancées :**
   - Défis
   - Leaderboards
   - Groupes

---

## ✅ CONCLUSION

**C'est faisable, mais c'est un projet significatif.**

- **Complexité technique :** Moyenne
- **Temps nécessaire :** 2-3 mois pour une version complète
- **Valeur ajoutée :** Élevée (engagement utilisateur)

**Mon conseil :** Commencez par les fonctionnalités de base (profils + suivi) et itérez selon le feedback des utilisateurs.

---

## 📚 Ressources utiles

- [Supabase Realtime](https://supabase.com/docs/guides/realtime) - Pour les notifications en temps réel
- [Supabase Storage](https://supabase.com/docs/guides/storage) - Pour les avatars
- [RLS avec relations complexes](https://supabase.com/docs/guides/auth/row-level-security#policies-with-joins)

# 🏋️ Analyse : Système de coaching

## 📊 Complexité globale : **MOYENNE à ÉLEVÉE** ⚠️

**Verdict :** C'est faisable mais nécessite plusieurs ajouts importants : système de rôles, relations coach-élève, et interface de gestion.

---

## 🎯 FONCTIONNALITÉS REQUISES

### 1. Système de rôles
- **Coach** : Peut gérer plusieurs élèves, voir/modifier leurs séances, commenter
- **Élève** : Utilisateur normal qui peut avoir un ou plusieurs coaches
- **Admin** (optionnel) : Gestion globale

### 2. Relations coach-élève
- Un coach peut avoir plusieurs élèves
- Un élève peut avoir plusieurs coaches
- Relation bidirectionnelle avec statut (en attente, accepté, refusé)

### 3. Permissions spéciales
- Coach peut voir les séances de ses élèves
- Coach peut modifier les séances de ses élèves
- Coach peut commenter les séances
- Coach peut créer des séances pour ses élèves

### 4. Interface coach
- Dashboard avec liste des élèves
- Vue détaillée de chaque élève
- Gestion des séances
- Système de commentaires

---

## 🗄️ STRUCTURE DE BASE DE DONNÉES

### 1. Table `user_roles` - Rôles utilisateurs

```sql
CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'coach', 'admin')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role);
```

### 2. Table `coach_student_relationships` - Relations coach-élève

```sql
CREATE TABLE coach_student_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'ended')),
  invited_by UUID REFERENCES auth.users(id), -- Qui a initié la relation
  accepted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(coach_id, student_id),
  CHECK (coach_id != student_id) -- Un coach ne peut pas être son propre élève
);

-- Index
CREATE INDEX idx_coach_student_coach_id ON coach_student_relationships(coach_id);
CREATE INDEX idx_coach_student_student_id ON coach_student_relationships(student_id);
CREATE INDEX idx_coach_student_status ON coach_student_relationships(status);
```

### 3. Table `coach_comments` - Commentaires des coaches

```sql
CREATE TABLE coach_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  performed_session_id UUID REFERENCES performedsession(id) ON DELETE CASCADE,
  coach_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_private BOOLEAN DEFAULT false, -- Commentaire privé (visible seulement par le coach et l'élève)
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index
CREATE INDEX idx_coach_comments_session_id ON coach_comments(performed_session_id);
CREATE INDEX idx_coach_comments_coach_id ON coach_comments(coach_id);
```

### 4. Modifications des tables existantes

```sql
-- Ajouter une colonne pour savoir qui a créé/modifié la séance
ALTER TABLE performedsession 
ADD COLUMN created_by UUID REFERENCES auth.users(id),
ADD COLUMN last_modified_by UUID REFERENCES auth.users(id);

-- Mettre à jour created_by avec user_id pour les séances existantes
UPDATE performedsession 
SET created_by = user_id 
WHERE created_by IS NULL;
```

---

## 🔒 SÉCURITÉ (RLS) - Complexité : ⭐⭐⭐⭐ Élevée

### Nouvelles policies nécessaires

#### 1. `user_roles` - Seul l'utilisateur peut voir son rôle
```sql
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own role"
  ON user_roles FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own role"
  ON user_roles FOR UPDATE
  USING ((SELECT auth.uid()) = user_id);
```

#### 2. `coach_student_relationships` - Coach et élève peuvent voir leur relation
```sql
ALTER TABLE coach_student_relationships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Coaches can view their students"
  ON coach_student_relationships FOR SELECT
  USING (
    (SELECT auth.uid()) = coach_id 
    OR (SELECT auth.uid()) = student_id
  );

CREATE POLICY "Coaches can manage relationships"
  ON coach_student_relationships FOR ALL
  USING (
    (SELECT auth.uid()) = coach_id 
    OR (SELECT auth.uid()) = student_id
  );
```

#### 3. `coach_comments` - Coach et élève peuvent voir les commentaires
```sql
ALTER TABLE coach_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Coach and student can view comments"
  ON coach_comments FOR SELECT
  USING (
    (SELECT auth.uid()) = coach_id
    OR EXISTS (
      SELECT 1 FROM performedsession ps
      WHERE ps.id = coach_comments.performed_session_id
      AND ps.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Coaches can create comments"
  ON coach_comments FOR INSERT
  WITH CHECK (
    (SELECT auth.uid()) = coach_id
    AND EXISTS (
      SELECT 1 FROM performedsession ps
      JOIN coach_student_relationships csr 
        ON csr.student_id = ps.user_id 
        AND csr.coach_id = (SELECT auth.uid())
        AND csr.status = 'accepted'
      WHERE ps.id = coach_comments.performed_session_id
    )
  );

CREATE POLICY "Coaches can update their comments"
  ON coach_comments FOR UPDATE
  USING ((SELECT auth.uid()) = coach_id);
```

#### 4. Modifier les policies de `performedsession` - Coach peut voir/modifier les séances de ses élèves
```sql
-- Policy supplémentaire : Les coaches peuvent voir les séances de leurs élèves
CREATE POLICY "Coaches can view their students' sessions"
  ON performedsession FOR SELECT
  USING (
    (SELECT auth.uid()) = user_id
    OR EXISTS (
      SELECT 1 FROM coach_student_relationships csr
      WHERE csr.coach_id = (SELECT auth.uid())
      AND csr.student_id = performedsession.user_id
      AND csr.status = 'accepted'
    )
  );

-- Policy supplémentaire : Les coaches peuvent modifier les séances de leurs élèves
CREATE POLICY "Coaches can update their students' sessions"
  ON performedsession FOR UPDATE
  USING (
    (SELECT auth.uid()) = user_id
    OR EXISTS (
      SELECT 1 FROM coach_student_relationships csr
      WHERE csr.coach_id = (SELECT auth.uid())
      AND csr.student_id = performedsession.user_id
      AND csr.status = 'accepted'
    )
  )
  WITH CHECK (
    (SELECT auth.uid()) = user_id
    OR EXISTS (
      SELECT 1 FROM coach_student_relationships csr
      WHERE csr.coach_id = (SELECT auth.uid())
      AND csr.student_id = performedsession.user_id
      AND csr.status = 'accepted'
    )
  );
```

---

## 🎨 INTERFACE UTILISATEUR

### 1. Dashboard Coach (`/coach/dashboard`)

```
┌─────────────────────────────────────────────────┐
│  🏋️ Dashboard Coach                            │
├─────────────────────────────────────────────────┤
│                                                 │
│  Mes élèves (12)                                │
│  ┌─────────────────────────────────────────┐   │
│  │  👤 Alexandre Lile                      │   │
│  │  📅 Dernière séance : Il y a 2 jours   │   │
│  │  💪 3 séances cette semaine            │   │
│  │  [👁️ Voir le profil]                   │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  [➕ Inviter un élève]                         │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 2. Profil d'un élève (`/coach/students/[id]`)

```
┌─────────────────────────────────────────────────┐
│  ← Retour                                       │
│                                                 │
│  👤 Alexandre Lile                             │
│  📧 alexandre@example.com                      │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Statistiques                           │   │
│  │  • Séances totales : 45                 │   │
│  │  • Séances cette semaine : 3           │   │
│  │  • Volume total : 12,450 kg            │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  📅 Séances récentes                            │
│  ┌─────────────────────────────────────────┐   │
│  │  🏋️ Full Body #1                       │   │
│  │  12 janvier 2025, 10:00                │   │
│  │  ⏱️ 1h 15min  💪 8 exercices            │   │
│  │  💬 2 commentaires                      │   │
│  │  [👁️ Voir] [✏️ Modifier]                │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 3. Vue d'une séance avec commentaires (`/coach/sessions/[id]`)

```
┌─────────────────────────────────────────────────┐
│  🏋️ Full Body #1                               │
│  Par Alexandre Lile                             │
│  12 janvier 2025, 10:00                         │
├─────────────────────────────────────────────────┤
│                                                 │
│  Statistiques                                   │
│  ⏱️ 1h 15min  💪 8 exercices  📊 2,450 kg      │
│                                                 │
│  Exercices réalisés                             │
│  • Squat (80kg × 8 reps × 3 sets)              │
│  • Développé couché (70kg × 10 reps × 3)       │
│  ...                                            │
│                                                 │
│  ───────────────────────────────────────────   │
│                                                 │
│  💬 Commentaires                                │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  👤 Coach Martin                        │   │
│  │  Il y a 2 heures                        │   │
│  │                                         │   │
│  │  Excellent travail ! Continue comme ça. │   │
│  │  Je remarque que tu as augmenté le      │   │
│  │  poids sur le squat. 👏                 │   │
│  │                                         │   │
│  │  [✏️ Modifier] [🗑️ Supprimer]          │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Ajouter un commentaire                 │   │
│  │  [Tapez votre commentaire...]           │   │
│  │  [📤 Envoyer]                            │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  [✏️ Modifier la séance]                       │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 4. Inviter un élève (`/coach/invite`)

```
┌─────────────────────────────────────────────────┐
│  ➕ Inviter un élève                            │
├─────────────────────────────────────────────────┤
│                                                 │
│  Rechercher un utilisateur :                    │
│  ┌─────────────────────────────────────────┐   │
│  │  [Rechercher par email ou username...]  │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  Ou envoyer une invitation par email :         │
│  ┌─────────────────────────────────────────┐   │
│  │  Email : [alexandre@example.com]        │   │
│  │  Message (optionnel) :                  │   │
│  │  [Tapez un message...]                  │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  [📧 Envoyer l'invitation]                      │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 📱 FONCTIONNALITÉS À IMPLÉMENTER

### Phase 1 - Fondations (2-3 semaines)
- [ ] Système de rôles (user_roles)
- [ ] Relations coach-élève (coach_student_relationships)
- [ ] RLS policies pour les coaches
- [ ] Migration des données existantes

### Phase 2 - Interface coach (2-3 semaines)
- [ ] Dashboard coach avec liste des élèves
- [ ] Page de profil d'un élève
- [ ] Vue des séances d'un élève
- [ ] Système d'invitation d'élèves

### Phase 3 - Commentaires et modifications (2 semaines)
- [ ] Système de commentaires
- [ ] Modification des séances par le coach
- [ ] Notifications pour les élèves (nouveau commentaire)
- [ ] Interface élève pour voir les commentaires

### Phase 4 - Fonctionnalités avancées (2-3 semaines)
- [ ] Création de séances par le coach pour l'élève
- [ ] Statistiques comparatives
- [ ] Planification d'entraînements
- [ ] Export de rapports

---

## ⚠️ DÉFIS ET CONSIDÉRATIONS

### 1. Performance
- **Problème :** Les requêtes avec plusieurs JOINs peuvent être lentes
- **Solution :** Index optimisés, cache, pagination

### 2. Notifications
- **Problème :** Comment notifier l'élève d'un nouveau commentaire ?
- **Solution :** Supabase Realtime ou système de notifications push

### 3. Permissions complexes
- **Problème :** Les RLS policies deviennent complexes avec les relations
- **Solution :** Fonctions SQL pour simplifier les checks

### 4. Gestion des conflits
- **Problème :** Coach et élève modifient en même temps
- **Solution :** Versioning ou système de verrouillage

### 5. Vie privée
- **Problème :** Les élèves veulent contrôler ce que le coach voit
- **Solution :** Options de confidentialité granulaires

---

## 💰 COÛT EN TEMPS ESTIMÉ

### Version minimale viable (MVP)
- **Phase 1** : 2-3 semaines
- **Phase 2** : 2-3 semaines
- **Phase 3** : 2 semaines

**Total MVP : 6-8 semaines**

### Version complète
- **Phase 4** : 2-3 semaines supplémentaires

**Total complet : 8-11 semaines**

---

## 🚀 RECOMMANDATION

### Approche progressive :

1. **Commencez par le MVP :**
   - Système de rôles
   - Relations coach-élève
   - Dashboard coach basique
   - Commentaires simples

2. **Testez avec quelques coaches :**
   - Collectez du feedback
   - Identifiez les fonctionnalités les plus demandées

3. **Ajoutez les fonctionnalités avancées :**
   - Modification des séances
   - Création de séances
   - Statistiques avancées

---

## ✅ AVANTAGES

1. **Monétisation** - Les coaches peuvent payer pour accéder
2. **Engagement** - Les élèves sont plus motivés avec un coach
3. **Différenciation** - Fonctionnalité unique sur le marché
4. **Scalable** - Un coach peut gérer plusieurs élèves

---

## 📚 Ressources

- [Supabase RLS avec relations](https://supabase.com/docs/guides/auth/row-level-security#policies-with-joins)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime) - Pour les notifications
- [Role-based access control](https://supabase.com/docs/guides/auth/row-level-security#role-based-access-control)

---

## 🎯 CONCLUSION

**C'est faisable mais c'est un projet significatif.**

- **Complexité technique :** Moyenne à Élevée
- **Temps nécessaire :** 2-3 mois pour une version complète
- **Valeur ajoutée :** Très élevée (monétisation possible)

**Mon conseil :** Commencez par le MVP (rôles + relations + commentaires) et itérez selon le feedback.

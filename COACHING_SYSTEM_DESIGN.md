# 🎨 Design : Système de coaching

## 📱 Exemples visuels de l'interface coach

---

## 1. 🏋️ Dashboard Coach

### Vue d'ensemble avec liste des élèves

```
┌─────────────────────────────────────────────────┐
│  🏋️ Dashboard Coach                            │
│  Bonjour, Coach Martin !                        │
├─────────────────────────────────────────────────┤
│                                                 │
│  📊 Vue d'ensemble                              │
│  ┌─────────────────────────────────────────┐  │
│  │  👥 Élèves actifs : 12                  │  │
│  │  📅 Séances cette semaine : 45          │  │
│  │  💬 Commentaires en attente : 3         │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  👥 Mes élèves                                  │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 Alexandre Lile                      │  │
│  │  📅 Dernière séance : Il y a 2 jours   │  │
│  │  💪 3 séances cette semaine            │  │
│  │  💬 2 nouveaux commentaires            │  │
│  │  [👁️ Voir le profil]                   │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 Sophie Martin                       │  │
│  │  📅 Dernière séance : Aujourd'hui      │  │
│  │  💪 4 séances cette semaine            │  │
│  │  ✅ À jour                             │  │
│  │  [👁️ Voir le profil]                   │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [➕ Inviter un élève]                         │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 2. 👤 Profil d'un élève

### Vue détaillée avec statistiques

```
┌─────────────────────────────────────────────────┐
│  ← Retour au dashboard                         │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 Alexandre Lile                      │  │
│  │  📧 alexandre@example.com               │  │
│  │  📅 Membre depuis : Janvier 2024        │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  📊 Statistiques                                │
│  ┌─────────────────────────────────────────┐  │
│  │  • Séances totales : 45                │  │
│  │  • Séances cette semaine : 3           │  │
│  │  • Volume total : 12,450 kg            │  │
│  │  • Temps total : 67h 30min             │  │
│  │  • Exercices favoris : Squat, Bench    │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  📅 Séances récentes                            │
│  ┌─────────────────────────────────────────┐  │
│  │  🏋️ Full Body #1                       │  │
│  │  12 janvier 2025, 10:00                │  │
│  │  ⏱️ 1h 15min  💪 8 exercices            │  │
│  │  💬 2 commentaires                      │  │
│  │  [👁️ Voir] [✏️ Modifier]                │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  🏋️ Upper Body                         │  │
│  │  10 janvier 2025, 14:00                │  │
│  │  ⏱️ 45min  💪 5 exercices              │  │
│  │  💬 1 commentaire                       │  │
│  │  [👁️ Voir] [✏️ Modifier]                │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [➕ Créer une séance pour cet élève]          │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 3. 💬 Vue d'une séance avec commentaires

### Interface pour voir et commenter

```
┌─────────────────────────────────────────────────┐
│  ← Retour                                       │
│                                                 │
│  🏋️ Full Body #1                               │
│  Par Alexandre Lile                             │
│  12 janvier 2025, 10:00 - 11:15                │
├─────────────────────────────────────────────────┤
│                                                 │
│  📊 Statistiques                                │
│  ┌─────────────────────────────────────────┐  │
│  │  ⏱️  Durée : 1h 15min                   │  │
│  │  💪 Exercices : 8                       │  │
│  │  📊 Volume : 2,450 kg                   │  │
│  │  🔥 Calories : ~450                     │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  💪 Exercices réalisés                         │
│  ┌─────────────────────────────────────────┐  │
│  │  💪 Squat                               │  │
│  │     80kg × 8 reps × 3 sets             │  │
│  │     [✏️ Modifier]                       │  │
│  │                                         │  │
│  │  💪 Développé couché                    │  │
│  │     70kg × 10 reps × 3 sets            │  │
│  │     [✏️ Modifier]                       │  │
│  │                                         │  │
│  │  💪 Soulevé de terre                    │  │
│  │     100kg × 8 reps × 2 sets            │  │
│  │     [✏️ Modifier]                       │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ───────────────────────────────────────────  │
│                                                 │
│  💬 Commentaires (2)                           │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 Coach Martin                        │  │
│  │  Il y a 2 heures                        │  │
│  │                                         │  │
│  │  Excellent travail ! Continue comme ça. │  │
│  │  Je remarque que tu as augmenté le      │  │
│  │  poids sur le squat. 👏                 │  │
│  │                                         │  │
│  │  [✏️ Modifier] [🗑️ Supprimer]          │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 Coach Martin                        │  │
│  │  Il y a 1 jour                          │  │
│  │                                         │  │
│  │  Pour la prochaine séance, essaie      │  │
│  │  d'augmenter le repos entre les séries │  │
│  │  de soulevé de terre à 3 minutes.       │  │
│  │                                         │  │
│  │  [✏️ Modifier] [🗑️ Supprimer]          │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  Ajouter un commentaire                 │  │
│  │  ┌───────────────────────────────────┐ │  │
│  │  │ Tapez votre commentaire...         │ │  │
│  │  │                                    │ │  │
│  │  └───────────────────────────────────┘ │  │
│  │  ☑️ Commentaire privé                  │  │
│  │  [📤 Envoyer]                           │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [✏️ Modifier la séance]                       │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 4. ➕ Inviter un élève

### Interface d'invitation

```
┌─────────────────────────────────────────────────┐
│  ➕ Inviter un élève                            │
├─────────────────────────────────────────────────┤
│                                                 │
│  Option 1 : Rechercher un utilisateur          │
│  ┌─────────────────────────────────────────┐  │
│  │  [Rechercher par email ou username...]   │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Résultats :                                    │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 alexandre@example.com               │  │
│  │  Alexandre Lile                         │  │
│  │  [➕ Inviter]                            │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ───────────────────────────────────────────  │
│                                                 │
│  Option 2 : Envoyer une invitation par email   │
│  ┌─────────────────────────────────────────┐  │
│  │  Email :                                │  │
│  │  [nouvel.eleve@example.com]             │  │
│  │                                         │  │
│  │  Message (optionnel) :                  │  │
│  │  ┌───────────────────────────────────┐ │  │
│  │  │ Bonjour,                          │ │  │
│  │  │                                   │ │  │
│  │  │ Je souhaite devenir votre coach   │ │  │
│  │  │ sur LastRep. Acceptez-vous ?      │ │  │
│  │  │                                   │ │  │
│  │  │ Cordialement,                     │ │  │
│  │  │ Coach Martin                      │ │  │
│  │  └───────────────────────────────────┘ │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [📧 Envoyer l'invitation]                      │
│  [Annuler]                                      │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 5. ✏️ Modifier une séance (Coach)

### Interface d'édition pour le coach

```
┌─────────────────────────────────────────────────┐
│  ✏️ Modifier la séance                          │
│  Full Body #1 - Alexandre Lile                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  📅 Date et heure                               │
│  [12/01/2025] [10:00] → [11:15]                │
│                                                 │
│  💪 Exercices                                   │
│  ┌─────────────────────────────────────────┐  │
│  │  💪 Squat                               │  │
│  │  Poids : [80] kg                        │  │
│  │  Répétitions : [8] reps                 │  │
│  │  Séries : [3]                            │  │
│  │  [✏️ Modifier] [🗑️ Supprimer]           │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [➕ Ajouter un exercice]                       │
│                                                 │
│  📝 Notes                                       │
│  ┌─────────────────────────────────────────┐  │
│  │  [Tapez des notes...]                   │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [💾 Enregistrer] [❌ Annuler]                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 6. 👁️ Vue élève - Voir les commentaires du coach

### Comment l'élève voit les commentaires

```
┌─────────────────────────────────────────────────┐
│  🏋️ Full Body #1                               │
│  12 janvier 2025, 10:00                        │
├─────────────────────────────────────────────────┤
│                                                 │
│  📊 Statistiques                                │
│  ⏱️ 1h 15min  💪 8 exercices  📊 2,450 kg      │
│                                                 │
│  ───────────────────────────────────────────   │
│                                                 │
│  💬 Commentaires de votre coach                 │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 Coach Martin                        │  │
│  │  Il y a 2 heures                        │  │
│  │                                         │  │
│  │  Excellent travail ! Continue comme ça. │  │
│  │  Je remarque que tu as augmenté le      │  │
│  │  poids sur le squat. 👏                 │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 Coach Martin                        │  │
│  │  Il y a 1 jour                          │  │
│  │                                         │  │
│  │  Pour la prochaine séance, essaie      │  │
│  │  d'augmenter le repos entre les séries │  │
│  │  de soulevé de terre à 3 minutes.       │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [✏️ Modifier la séance]                       │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 7. 📊 Statistiques comparatives

### Vue des progrès de l'élève

```
┌─────────────────────────────────────────────────┐
│  📊 Progrès de Alexandre Lile                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  📈 Évolution du volume                         │
│  ┌─────────────────────────────────────────┐  │
│  │  [Graphique linéaire]                    │  │
│  │  Jan  │ Fév  │ Mar  │ Avr               │  │
│  │  2.1k │ 2.3k │ 2.5k │ 2.7k (tonnes)    │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  💪 Exercices les plus pratiqués                │
│  ┌─────────────────────────────────────────┐  │
│  │  1. Squat (45 séances)                  │  │
│  │  2. Développé couché (38 séances)       │  │
│  │  3. Soulevé de terre (32 séances)       │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  📅 Fréquence d'entraînement                   │
│  ┌─────────────────────────────────────────┐  │
│  │  Cette semaine : 3 séances              │  │
│  │  Semaine dernière : 4 séances            │  │
│  │  Objectif : 4 séances/semaine            │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 8. 🔔 Notifications élève

### Quand le coach commente

```
┌─────────────────────────────────────────────────┐
│  🔔 Notifications                               │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 Coach Martin                        │  │
│  │  a commenté votre séance                │  │
│  │  "Full Body #1"                         │  │
│  │  Il y a 5 minutes                       │  │
│  │  [👁️ Voir]                              │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  👤 Coach Martin                        │  │
│  │  a modifié votre séance                 │  │
│  │  "Upper Body"                            │  │
│  │  Il y a 2 heures                        │  │
│  │  [👁️ Voir]                              │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🎨 Design System

### Couleurs
- **Coach** : Badge bleu/violet pour identifier les coaches
- **Élève** : Badge vert pour les élèves
- **Commentaires** : Fond légèrement coloré pour les distinguer
- **Actions coach** : Couleur primaire pour les boutons d'action

### Typographie
- **Titre coach** : Font bold, 24px
- **Nom élève** : Font semibold, 18px
- **Commentaires** : Font regular, 14px
- **Statistiques** : Font semibold, 16px

### Icônes
- 👤 Élève/Coach
- 💬 Commentaires
- ✏️ Modifier
- 📊 Statistiques
- ➕ Ajouter/Inviter
- 🔔 Notifications

---

## 📱 Responsive Design

### Mobile
- Une colonne
- Menu hamburger pour navigation
- Cards empilées verticalement
- Boutons pleine largeur

### Desktop
- Sidebar avec navigation
- Deux colonnes pour les stats
- Modal centrée pour les actions
- Tableau pour la liste des élèves

---

## ✨ Fonctionnalités clés

1. **Gestion des élèves**
   - Liste avec recherche
   - Filtres (actifs, inactifs, en attente)
   - Statistiques rapides

2. **Commentaires**
   - Commentaires privés (coach + élève uniquement)
   - Commentaires publics (optionnel)
   - Édition/suppression
   - Notifications

3. **Modification des séances**
   - Modification complète
   - Historique des modifications (optionnel)
   - Notification à l'élève

4. **Création de séances**
   - Coach peut créer des séances pour l'élève
   - Templates réutilisables
   - Planification

---

Ces designs s'intègrent naturellement avec votre application actuelle et offrent une expérience professionnelle pour les coaches ! 🚀

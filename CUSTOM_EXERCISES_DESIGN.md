# 🎨 Design : Exercices personnalisés avec types de mesure

## 📱 Exemples visuels des différents types

---

## 1. 💪 Type : Poids + Répétitions (Actuel)

### Exemple : Squat

```
┌─────────────────────────────────────────────────┐
│  💪 Squat                                       │
│  Poids + Répétitions                            │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  🏋️  Poids : [80] kg                    │  │
│  │  🔢 Répétitions : [8]                   │  │
│  │  ⏸️  Repos : [120] secondes             │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 80kg × 8 reps (repos 120s)                  │
│  • 80kg × 8 reps (repos 120s)                  │
│  • 80kg × 8 reps                               │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 2. ⏱️ Type : Temps uniquement

### Exemple : Gainage

```
┌─────────────────────────────────────────────────┐
│  ⏱️ Gainage                                     │
│  Temps uniquement                              │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  ⏱️  Durée : [30] secondes              │  │
│  │  ⏸️  Repos : [60] secondes              │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 30 secondes (repos 60s)                       │
│  • 45 secondes (repos 60s)                       │
│  • 60 secondes                                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Affichage :** `30s`, `45s`, `60s` au lieu de `80kg × 8`

---

## 3. 🔢 Type : Répétitions uniquement

### Exemple : Pompes

```
┌─────────────────────────────────────────────────┐
│  🔢 Pompes                                      │
│  Répétitions uniquement                         │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  🔢 Répétitions : [20]                   │  │
│  │  ⏸️  Repos : [60] secondes               │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 20 reps (repos 60s)                          │
│  • 25 reps (repos 60s)                          │
│  • 30 reps                                      │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Affichage :** `20 reps`, `25 reps`, `30 reps` (pas de poids)

---

## 4. 🏃 Type : Temps + Distance

### Exemple : Course à pied

```
┌─────────────────────────────────────────────────┐
│  🏃 Course à pied                               │
│  Temps + Distance                               │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  ⏱️  Durée : [25] minutes                │  │
│  │  📏 Distance : [5] km                   │  │
│  │  ⏸️  Repos : [120] secondes             │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 5km en 25min (repos 2min)                    │
│  • 3km en 15min (repos 2min)                    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Affichage :** `5km en 25min` avec calcul automatique de la vitesse

---

## 5. 🏋️ Type : Poids uniquement

### Exemple : Charge maximale (1RM)

```
┌─────────────────────────────────────────────────┐
│  🏋️ 1RM Squat                                   │
│  Poids uniquement                               │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  🏋️  Poids : [100] kg                   │  │
│  │  ⏸️  Repos : [180] secondes             │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 100kg (repos 3min)                           │
│  • 105kg (repos 3min)                           │
│  • 110kg                                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Affichage :** `100kg`, `105kg`, `110kg` (pas de répétitions)

---

## 6. ⏱️🔢 Type : Temps + Répétitions

### Exemple : Gainage avec séries

```
┌─────────────────────────────────────────────────┐
│  ⏱️ Gainage 3 séries                            │
│  Temps + Répétitions                            │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  ⏱️  Durée : [30] secondes              │  │
│  │  🔢 Répétitions : [3]                   │  │
│  │  ⏸️  Repos : [60] secondes              │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 30s × 3 (repos 60s)                          │
│  • 45s × 3 (repos 60s)                          │
│  • 60s × 3                                      │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Affichage :** `30s × 3` (3 séries de 30 secondes)

---

## 7. 📏 Type : Distance uniquement

### Exemple : Marche

```
┌─────────────────────────────────────────────────┐
│  🚶 Marche                                      │
│  Distance uniquement                            │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  📏 Distance : [5] km                    │  │
│  │  ⏸️  Repos : [0] secondes                │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 5km                                          │
│  • 3km                                          │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🎨 Formulaire de création d'exercice

### Vue complète avec tous les types

```
┌─────────────────────────────────────────────────┐
│  ➕ Créer un exercice personnalisé              │
├─────────────────────────────────────────────────┤
│                                                 │
│  Nom de l'exercice *                            │
│  ┌─────────────────────────────────────────┐  │
│  │  [Gainage]                               │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Muscle principal                                │
│  ┌─────────────────────────────────────────┐  │
│  │  [Abdominaux ▼]                         │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Type de mesure *                               │
│  ┌─────────────────────────────────────────┐  │
│  │  ○ 🏋️  Poids + Répétitions              │  │
│  │     Ex: Squat, Bench Press               │  │
│  │                                          │  │
│  │  ● ⏱️  Temps uniquement                  │  │
│  │     Ex: Gainage, Planche                 │  │
│  │                                          │  │
│  │  ○ 🔢 Répétitions uniquement             │  │
│  │     Ex: Pompes, Tractions                │  │
│  │                                          │  │
│  │  ○ 🏋️  Poids uniquement                 │  │
│  │     Ex: 1RM, Charge max                  │  │
│  │                                          │  │
│  │  ○ ⏱️📏 Temps + Distance                 │  │
│  │     Ex: Course, Vélo                     │  │
│  │                                          │  │
│  │  ○ ⏱️🔢 Temps + Répétitions             │  │
│  │     Ex: Gainage 3x 30s                   │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [💾 Créer] [❌ Annuler]                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 📊 Affichage dans les listes

### Liste des exercices avec badges

```
┌─────────────────────────────────────────────────┐
│  💪 Exercices                                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  📚 Exercices globaux                           │
│  ┌─────────────────────────────────────────┐  │
│  │  💪 Squat                                │  │
│  │  🏋️  Poids + Répétitions                 │  │
│  │  Pectoraux                               │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ⭐ Mes exercices personnalisés                 │
│  ┌─────────────────────────────────────────┐  │
│  │  ⏱️ Gainage                              │  │
│  │  ⏱️ Temps uniquement                    │  │
│  │  Abdominaux                              │  │
│  │  [✏️] [🗑️]                               │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  🏃 Course à pied                       │  │
│  │  ⏱️📏 Temps + Distance                 │  │
│  │  Cardio                                  │  │
│  │  [✏️] [🗑️]                               │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [➕ Créer un exercice]                         │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🎯 Statistiques adaptées

### Selon le type d'exercice

#### Type "Poids + Répétitions"
```
📊 Statistiques
• Volume total : 2,450 kg
• Poids max : 100kg
• Répétitions totales : 24
• Meilleure série : 100kg × 8 reps
```

#### Type "Temps"
```
📊 Statistiques
• Temps total : 2h 15min
• Durée max : 5min
• Séries : 12
• Meilleure série : 5min
```

#### Type "Temps + Distance"
```
📊 Statistiques
• Distance totale : 15km
• Temps total : 1h 20min
• Vitesse moyenne : 11.25 km/h
• Meilleure série : 5km en 25min
```

---

## 💡 Suggestions de types

### Types essentiels (à implémenter en premier)
1. ✅ **Poids + Répétitions** - Déjà fait
2. ✅ **Temps uniquement** - Gainage, planche, course
3. ✅ **Répétitions uniquement** - Pompes, tractions, abdominaux

### Types utiles (à ajouter ensuite)
4. **Temps + Distance** - Course, vélo, natation
5. **Distance uniquement** - Marche, randonnée
6. **Poids uniquement** - 1RM, charge maximale

### Types avancés (optionnel)
7. **Temps + Répétitions** - Gainage 3x 30s
8. **Custom** - Type libre avec unité personnalisée

---

## ✨ Avantages

1. **Flexibilité totale** - Les utilisateurs créent ce dont ils ont besoin
2. **Adapté à tous les sports** - Musculation, cardio, yoga, etc.
3. **Personnalisation** - Chaque utilisateur a ses propres exercices
4. **Évolutif** - Facile d'ajouter de nouveaux types plus tard

---

## 🎨 Design System

### Icônes par type
- 🏋️ Poids + Répétitions
- ⏱️ Temps
- 🔢 Répétitions
- 📏 Distance
- 🏃 Temps + Distance
- ⏱️🔢 Temps + Répétitions

### Couleurs
- **Exercices globaux** : Badge bleu
- **Exercices personnalisés** : Badge violet/rose
- **Type de mesure** : Badge gris clair

---

Cette fonctionnalité rendra votre application beaucoup plus flexible et adaptée à tous les types d'entraînement ! 💪

# 💪 Système flexible : Exercices personnalisés avec lestage

## 🎯 Approche révisée : Flexibilité maximale

**Problème identifié :** Les pompes, tractions, etc. peuvent être :
- ✅ Sans poids (juste répétitions)
- ✅ Avec poids (lestées : gilet lesté, ceinture, etc.)

**Solution :** Système de champs optionnels plutôt que types stricts.

---

## 📊 Types de mesure révisés

### 1. **Poids + Répétitions** (flexible)
- **Exemples :** Squat, Développé couché, Pompes lestées
- **Champs :** `weight_kg` (optionnel) + `reps` (obligatoire)
- **Usage :** Permet squats avec poids ET pompes lestées

### 2. **Répétitions** (poids optionnel)
- **Exemples :** Pompes, Tractions, Abdominaux
- **Champs :** `reps` (obligatoire) + `weight_kg` (optionnel si lesté)
- **Usage :** Pompes normales OU pompes lestées

### 3. **Temps**
- **Exemples :** Gainage, Planche
- **Champs :** `duration_seconds` (obligatoire) + `reps` (optionnel pour séries)
- **Usage :** Gainage 30s OU gainage 3x 30s

### 4. **Temps + Distance**
- **Exemples :** Course, Vélo
- **Champs :** `duration_seconds` + `distance_meters` (les deux obligatoires)

### 5. **Distance uniquement**
- **Exemples :** Marche
- **Champs :** `distance_meters` (obligatoire)

---

## 🎨 Interface adaptative

### Exemple : Pompes (type "reps" avec poids optionnel)

```
┌─────────────────────────────────────────────────┐
│  💪 Pompes                                      │
│  Répétitions (poids optionnel)                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  🔢 Répétitions : [20] *                │  │
│  │  🏋️  Poids (optionnel) : [0] kg        │  │
│  │     💡 Pour pompes lestées              │  │
│  │  ⏸️  Repos : [60] secondes              │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 20 reps                                      │
│  • 20 reps (lesté +10kg)                        │
│  • 25 reps (lesté +15kg)                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Affichage :**
- Sans poids : `20 reps`
- Avec poids : `20 reps (lesté +10kg)`

---

### Exemple : Tractions (même principe)

```
┌─────────────────────────────────────────────────┐
│  💪 Tractions                                   │
│  Répétitions (poids optionnel)                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  🔢 Répétitions : [12] *                │  │
│  │  🏋️  Poids (optionnel) : [0] kg        │  │
│  │     💡 Pour tractions lestées           │  │
│  │  ⏸️  Repos : [90] secondes             │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 12 reps                                      │
│  • 10 reps (lesté +20kg)                        │
│  • 8 reps (lesté +30kg)                         │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

### Exemple : Squat (type "weight_reps" - poids généralement requis)

```
┌─────────────────────────────────────────────────┐
│  💪 Squat                                       │
│  Poids + Répétitions                            │
├─────────────────────────────────────────────────┤
│                                                 │
│  Ajouter une série                              │
│  ┌─────────────────────────────────────────┐  │
│  │  🏋️  Poids : [80] kg *                 │  │
│  │  🔢 Répétitions : [8] *                 │  │
│  │  ⏸️  Repos : [120] secondes             │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Séries effectuées :                            │
│  • 80kg × 8 reps                               │
│  • 85kg × 8 reps                               │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Note :** Pour squat, poids est généralement requis, mais on peut le rendre optionnel pour flexibilité.

---

## 🗄️ Structure de base de données révisée

### Table `exercise`

```sql
ALTER TABLE exercise 
ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
ADD COLUMN measurement_type VARCHAR(20) NOT NULL DEFAULT 'weight_reps' 
  CHECK (measurement_type IN (
    'weight_reps',      -- Poids + Répétitions (poids généralement requis)
    'reps',             -- Répétitions (poids optionnel pour lestage)
    'time',             -- Temps uniquement
    'time_reps',         -- Temps + Répétitions
    'time_distance',     -- Temps + Distance
    'distance',          -- Distance uniquement
    'weight_only'        -- Poids uniquement
  )),
ADD COLUMN is_custom BOOLEAN DEFAULT false;
```

### Table `exerciseset` (déjà flexible)

```sql
-- Les champs sont déjà optionnels, c'est parfait !
-- weight_kg peut être NULL (pour pompes sans lestage)
-- reps peut être NULL (pour exercices en temps uniquement)
-- duration_seconds peut être NULL (pour exercices sans temps)
-- distance_meters peut être NULL (pour exercices sans distance)
```

### Validation flexible

```sql
CREATE OR REPLACE FUNCTION validate_exercise_set()
RETURNS TRIGGER AS $$
DECLARE
  exercise_type VARCHAR(20);
BEGIN
  SELECT measurement_type INTO exercise_type
  FROM exercise
  WHERE id = NEW.exercise_id;

  CASE exercise_type
    WHEN 'weight_reps' THEN
      -- Poids généralement requis, mais peut être optionnel
      IF NEW.reps IS NULL THEN
        RAISE EXCEPTION 'weight_reps requires reps';
      END IF;
      -- weight_kg peut être NULL (rare mais possible)
    
    WHEN 'reps' THEN
      -- Répétitions obligatoires, poids optionnel (pour lestage)
      IF NEW.reps IS NULL THEN
        RAISE EXCEPTION 'reps type requires reps';
      END IF;
      -- weight_kg est optionnel : permet pompes normales ET lestées
    
    WHEN 'time' THEN
      IF NEW.duration_seconds IS NULL THEN
        RAISE EXCEPTION 'time requires duration_seconds';
      END IF;
      -- reps peut être optionnel (pour séries de temps)
    
    WHEN 'time_reps' THEN
      IF NEW.duration_seconds IS NULL OR NEW.reps IS NULL THEN
        RAISE EXCEPTION 'time_reps requires both duration_seconds and reps';
      END IF;
    
    WHEN 'time_distance' THEN
      IF NEW.duration_seconds IS NULL OR NEW.distance_meters IS NULL THEN
        RAISE EXCEPTION 'time_distance requires both duration_seconds and distance_meters';
      END IF;
    
    WHEN 'distance' THEN
      IF NEW.distance_meters IS NULL THEN
        RAISE EXCEPTION 'distance requires distance_meters';
      END IF;
    
    WHEN 'weight_only' THEN
      IF NEW.weight_kg IS NULL THEN
        RAISE EXCEPTION 'weight_only requires weight_kg';
      END IF;
  END CASE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 🎨 Interface utilisateur adaptative

### Formulaire pour type "reps" (pompes, tractions)

```vue
<template>
  <div v-if="exercise.measurement_type === 'reps'">
    <!-- Répétitions (obligatoire) -->
    <div class="space-y-2">
      <Label>Répétitions *</Label>
      <Input 
        v-model="setData.reps" 
        type="number"
        required
      />
    </div>

    <!-- Poids (optionnel - pour lestage) -->
    <div class="space-y-2">
      <Label>
        Poids (optionnel)
        <span class="text-xs text-muted-foreground">
          Pour exercices lestés (gilet, ceinture, etc.)
        </span>
      </Label>
      <Input 
        v-model="setData.weight_kg" 
        type="number"
        step="0.5"
        placeholder="0"
      />
      <p v-if="setData.weight_kg > 0" class="text-xs text-primary">
        💡 Exercice lesté : +{{ setData.weight_kg }}kg
      </p>
    </div>

    <!-- Repos et note -->
    <div class="space-y-2">
      <Label>Repos (secondes)</Label>
      <Input v-model="setData.rest_seconds" type="number" />
    </div>
  </div>
</template>
```

### Affichage des séries

```vue
<template>
  <div v-for="set in sets" :key="set.id">
    <div v-if="exercise.measurement_type === 'reps'">
      <!-- Sans poids -->
      <span v-if="!set.weight_kg || set.weight_kg === 0">
        {{ set.reps }} reps
      </span>
      
      <!-- Avec poids (lesté) -->
      <span v-else>
        {{ set.reps }} reps 
        <span class="text-primary font-semibold">
          (lesté +{{ set.weight_kg }}kg)
        </span>
      </span>
    </div>
  </div>
</template>
```

---

## 📊 Exemples concrets

### Pompes
```
Type : "reps" (poids optionnel)

Série 1 : 20 reps (sans poids)
Série 2 : 20 reps (lesté +10kg) ← Gilet lesté
Série 3 : 18 reps (lesté +15kg) ← Plus lourd
```

### Tractions
```
Type : "reps" (poids optionnel)

Série 1 : 12 reps (sans poids)
Série 2 : 10 reps (lesté +20kg) ← Ceinture lestée
Série 3 : 8 reps (lesté +30kg)
```

### Squat
```
Type : "weight_reps" (poids généralement requis)

Série 1 : 80kg × 8 reps
Série 2 : 85kg × 8 reps
Série 3 : 90kg × 6 reps
```

### Gainage
```
Type : "time" (reps optionnel pour séries)

Série 1 : 30 secondes
Série 2 : 45 secondes
Série 3 : 60 secondes

OU

Série 1 : 30s × 3 (3 séries de 30 secondes)
```

---

## ✅ Avantages de cette approche

1. **Flexibilité maximale** - Un exercice peut être fait avec ou sans poids
2. **Pas de duplication** - Pas besoin de créer "Pompes" et "Pompes lestées" séparément
3. **Évolutif** - Facile d'ajouter d'autres combinaisons
4. **Intuitif** - L'utilisateur comprend qu'il peut ajouter du poids s'il veut

---

## 🎯 Recommandation finale

**Types essentiels à implémenter :**

1. ✅ **`weight_reps`** - Poids + Répétitions (poids généralement requis)
   - Ex: Squat, Bench Press
   - Permet aussi poids optionnel pour flexibilité

2. ✅ **`reps`** - Répétitions (poids optionnel pour lestage)
   - Ex: Pompes, Tractions, Abdominaux
   - Permet pompes normales ET lestées

3. ✅ **`time`** - Temps (reps optionnel pour séries)
   - Ex: Gainage, Planche
   - Permet gainage simple OU gainage 3x 30s

Cette approche couvre tous les cas d'usage ! 💪

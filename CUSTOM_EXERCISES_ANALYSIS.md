# 💪 Analyse : Exercices personnalisés avec types de mesure

## 📊 Complexité globale : **MOYENNE** ⚠️

**Verdict :** C'est faisable ! Nécessite des modifications de la structure de données et de l'interface, mais c'est une fonctionnalité très utile.

**Important :** Toutes les statistiques existantes (record, 1RM, volume, progression, graphiques) doivent être adaptées pour fonctionner avec les différents types de mesure. Voir `CUSTOM_EXERCISES_STATS.md` pour les détails.

---

## 🎯 TYPES DE MESURE À SUPPORTER

### Approche flexible : Champs optionnels selon le contexte

**Important :** Les exercices comme pompes/tractions peuvent être faits :
- Sans poids (juste répétitions)
- Avec poids (lestées : gilet lesté, ceinture, etc.)

Donc on utilise un système de **champs optionnels** plutôt que des types stricts.

### Types principaux (pour l'affichage par défaut)

### 1. **Poids + Répétitions** (actuel)
- Exemples : Squat, Développé couché, Soulevé de terre
- Mesures : `weight_kg` + `reps`
- **Note :** Les deux sont généralement remplis, mais peuvent être optionnels

### 2. **Temps** (à ajouter)
- Exemples : Gainage, Planche
- Mesures : `duration_seconds`
- **Note :** Peut être combiné avec `reps` (ex: 3 séries de 30s)

### 3. **Répétitions** (poids optionnel)
- Exemples : Pompes, Tractions, Abdominaux
- Mesures : `reps` (obligatoire) + `weight_kg` (optionnel si lesté)
- **Note :** Permet pompes normales ET pompes lestées

### 4. **Distance** (optionnel)
- Exemples : Course, Vélo, Natation
- Mesures : `distance_meters` + `duration_seconds` (optionnel)

### 5. **Poids uniquement** (optionnel)
- Exemples : Charge maximale (1RM)
- Mesures : `weight_kg` seulement

---

## 🗄️ MODIFICATIONS DE BASE DE DONNÉES

### 1. Modifier la table `exercise`

```sql
-- Ajouter les colonnes nécessaires
ALTER TABLE exercise 
ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
ADD COLUMN measurement_type VARCHAR(20) NOT NULL DEFAULT 'weight_reps' 
  CHECK (measurement_type IN (
    'weight_reps',      -- Poids + Répétitions (défaut)
    'time',             -- Temps uniquement
    'reps',             -- Répétitions (poids optionnel pour lestage)
    'distance',         -- Distance uniquement
    'weight_only',      -- Poids uniquement
    'time_distance',    -- Temps + Distance
    'time_reps'         -- Temps + Répétitions (ex: gainage 3x 30s)
  )),
ADD COLUMN is_custom BOOLEAN DEFAULT false,
ADD COLUMN unit VARCHAR(20), -- Unité personnalisée (optionnel)
ADD COLUMN created_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();

-- Index
CREATE INDEX idx_exercise_user_id ON exercise(user_id);
CREATE INDEX idx_exercise_measurement_type ON exercise(measurement_type);
CREATE INDEX idx_exercise_is_custom ON exercise(is_custom);

-- Les exercices existants sont globaux (user_id = NULL, is_custom = false)
UPDATE exercise 
SET is_custom = false, 
    user_id = NULL,
    measurement_type = 'weight_reps'
WHERE user_id IS NULL;
```

### 2. Modifier la table `exerciseset`

```sql
-- Ajouter les colonnes pour les nouveaux types de mesure
ALTER TABLE exerciseset
ADD COLUMN duration_seconds INTEGER, -- Pour les exercices en temps
ADD COLUMN distance_meters NUMERIC,  -- Pour les exercices en distance
ADD COLUMN value NUMERIC;             -- Valeur générique pour d'autres types

-- Index
CREATE INDEX idx_exerciseset_duration ON exerciseset(duration_seconds);
CREATE INDEX idx_exerciseset_distance ON exerciseset(distance_meters);
```

### 3. Contraintes de validation

```sql
-- Fonction pour valider que les bonnes colonnes sont remplies selon le type
-- APPROCHE FLEXIBLE : Certains champs sont optionnels pour permettre la flexibilité
CREATE OR REPLACE FUNCTION validate_exercise_set()
RETURNS TRIGGER AS $$
DECLARE
  exercise_type VARCHAR(20);
BEGIN
  -- Récupérer le type de mesure de l'exercice
  SELECT measurement_type INTO exercise_type
  FROM exercise
  WHERE id = NEW.exercise_id;

  -- Valider selon le type (avec flexibilité)
  CASE exercise_type
    WHEN 'weight_reps' THEN
      -- Poids + Répétitions : les deux sont généralement requis
      IF NEW.reps IS NULL THEN
        RAISE EXCEPTION 'weight_reps requires reps';
      END IF;
      -- weight_kg peut être NULL si on fait juste des répétitions (rare mais possible)
    
    WHEN 'time' THEN
      IF NEW.duration_seconds IS NULL THEN
        RAISE EXCEPTION 'time requires duration_seconds';
      END IF;
    
    WHEN 'reps' THEN
      -- Répétitions : reps obligatoire, poids optionnel (pour lestage)
      IF NEW.reps IS NULL THEN
        RAISE EXCEPTION 'reps type requires reps';
      END IF;
      -- weight_kg est optionnel : permet pompes normales ET pompes lestées
    
    WHEN 'distance' THEN
      IF NEW.distance_meters IS NULL THEN
        RAISE EXCEPTION 'distance requires distance_meters';
      END IF;
    
    WHEN 'weight_only' THEN
      IF NEW.weight_kg IS NULL THEN
        RAISE EXCEPTION 'weight_only requires weight_kg';
      END IF;
    
    WHEN 'time_distance' THEN
      IF NEW.duration_seconds IS NULL OR NEW.distance_meters IS NULL THEN
        RAISE EXCEPTION 'time_distance requires both duration_seconds and distance_meters';
      END IF;
    
    WHEN 'time_reps' THEN
      IF NEW.duration_seconds IS NULL OR NEW.reps IS NULL THEN
        RAISE EXCEPTION 'time_reps requires both duration_seconds and reps';
      END IF;
  END CASE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour valider automatiquement
CREATE TRIGGER validate_exercise_set_trigger
  BEFORE INSERT OR UPDATE ON exerciseset
  FOR EACH ROW
  EXECUTE FUNCTION validate_exercise_set();
```

---

## 🔒 SÉCURITÉ (RLS)

### Modifier les policies de `exercise`

```sql
-- Activer RLS sur exercise
ALTER TABLE exercise ENABLE ROW LEVEL SECURITY;

-- Policy : Les utilisateurs peuvent voir les exercices globaux + leurs exercices personnalisés
CREATE POLICY "Users can view global and their own custom exercises"
  ON exercise FOR SELECT
  USING (
    is_custom = false 
    OR (is_custom = true AND user_id = (SELECT auth.uid()))
  );

-- Policy : Les utilisateurs peuvent créer leurs propres exercices
CREATE POLICY "Users can create their own custom exercises"
  ON exercise FOR INSERT
  WITH CHECK (
    is_custom = true 
    AND user_id = (SELECT auth.uid())
  );

-- Policy : Les utilisateurs peuvent modifier leurs propres exercices
CREATE POLICY "Users can update their own custom exercises"
  ON exercise FOR UPDATE
  USING (
    is_custom = true 
    AND user_id = (SELECT auth.uid())
  )
  WITH CHECK (
    is_custom = true 
    AND user_id = (SELECT auth.uid())
  );

-- Policy : Les utilisateurs peuvent supprimer leurs propres exercices
CREATE POLICY "Users can delete their own custom exercises"
  ON exercise FOR DELETE
  USING (
    is_custom = true 
    AND user_id = (SELECT auth.uid())
  );

-- Policy : Personne ne peut modifier les exercices globaux (sauf admin)
-- (Pas de policy UPDATE/DELETE pour is_custom = false)
```

---

## 🎨 INTERFACE UTILISATEUR

### 1. Créer un exercice personnalisé

```
┌─────────────────────────────────────────────────┐
│  ➕ Créer un exercice personnalisé             │
├─────────────────────────────────────────────────┤
│                                                 │
│  Nom de l'exercice *                           │
│  ┌─────────────────────────────────────────┐  │
│  │  [Gainage]                               │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Muscle principal                               │
│  ┌─────────────────────────────────────────┐  │
│  │  [Abdominaux ▼]                         │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  Type de mesure *                               │
│  ┌─────────────────────────────────────────┐  │
│  │  ○ Poids + Répétitions                  │  │
│  │  ● Temps uniquement                     │  │
│  │  ○ Distance uniquement                  │  │
│  │  ○ Répétitions uniquement               │  │
│  │  ○ Poids uniquement                     │  │
│  │  ○ Temps + Distance                     │  │
│  │  ○ Temps + Répétitions                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [💾 Créer] [❌ Annuler]                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 2. Ajouter une série - Type "Temps"

```
┌─────────────────────────────────────────────────┐
│  💪 Gainage                                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  Série 1                                        │
│  ┌─────────────────────────────────────────┐  │
│  │  ⏱️  Durée : [30] secondes              │  │
│  │  ⏸️  Repos : [60] secondes              │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [➕ Ajouter une série]                         │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 3. Ajouter une série - Type "Poids + Répétitions" (actuel)

```
┌─────────────────────────────────────────────────┐
│  💪 Squat                                       │
├─────────────────────────────────────────────────┤
│                                                 │
│  Série 1                                        │
│  ┌─────────────────────────────────────────┐  │
│  │  🏋️  Poids : [80] kg                    │  │
│  │  🔢 Répétitions : [8]                   │  │
│  │  ⏸️  Repos : [120] secondes             │  │
│  │  📝 Note : [Optionnel]                  │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  [➕ Ajouter une série]                         │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 4. Liste des exercices (globaux + personnalisés)

```
┌─────────────────────────────────────────────────┐
│  💪 Exercices                                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  🔍 Rechercher...                               │
│                                                 │
│  📚 Exercices globaux                           │
│  • Squat (Poids + Répétitions)                  │
│  • Développé couché (Poids + Répétitions)       │
│  • Soulevé de terre (Poids + Répétitions)       │
│  ...                                            │
│                                                 │
│  ⭐ Mes exercices personnalisés                 │
│  • Gainage (Temps)                              │
│  • Planche (Temps)                              │
│  • Course (Temps + Distance)                    │
│  ...                                            │
│                                                 │
│  [➕ Créer un exercice]                         │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 💻 CODE EXEMPLE

### Composant pour créer un exercice

```vue
<template>
  <Dialog v-model:open="showDialog">
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Créer un exercice personnalisé</DialogTitle>
      </DialogHeader>

      <div class="space-y-4">
        <!-- Nom -->
        <div>
          <Label>Nom de l'exercice *</Label>
          <Input v-model="form.name" placeholder="Ex: Gainage" />
        </div>

        <!-- Muscle principal -->
        <div>
          <Label>Muscle principal</Label>
          <Select v-model="form.primary_muscle">
            <SelectTrigger>
              <SelectValue placeholder="Sélectionner" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="Abdominaux">Abdominaux</SelectItem>
              <SelectItem value="Pectoraux">Pectoraux</SelectItem>
              <SelectItem value="Dos">Dos</SelectItem>
              <!-- ... -->
            </SelectContent>
          </Select>
        </div>

        <!-- Type de mesure -->
        <div>
          <Label>Type de mesure *</Label>
          <RadioGroup v-model="form.measurement_type">
            <div class="space-y-2">
              <div class="flex items-center space-x-2">
                <RadioGroupItem value="weight_reps" id="weight_reps" />
                <Label for="weight_reps">Poids + Répétitions</Label>
              </div>
              <div class="flex items-center space-x-2">
                <RadioGroupItem value="time" id="time" />
                <Label for="time">Temps uniquement</Label>
              </div>
              <div class="flex items-center space-x-2">
                <RadioGroupItem value="distance" id="distance" />
                <Label for="distance">Distance uniquement</Label>
              </div>
              <div class="flex items-center space-x-2">
                <RadioGroupItem value="reps_only" id="reps_only" />
                <Label for="reps_only">Répétitions uniquement</Label>
              </div>
              <div class="flex items-center space-x-2">
                <RadioGroupItem value="time_distance" id="time_distance" />
                <Label for="time_distance">Temps + Distance</Label>
              </div>
            </div>
          </RadioGroup>
        </div>

        <DialogFooter>
          <Button @click="createExercise">Créer</Button>
          <Button @click="showDialog = false" variant="ghost">Annuler</Button>
        </DialogFooter>
      </div>
    </DialogContent>
  </Dialog>
</template>

<script setup>
const form = ref({
  name: '',
  primary_muscle: '',
  measurement_type: 'weight_reps'
})

const createExercise = async () => {
  const supabase = useSupabaseClient()
  const user = (await supabase.auth.getUser()).data.user

  const { data, error } = await supabase
    .from('exercise')
    .insert({
      name: form.value.name,
      primary_muscle: form.value.primary_muscle,
      measurement_type: form.value.measurement_type,
      user_id: user.id,
      is_custom: true
    })
    .select()
    .single()

  if (error) {
    toast.error('Erreur lors de la création')
    return
  }

  toast.success('Exercice créé !')
  showDialog.value = false
}
</script>
```

### Composant pour ajouter une série (adaptatif)

```vue
<template>
  <div class="space-y-4">
    <!-- Selon le type de mesure -->
    <div v-if="exercise.measurement_type === 'weight_reps'">
      <Label>Poids (kg)</Label>
      <Input v-model="setData.weight_kg" type="number" />
      
      <Label>Répétitions</Label>
      <Input v-model="setData.reps" type="number" />
    </div>

    <div v-else-if="exercise.measurement_type === 'time'">
      <Label>Durée (secondes)</Label>
      <Input v-model="setData.duration_seconds" type="number" />
    </div>

    <div v-else-if="exercise.measurement_type === 'time_distance'">
      <Label>Durée (secondes)</Label>
      <Input v-model="setData.duration_seconds" type="number" />
      
      <Label>Distance (mètres)</Label>
      <Input v-model="setData.distance_meters" type="number" />
    </div>

    <div v-else-if="exercise.measurement_type === 'reps_only'">
      <Label>Répétitions</Label>
      <Input v-model="setData.reps" type="number" />
    </div>

    <!-- Repos et note (commun à tous) -->
    <Label>Repos (secondes)</Label>
    <Input v-model="setData.rest_seconds" type="number" />
    
    <Label>Note (optionnel)</Label>
    <Textarea v-model="setData.note" />
  </div>
</template>
```

---

## 📊 EXEMPLES D'UTILISATION

### Exemple 1 : Gainage (Temps)
```
Exercice : Gainage
Type : Temps uniquement

Série 1 : 30 secondes, repos 60s
Série 2 : 45 secondes, repos 60s
Série 3 : 60 secondes
```

### Exemple 2 : Course (Temps + Distance)
```
Exercice : Course à pied
Type : Temps + Distance

Série 1 : 5km en 25 minutes
Série 2 : 3km en 15 minutes
```

### Exemple 3 : Pompes (Répétitions uniquement)
```
Exercice : Pompes
Type : Répétitions uniquement

Série 1 : 20 reps, repos 60s
Série 2 : 25 reps, repos 60s
Série 3 : 30 reps
```

---

## 📊 STATISTIQUES ADAPTATIVES

**⚠️ IMPORTANT :** Tous les exercices personnalisés doivent avoir les mêmes statistiques que les exercices globaux, mais adaptées selon le type de mesure.

### Statistiques à adapter

1. **Record personnel (Best Set)**
   - `weight_reps` : Poids × Reps max
   - `reps` : Reps max (avec bonus si lesté)
   - `time` : Durée max
   - `time_distance` : Vitesse max

2. **1RM estimé**
   - `weight_reps` : Calculé avec formule Epley/Brzycki
   - `reps` : Afficher "Répétitions max" au lieu de 1RM
   - `time` : Afficher "Durée max" au lieu de 1RM
   - `time_distance` : Afficher "Vitesse max" au lieu de 1RM

3. **Volume total**
   - `weight_reps` : Somme poids × reps
   - `reps` : Total répétitions
   - `time` : Temps total
   - `time_distance` : Distance totale

4. **Progression**
   - `weight_reps` : Graphique poids max par jour
   - `reps` : Graphique reps max par jour
   - `time` : Graphique durée max par jour
   - `time_distance` : Graphique vitesse/distance par jour

5. **Graphiques**
   - `weight_reps` : Poids vs Répétitions
   - `reps` : Poids de lestage vs Répétitions (si lesté)
   - `time` : Durée vs Séries
   - `time_distance` : Vitesse par jour

**Voir `CUSTOM_EXERCISES_STATS.md` pour les détails complets et les fonctions SQL.**

---

## ⏱️ ESTIMATION DE TEMPS

### Phase 1 - Base de données (3-5 jours)
- [ ] Modifier la table `exercise`
- [ ] Modifier la table `exerciseset`
- [ ] Créer les triggers de validation
- [ ] RLS policies

### Phase 2 - Interface création (2-3 jours)
- [ ] Formulaire de création d'exercice
- [ ] Sélection du type de mesure
- [ ] Validation côté client

### Phase 3 - Interface séries (3-5 jours)
- [ ] Composant adaptatif selon le type
- [ ] Affichage conditionnel des champs
- [ ] Validation des données

### Phase 4 - Liste et recherche (2-3 jours)
- [ ] Afficher exercices globaux + personnalisés
- [ ] Filtres par type
- [ ] Recherche

### Phase 5 - Statistiques adaptatives (5-7 jours) ⚠️
- [ ] Fonctions SQL pour stats selon type
- [ ] Composants de stats adaptatifs
- [ ] Graphiques adaptatifs
- [ ] Affichage conditionnel selon type

**Total : ~3 semaines** 🚀

---

## ✅ AVANTAGES

1. **Flexibilité** - Les utilisateurs peuvent créer n'importe quel exercice
2. **Personnalisation** - Adapté à tous les types d'entraînement
3. **Scalable** - Facile d'ajouter de nouveaux types de mesure
4. **Valeur ajoutée** - Différenciation sur le marché

---

## 🎯 RECOMMANDATION

**Commencez par les types essentiels :**
1. ✅ Poids + Répétitions (déjà fait)
2. ✅ Temps uniquement (gainage, planche)
3. ✅ Répétitions uniquement (pompes, tractions)

**Ajoutez les autres types plus tard selon les besoins.**

---

## 📚 Types de mesure suggérés

### Essentiels
- `weight_reps` - Poids + Répétitions ✅ (déjà fait)
- `time` - Temps uniquement (gainage, planche)
- `reps_only` - Répétitions uniquement (pompes, tractions)

### Utiles
- `time_distance` - Temps + Distance (course, vélo)
- `distance` - Distance uniquement (marche)
- `weight_only` - Poids uniquement (1RM)

### Avancés (plus tard)
- `time_reps` - Temps + Répétitions (gainage 3x 30s)
- `custom` - Type personnalisé avec unité libre

---

Cette fonctionnalité rendra votre application beaucoup plus flexible et adaptée à tous les types d'entraînement ! 💪

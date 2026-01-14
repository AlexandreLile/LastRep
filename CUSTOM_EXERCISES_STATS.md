# 📊 Statistiques pour exercices personnalisés

## 🎯 Objectif

Adapter toutes les statistiques existantes pour qu'elles fonctionnent avec les différents types de mesure (poids, temps, distance, etc.).

---

## 📈 STATISTIQUES ACTUELLES

### 1. **Record personnel (Best Set)**
- **Actuel :** Meilleur set basé sur `weight_kg × reps`
- **Calcul :** `weight_kg × reps` le plus élevé
- **Affichage :** `100kg × 8 reps`

### 2. **1RM estimé**
- **Actuel :** Calculé avec formule Brzycki/Epley basée sur poids + reps
- **Formule :** `weight × (1 + reps / 30)` ou similaire

### 3. **Volume total**
- **Actuel :** Somme de `weight_kg × reps` pour toutes les séries
- **Affichage :** `2,450 kg`

### 4. **Progression du poids**
- **Actuel :** Graphique du poids maximum par jour
- **Données :** `MAX(weight_kg)` groupé par date

### 5. **Poids vs Répétitions**
- **Actuel :** Graphique montrant max reps pour chaque poids
- **Données :** `MAX(reps)` groupé par `weight_kg`

### 6. **Dernière séance**
- **Actuel :** Affiche poids et reps de la dernière séance
- **Données :** Dernier `exerciseset` pour cet exercice

---

## 🔄 ADAPTATION PAR TYPE DE MESURE

### Type 1 : `weight_reps` (Poids + Répétitions)

**✅ Fonctionne déjà !** Toutes les stats actuelles fonctionnent.

- Record : `weight_kg × reps` max
- 1RM : Calculé avec formule
- Volume : `SUM(weight_kg × reps)`
- Progression : Poids max par jour
- Graphique : Poids vs Répétitions

---

### Type 2 : `reps` (Répétitions, poids optionnel)

#### Record personnel
```sql
-- Meilleur set : max reps (ou max reps avec poids si lesté)
SELECT 
  id,
  reps,
  weight_kg,
  created_at
FROM exerciseset
WHERE exercise_id = ? 
  AND user_id = ?
ORDER BY 
  CASE 
    WHEN weight_kg > 0 THEN reps * (1 + weight_kg / 100) -- Bonus pour lestage
    ELSE reps
  END DESC,
  reps DESC
LIMIT 1;
```

**Affichage :**
- Sans poids : `25 reps` (record)
- Avec poids : `20 reps (lesté +15kg)` (record)

#### 1RM estimé
**❌ Pas applicable** - Les répétitions seules n'ont pas de 1RM
**Alternative :** Afficher "Répétitions max" au lieu de 1RM

#### Volume total
```sql
-- Volume = total reps (ou reps × poids si lesté)
SELECT 
  SUM(
    CASE 
      WHEN weight_kg > 0 THEN reps * (1 + weight_kg / 100)
      ELSE reps
    END
  ) as total_volume
FROM exerciseset
WHERE exercise_id = ? AND user_id = ?;
```

**Affichage :** `125 reps` ou `145 reps équivalents` (si lesté)

#### Progression
**Graphique :** Répétitions max par jour
```sql
SELECT 
  DATE(created_at) as date,
  MAX(reps) as max_reps,
  MAX(weight_kg) as max_weight
FROM exerciseset
WHERE exercise_id = ? AND user_id = ?
GROUP BY DATE(created_at)
ORDER BY date;
```

**Affichage :** Graphique "Répétitions max" au lieu de "Poids max"

#### Poids vs Répétitions
**Adaptation :** Répétitions max par poids (si lesté)
- Si pas de poids : Afficher juste "Répétitions totales"
- Si avec poids : Graphique "Poids de lestage vs Répétitions"

---

### Type 3 : `time` (Temps)

#### Record personnel
```sql
-- Meilleur set : durée max
SELECT 
  id,
  duration_seconds,
  reps, -- Optionnel pour séries
  created_at
FROM exerciseset
WHERE exercise_id = ? 
  AND user_id = ?
ORDER BY duration_seconds DESC
LIMIT 1;
```

**Affichage :** `5min 30s` (record)

#### 1RM estimé
**❌ Pas applicable** - Pas de 1RM pour le temps
**Alternative :** Afficher "Durée max" ou "Temps record"

#### Volume total
```sql
-- Volume = temps total
SELECT 
  SUM(duration_seconds) as total_seconds,
  COUNT(*) as total_sets
FROM exerciseset
WHERE exercise_id = ? AND user_id = ?;
```

**Affichage :** `2h 15min` (temps total)

#### Progression
**Graphique :** Durée max par jour
```sql
SELECT 
  DATE(created_at) as date,
  MAX(duration_seconds) as max_duration
FROM exerciseset
WHERE exercise_id = ? AND user_id = ?
GROUP BY DATE(created_at)
ORDER BY date;
```

**Affichage :** Graphique "Durée max" (en secondes/minutes)

#### Poids vs Répétitions
**Adaptation :** 
- Si `reps` utilisé : Graphique "Durée vs Séries" (ex: 3 séries de 30s)
- Sinon : Afficher "Temps total par séance"

---

### Type 4 : `time_distance` (Temps + Distance)

#### Record personnel
```sql
-- Meilleur set : vitesse max (distance / temps)
SELECT 
  id,
  duration_seconds,
  distance_meters,
  (distance_meters / NULLIF(duration_seconds, 0) * 3.6) as speed_kmh,
  created_at
FROM exerciseset
WHERE exercise_id = ? 
  AND user_id = ?
ORDER BY speed_kmh DESC
LIMIT 1;
```

**Affichage :** `5km en 25min` (12 km/h)

#### 1RM estimé
**❌ Pas applicable**
**Alternative :** Afficher "Vitesse max" ou "Meilleure performance"

#### Volume total
```sql
-- Volume = distance totale + temps total
SELECT 
  SUM(distance_meters) as total_distance,
  SUM(duration_seconds) as total_time
FROM exerciseset
WHERE exercise_id = ? AND user_id = ?;
```

**Affichage :** `15km en 1h 20min`

#### Progression
**Graphique :** Vitesse moyenne par jour
```sql
SELECT 
  DATE(created_at) as date,
  AVG(distance_meters / NULLIF(duration_seconds, 0) * 3.6) as avg_speed_kmh,
  SUM(distance_meters) as total_distance
FROM exerciseset
WHERE exercise_id = ? AND user_id = ?
GROUP BY DATE(created_at)
ORDER BY date;
```

**Affichage :** Graphique "Vitesse moyenne" ou "Distance par jour"

---

## 🎨 COMPOSANTS ADAPTATIFS

### Composant de stats adaptatif

```vue
<template>
  <div>
    <!-- Selon le type d'exercice -->
    <div v-if="exercise.measurement_type === 'weight_reps'">
      <LastSetRMStats :exercise-id="exercise.id" />
      <TotalVolumeStats :exercise-id="exercise.id" />
      <WeightProgressionChart :exercise-id="exercise.id" />
    </div>

    <div v-else-if="exercise.measurement_type === 'reps'">
      <LastSetRepsStats :exercise-id="exercise.id" />
      <TotalRepsStats :exercise-id="exercise.id" />
      <RepsProgressionChart :exercise-id="exercise.id" />
    </div>

    <div v-else-if="exercise.measurement_type === 'time'">
      <LastSetTimeStats :exercise-id="exercise.id" />
      <TotalTimeStats :exercise-id="exercise.id" />
      <TimeProgressionChart :exercise-id="exercise.id" />
    </div>

    <div v-else-if="exercise.measurement_type === 'time_distance'">
      <LastSetSpeedStats :exercise-id="exercise.id" />
      <TotalDistanceStats :exercise-id="exercise.id" />
      <SpeedProgressionChart :exercise-id="exercise.id" />
    </div>
  </div>
</template>
```

---

## 📊 FONCTIONS SQL ADAPTATIVES

### Fonction pour calculer le "meilleur set" selon le type

```sql
CREATE OR REPLACE FUNCTION get_best_set(exercise_uuid uuid, user_uuid uuid)
RETURNS TABLE (
  id uuid,
  weight_kg numeric,
  reps integer,
  duration_seconds integer,
  distance_meters numeric,
  value numeric,
  created_at timestamp
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  exercise_type VARCHAR(20);
BEGIN
  -- Récupérer le type de l'exercice
  SELECT measurement_type INTO exercise_type
  FROM exercise
  WHERE id = exercise_uuid;

  CASE exercise_type
    WHEN 'weight_reps' THEN
      RETURN QUERY
      SELECT 
        es.id,
        es.weight_kg,
        es.reps,
        NULL::integer,
        NULL::numeric,
        (es.weight_kg * es.reps)::numeric as value,
        es.created_at
      FROM exerciseset es
      WHERE es.exercise_id = exercise_uuid
        AND es.user_id = user_uuid
        AND es.weight_kg IS NOT NULL
        AND es.reps IS NOT NULL
      ORDER BY (es.weight_kg * es.reps) DESC
      LIMIT 1;

    WHEN 'reps' THEN
      RETURN QUERY
      SELECT 
        es.id,
        es.weight_kg,
        es.reps,
        NULL::integer,
        NULL::numeric,
        CASE 
          WHEN es.weight_kg > 0 THEN es.reps * (1 + es.weight_kg / 100)
          ELSE es.reps
        END::numeric as value,
        es.created_at
      FROM exerciseset es
      WHERE es.exercise_id = exercise_uuid
        AND es.user_id = user_uuid
        AND es.reps IS NOT NULL
      ORDER BY value DESC, es.reps DESC
      LIMIT 1;

    WHEN 'time' THEN
      RETURN QUERY
      SELECT 
        es.id,
        NULL::numeric,
        es.reps,
        es.duration_seconds,
        NULL::numeric,
        es.duration_seconds::numeric as value,
        es.created_at
      FROM exerciseset es
      WHERE es.exercise_id = exercise_uuid
        AND es.user_id = user_uuid
        AND es.duration_seconds IS NOT NULL
      ORDER BY es.duration_seconds DESC
      LIMIT 1;

    WHEN 'time_distance' THEN
      RETURN QUERY
      SELECT 
        es.id,
        NULL::numeric,
        NULL::integer,
        es.duration_seconds,
        es.distance_meters,
        (es.distance_meters / NULLIF(es.duration_seconds, 0) * 3.6)::numeric as value,
        es.created_at
      FROM exerciseset es
      WHERE es.exercise_id = exercise_uuid
        AND es.user_id = user_uuid
        AND es.duration_seconds IS NOT NULL
        AND es.distance_meters IS NOT NULL
      ORDER BY value DESC
      LIMIT 1;

    ELSE
      -- Par défaut, retourner le premier set
      RETURN QUERY
      SELECT 
        es.id,
        es.weight_kg,
        es.reps,
        es.duration_seconds,
        es.distance_meters,
        NULL::numeric,
        es.created_at
      FROM exerciseset es
      WHERE es.exercise_id = exercise_uuid
        AND es.user_id = user_uuid
      ORDER BY es.created_at DESC
      LIMIT 1;
  END CASE;
END;
$$;
```

### Fonction pour calculer le volume total selon le type

```sql
CREATE OR REPLACE FUNCTION get_total_volume(exercise_uuid uuid, user_uuid uuid)
RETURNS TABLE (
  total_volume numeric,
  unit varchar
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  exercise_type VARCHAR(20);
BEGIN
  SELECT measurement_type INTO exercise_type
  FROM exercise
  WHERE id = exercise_uuid;

  CASE exercise_type
    WHEN 'weight_reps' THEN
      RETURN QUERY
      SELECT 
        COALESCE(SUM(es.weight_kg * es.reps), 0)::numeric as total_volume,
        'kg'::varchar as unit
      FROM exerciseset es
      WHERE es.exercise_id = exercise_uuid
        AND es.user_id = user_uuid;

    WHEN 'reps' THEN
      RETURN QUERY
      SELECT 
        COALESCE(SUM(
          CASE 
            WHEN es.weight_kg > 0 THEN es.reps * (1 + es.weight_kg / 100)
            ELSE es.reps
          END
        ), 0)::numeric as total_volume,
        'reps'::varchar as unit
      FROM exerciseset es
      WHERE es.exercise_id = exercise_uuid
        AND es.user_id = user_uuid
        AND es.reps IS NOT NULL;

    WHEN 'time' THEN
      RETURN QUERY
      SELECT 
        COALESCE(SUM(es.duration_seconds), 0)::numeric as total_volume,
        'seconds'::varchar as unit
      FROM exerciseset es
      WHERE es.exercise_id = exercise_uuid
        AND es.user_id = user_uuid
        AND es.duration_seconds IS NOT NULL;

    WHEN 'time_distance' THEN
      RETURN QUERY
      SELECT 
        COALESCE(SUM(es.distance_meters), 0)::numeric as total_volume,
        'meters'::varchar as unit
      FROM exerciseset es
      WHERE es.exercise_id = exercise_uuid
        AND es.user_id = user_uuid
        AND es.distance_meters IS NOT NULL;

    ELSE
      RETURN QUERY
      SELECT 0::numeric as total_volume, 'unknown'::varchar as unit;
  END CASE;
END;
$$;
```

---

## 🎨 AFFICHAGE ADAPTATIF

### Exemple : Page d'exercice adaptative

```vue
<template>
  <div>
    <!-- Stats selon le type -->
    <div v-if="exercise.measurement_type === 'weight_reps'">
      <div class="stat-card">
        <h3>1RM estimé</h3>
        <p>{{ estimated1RM }} kg</p>
      </div>
      <div class="stat-card">
        <h3>Volume total</h3>
        <p>{{ totalVolume }} kg</p>
      </div>
    </div>

    <div v-else-if="exercise.measurement_type === 'reps'">
      <div class="stat-card">
        <h3>Répétitions max</h3>
        <p>{{ maxReps }} reps</p>
        <p v-if="bestSet?.weight_kg" class="text-sm text-primary">
          (lesté +{{ bestSet.weight_kg }}kg)
        </p>
      </div>
      <div class="stat-card">
        <h3>Total répétitions</h3>
        <p>{{ totalReps }} reps</p>
      </div>
    </div>

    <div v-else-if="exercise.measurement_type === 'time'">
      <div class="stat-card">
        <h3>Durée max</h3>
        <p>{{ formatDuration(maxDuration) }}</p>
      </div>
      <div class="stat-card">
        <h3>Temps total</h3>
        <p>{{ formatDuration(totalTime) }}</p>
      </div>
    </div>

    <div v-else-if="exercise.measurement_type === 'time_distance'">
      <div class="stat-card">
        <h3>Vitesse max</h3>
        <p>{{ maxSpeed }} km/h</p>
      </div>
      <div class="stat-card">
        <h3>Distance totale</h3>
        <p>{{ totalDistance }} km</p>
      </div>
    </div>
  </div>
</template>
```

---

## 📊 TABLEAU RÉCAPITULATIF

| Type | Record | Volume | Progression | 1RM |
|------|--------|--------|------------|-----|
| `weight_reps` | Poids × Reps max | Somme poids × reps | Poids max/jour | ✅ Oui |
| `reps` | Reps max (avec bonus lestage) | Total reps | Reps max/jour | ❌ Non → Reps max |
| `time` | Durée max | Temps total | Durée max/jour | ❌ Non → Durée max |
| `time_distance` | Vitesse max | Distance totale | Vitesse/jour | ❌ Non → Vitesse max |

---

## ✅ RECOMMANDATION

**Créer des composants de stats adaptatifs :**

1. **Composant générique** qui détecte le type d'exercice
2. **Affiche les stats appropriées** selon le type
3. **Fonctions SQL** pour calculer les stats selon le type
4. **Graphiques adaptatifs** selon le type

**Avantage :** Les exercices personnalisés auront exactement les mêmes fonctionnalités de stats que les exercices globaux ! 📊

---

Cette approche garantit que tous les exercices (globaux et personnalisés) ont des statistiques cohérentes et adaptées à leur type de mesure ! 💪

-- ============================================
-- PERMETTRE NULL OU VALEUR PAR DÉFAUT POUR weight_kg
-- ============================================
-- Cette migration permet que weight_kg soit NULL ou ait une valeur par défaut de 0
-- pour permettre aux utilisateurs de ne pas spécifier de poids pour certains exercices
-- (ex: pompes sans lestage pour les exercices de type 'reps')

-- Modifier la colonne weight_kg pour permettre NULL et mettre une valeur par défaut de 0
ALTER TABLE exerciseset
  ALTER COLUMN weight_kg DROP NOT NULL,
  ALTER COLUMN weight_kg SET DEFAULT 0;

-- Mettre à jour les valeurs NULL existantes à 0 (si nécessaire)
UPDATE exerciseset
SET weight_kg = 0
WHERE weight_kg IS NULL;

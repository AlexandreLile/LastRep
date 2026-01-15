-- ============================================
-- PERMETTRE NULL OU VALEUR PAR DÉFAUT POUR rest_seconds
-- ============================================
-- Cette migration permet que rest_seconds soit NULL ou ait une valeur par défaut de 0
-- pour permettre aux utilisateurs de ne pas spécifier de temps de repos

-- Modifier la colonne rest_seconds pour permettre NULL et mettre une valeur par défaut de 0
ALTER TABLE exerciseset
  ALTER COLUMN rest_seconds DROP NOT NULL,
  ALTER COLUMN rest_seconds SET DEFAULT 0;

-- Mettre à jour les valeurs NULL existantes à 0 (si nécessaire)
UPDATE exerciseset
SET rest_seconds = 0
WHERE rest_seconds IS NULL;

// Importe le catalogue complet WorkoutX (workoutxapp.com) comme nouveaux
// exercices globaux, avec leurs GIFs de démonstration.
//
// Les exercices existants ne sont JAMAIS touchés : ce script ne fait que des
// INSERT. La visibilité "nouveaux vs anciens" exercices est gérée par la
// colonne is_legacy et la fonction get_visible_exercises() (cf. migration
// add_exercise_legacy_visibility).
//
// Les GIFs nécessitent la clé API WorkoutX pour être récupérés : on les
// télécharge une fois puis on les réhéberge sur notre bucket Supabase, pour
// ne jamais exposer la clé côté client et ne plus dépendre de WorkoutX ensuite.
//
// Usage :
//   SUPABASE_URL=... SUPABASE_SERVICE_KEY=... WORKOUTX_API_KEY=... node scripts/import-workoutx-catalog.js [--dry-run] [--limit=N] [--force]

import { createClient } from '@supabase/supabase-js'
import { readFile, writeFile, mkdir } from 'node:fs/promises'
import { randomUUID } from 'node:crypto'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const WORKOUTX_BASE = 'https://api.workoutxapp.com/v1'
const CACHE_PATH = path.join(__dirname, 'data', 'workoutx-catalog-cache.json')
const TRANSLATIONS_PATH = path.join(__dirname, 'data', 'workoutx-translations-fr.json')
const BUCKET = 'exercise-images'
// Plan Pro : 300 req/min. Avec CONCURRENCY workers, chacun espacé de
// PACE_MS, le débit total reste sous la limite (300 req/min ≈ 1 req/200ms).
const CONCURRENCY = 4
const PACE_MS = 900

const args = process.argv.slice(2)
const dryRun = args.includes('--dry-run')
const force = args.includes('--force')
const limitArg = args.find((a) => a.startsWith('--limit='))
const limit = limitArg ? parseInt(limitArg.split('=')[1], 10) : Infinity

const SUPABASE_URL = process.env.SUPABASE_URL
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY
const WORKOUTX_API_KEY = process.env.WORKOUTX_API_KEY

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY || !WORKOUTX_API_KEY) {
  console.error('SUPABASE_URL, SUPABASE_SERVICE_KEY et WORKOUTX_API_KEY sont requis dans l\'environnement.')
  process.exit(1)
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

// target / secondaryMuscles WorkoutX (récupérés en français via ?lang=fr)
// -> nom exact dans la table `muscle`. Utiliser le vocabulaire officiel
// WorkoutX-FR est plus fiable qu'une traduction maison.
const MUSCLE_MAP = {
  // target (muscle principal)
  Abdominaux: 'Abdominaux',
  Abducteurs: 'Abducteurs',
  Adducteurs: 'Adducteurs',
  'Avant-bras': 'Avant-bras',
  Biceps: 'Biceps',
  'Colonne vertébrale': 'Érecteurs du rachis',
  Deltoïdes: 'Épaules',
  'Dentelé antérieur': 'Dentelé antérieur',
  Fessiers: 'Fessiers',
  'Grand dorsal': 'Grand dorsal',
  'Haut du dos': 'Dorsaux',
  'Ischio-jambiers': 'Ischio-jambiers',
  Mollets: 'Mollets',
  Pectoraux: 'Pectoraux',
  Quadriceps: 'Quadriceps',
  'Système cardiovasculaire': 'Cardio',
  Trapèzes: 'Trapèzes',
  Triceps: 'Triceps',
  'Élévateur de la scapula': 'Élévateur de la scapula',
  // secondaryMuscles (vocabulaire plus large, en partie recoupant target)
  'Abdominaux inférieurs': 'Abdominaux',
  Aine: 'Adducteurs',
  'Bas du dos': 'Lombaires',
  Brachial: 'Brachial antérieur',
  Chevilles: null,
  'Coiffe des rotateurs': 'Épaules',
  'Deltoïdes postérieurs': 'Deltoïdes postérieurs',
  Dos: 'Dorsaux',
  'Extenseurs du poignet': null,
  'Fléchisseurs de la hanche': 'Fléchisseurs de hanche',
  'Fléchisseurs du poignet': null,
  'Haut de la poitrine': 'Pectoraux supérieurs',
  'Intérieur des cuisses': 'Adducteurs',
  Mains: null,
  'Muscles de la préhension': 'Avant-bras',
  Obliques: 'Obliques',
  Pieds: null,
  Poignets: null,
  Poitrine: 'Pectoraux',
  Rhomboïdes: 'Rhomboïdes',
  'Sangle abdominale': 'Abdominaux',
  Soléaire: 'Soléaire',
  'Stabilisateurs de la cheville': null,
  'Sterno-cléido-mastoïdien': 'Cou',
  Tibias: 'Tibial antérieur',
  Trapèze: 'Trapèzes',
  Épaules: 'Épaules',
}

// equipment WorkoutX (français) -> nom de catégorie dans `exercise_category`
const EQUIPMENT_TO_CATEGORY = {
  Assisté: 'Autre',
  'Assisté (serviette)': 'Autre',
  'Avec poids additionnel': 'Poids libre',
  'Ballon Bosu': 'Autre',
  'Ballon de stabilité': 'Autre',
  'Bande de résistance': 'Élastique',
  'Bande élastique': 'Élastique',
  Barre: 'Poids libre',
  'Barre EZ': 'Poids libre',
  'Barre EZ, ballon d’exercice': 'Poids libre',
  'Barre olympique': 'Poids libre',
  'Barre trap': 'Poids libre',
  Corde: 'Autre',
  Câble: 'Machine',
  'Ergomètre pour le haut du corps': 'Cardio',
  Haltère: 'Poids libre',
  'Haltère (utilisé comme poignée pour une amplitude plus large)': 'Poids libre',
  'Haltère, ballon d’exercice': 'Poids libre',
  'Haltère, ballon d’exercice, balle de tennis': 'Poids libre',
  Kettlebell: 'Poids libre',
  'Machine Hammer': 'Machine',
  'Machine SkiErg': 'Cardio',
  'Machine Smith': 'Machine',
  'Machine Stepmill': 'Cardio',
  'Machine à levier': 'Machine',
  'Médecine-ball': 'Poids libre',
  Pneu: 'Autre',
  'Poids du corps': 'Poids du corps',
  'Poids du corps (avec bande de résistance)': 'Poids du corps',
  'Roue abdominale': 'Autre',
  Rouleau: 'Autre',
  Traîneau: 'Cardio',
  'Vélo d’appartement': 'Cardio',
  'Vélo elliptique': 'Cardio',
}

// category WorkoutX (français, type de mouvement) -> measurement_type de l'app
const CATEGORY_TO_MEASUREMENT = {
  flexibilité: 'time',
  cardio: 'time',
  équilibre: 'time',
  pliométrique: 'reps',
  force: 'weight_reps',
}

async function fetchAllWorkoutxExercises() {
  const res = await fetch(`${WORKOUTX_BASE}/exercises?limit=2000&offset=0`, {
    headers: { 'X-WorkoutX-Key': WORKOUTX_API_KEY },
  })
  if (!res.ok) throw new Error(`Échec récupération liste WorkoutX: HTTP ${res.status}`)
  const json = await res.json()
  return json.data
}

async function loadWorkoutxExercises() {
  try {
    const raw = await readFile(CACHE_PATH, 'utf-8')
    const list = JSON.parse(raw)
    console.log(`  ${list.length} exercices WorkoutX chargés depuis le cache local`)
    return list
  } catch {
    console.log('  pas de cache local, récupération depuis l\'API WorkoutX...')
    const list = await fetchAllWorkoutxExercises()
    await mkdir(path.dirname(CACHE_PATH), { recursive: true })
    await writeFile(CACHE_PATH, JSON.stringify(list))
    console.log(`  ${list.length} exercices récupérés et mis en cache`)
    return list
  }
}

async function loadTranslations() {
  try {
    const raw = await readFile(TRANSLATIONS_PATH, 'utf-8')
    const list = JSON.parse(raw)
    const map = new Map(list.map((t) => [t.id, t.fr]))
    console.log(`Traductions chargées : ${map.size} entrées`)
    return map
  } catch {
    console.warn(`Pas de fichier de traductions trouvé (${TRANSLATIONS_PATH}), noms anglais utilisés tels quels.`)
    return new Map()
  }
}

async function mapConcurrent(items, limitConcurrency, fn) {
  const results = new Array(items.length)
  let index = 0
  async function worker() {
    while (index < items.length) {
      const i = index++
      results[i] = await fn(items[i], i)
    }
  }
  await Promise.all(Array.from({ length: limitConcurrency }, worker))
  return results
}

async function uploadGif(exerciseId, wxId, attempt = 1) {
  const url = `${WORKOUTX_BASE}/gifs/${wxId}.gif`
  const res = await fetch(url, { headers: { 'X-WorkoutX-Key': WORKOUTX_API_KEY } })

  if (res.status === 429) {
    if (attempt > 5) {
      console.error(`  ✗ téléchargement GIF échoué (429 persistant) pour ${wxId}`)
      return null
    }
    const retryAfter = Number(res.headers.get('retry-after')) || attempt * 2
    await sleep(retryAfter * 1000 + 300)
    return uploadGif(exerciseId, wxId, attempt + 1)
  }

  if (!res.ok) {
    console.error(`  ✗ téléchargement GIF échoué (${res.status}) pour ${wxId}`)
    return null
  }
  const buffer = Buffer.from(await res.arrayBuffer())
  const objectPath = `${exerciseId}.gif`

  const { error } = await supabase.storage
    .from(BUCKET)
    .upload(objectPath, buffer, { contentType: 'image/gif', upsert: true })

  if (error) {
    console.error(`  ✗ upload échoué pour ${objectPath}:`, error.message)
    return null
  }

  const { data } = supabase.storage.from(BUCKET).getPublicUrl(objectPath)
  return data.publicUrl
}

async function main() {
  console.log('Récupération de WorkoutX...')
  const wxExercises = await loadWorkoutxExercises()
  console.log(`  ${wxExercises.length} exercices`)

  const translations = await loadTranslations()

  console.log('Récupération des tables muscle / exercise_category locales...')
  const [{ data: muscles }, { data: categories }] = await Promise.all([
    supabase.from('muscle').select('id, name'),
    supabase.from('exercise_category').select('id, name'),
  ])
  const muscleIdByName = new Map(muscles.map((m) => [m.name, m.id]))
  const categoryIdByName = new Map(categories.map((c) => [c.name, c.id]))

  if (!force) {
    const { count } = await supabase
      .from('exercise')
      .select('id', { count: 'exact', head: true })
      .eq('is_legacy', false)
      .eq('is_custom', false)
    if (count > 0) {
      console.error(`${count} exercices is_legacy=false existent déjà. Utilise --force pour ré-importer quand même.`)
      process.exit(1)
    }
  }

  const toImport = wxExercises.slice(0, limit === Infinity ? wxExercises.length : limit)

  const rows = toImport.map((ex) => {
    const id = randomUUID()
    const primaryMuscleFr = MUSCLE_MAP[ex.target] || null
    const categoryName = EQUIPMENT_TO_CATEGORY[ex.equipment] || 'Autre'
    return {
      id,
      wxId: ex.id,
      name: translations.get(ex.id) || ex.name,
      primary_muscle: primaryMuscleFr,
      measurement_type: CATEGORY_TO_MEASUREMENT[ex.category] || 'weight_reps',
      is_custom: false,
      is_legacy: false,
      category_id: categoryIdByName.get(categoryName) || null,
      hasGif: Boolean(ex.gifUrl),
      target: ex.target,
      secondaryMuscles: ex.secondaryMuscles || [],
    }
  })

  console.log(`\nPréparation de ${rows.length} exercices${dryRun ? ' (dry-run)' : ''}...`)

  if (dryRun) {
    for (const r of rows.slice(0, 20)) {
      const catName = [...categoryIdByName.entries()].find(([, id]) => id === r.category_id)?.[0]
      console.log(`  "${r.name}" — muscle: ${r.primary_muscle} — catégorie: ${catName} — mesure: ${r.measurement_type}`)
    }
    console.log(`  ... (${rows.length} au total)`)
    const missingMuscle = rows.filter((r) => !r.primary_muscle)
    if (missingMuscle.length) {
      console.log(`\n⚠ ${missingMuscle.length} exercices sans muscle mappé, ex: ${missingMuscle.slice(0, 5).map(r => r.target).join(', ')}`)
    }
    return
  }

  console.log('Téléchargement + upload des GIFs...')
  let uploaded = 0
  await mapConcurrent(rows, CONCURRENCY, async (r) => {
    if (r.hasGif) {
      r.image_url = await uploadGif(r.id, r.wxId)
    }
    await sleep(PACE_MS)
    uploaded++
    if (uploaded % 100 === 0) console.log(`  ${uploaded}/${rows.length} traités`)
  })
  console.log(`  ${uploaded}/${rows.length} traités`)

  console.log('\nInsertion des exercices...')
  const exerciseInserts = rows.map((r) => ({
    id: r.id,
    name: r.name,
    primary_muscle: r.primary_muscle,
    measurement_type: r.measurement_type,
    is_custom: r.is_custom,
    is_legacy: r.is_legacy,
    category_id: r.category_id,
    image_url: r.image_url || null,
  }))

  for (let i = 0; i < exerciseInserts.length; i += 200) {
    const chunk = exerciseInserts.slice(i, i + 200)
    const { error } = await supabase.from('exercise').insert(chunk)
    if (error) {
      console.error(`Erreur insertion exercices [${i}-${i + chunk.length}]:`, error.message)
      process.exit(1)
    }
  }
  console.log(`  ${exerciseInserts.length} exercices insérés`)

  console.log('Insertion des associations exercise_muscle...')
  const muscleLinks = []
  for (const r of rows) {
    const all = [
      ...(r.target ? [{ m: r.target, isPrimary: true }] : []),
      ...r.secondaryMuscles.map((m) => ({ m, isPrimary: false })),
    ]
    const seen = new Set()
    for (const { m, isPrimary } of all) {
      const muscleId = muscleIdByName.get(MUSCLE_MAP[m])
      if (!muscleId) continue
      const key = `${r.id}:${muscleId}`
      if (seen.has(key)) continue
      seen.add(key)
      muscleLinks.push({ exercise_id: r.id, muscle_id: muscleId, is_primary: isPrimary })
    }
  }
  for (let i = 0; i < muscleLinks.length; i += 500) {
    const chunk = muscleLinks.slice(i, i + 500)
    const { error } = await supabase.from('exercise_muscle').insert(chunk)
    if (error) {
      console.error(`Erreur insertion exercise_muscle [${i}-${i + chunk.length}]:`, error.message)
      process.exit(1)
    }
  }
  console.log(`  ${muscleLinks.length} associations exercise_muscle insérées`)

  console.log('\nTerminé.')
}

main()

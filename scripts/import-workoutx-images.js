// Associe une image (GIF) WorkoutX à chaque exercice existant du catalogue
// (approche hybride : on ne touche PAS à la liste d'exercices, on ajoute juste
// une image quand un match fiable est trouvé sur https://workoutxapp.com).
//
// Les GIFs WorkoutX nécessitent une clé API pour être récupérés : on les télécharge
// une fois puis on les réhéberge sur notre propre bucket Supabase, pour ne jamais
// exposer la clé API côté client et ne pas dépendre de leur quota à chaque affichage.
//
// Usage :
//   SUPABASE_URL=... SUPABASE_SERVICE_KEY=... WORKOUTX_API_KEY=... node scripts/import-workoutx-images.js [--dry-run] [--limit=N]

import { createClient } from '@supabase/supabase-js'
import { readFile, writeFile, mkdir } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const WORKOUTX_BASE = 'https://api.workoutxapp.com/v1'
const CACHE_PATH = path.join(__dirname, 'data', 'workoutx-exercises-cache.json')
const BUCKET = 'exercise-images'

const args = process.argv.slice(2)
const dryRun = args.includes('--dry-run')
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

// Mots vraiment sans signification distinctive (les mots d'équipement comme
// "barre"/"câble"/"machine" sont volontairement gardés : ils sont essentiels
// pour ne pas confondre les variantes d'un même mouvement selon l'équipement).
const STOPWORDS = new Set([
  'assis', 'debout', 'couche', 'unilateral', 'bilateral', 'alterne', 'alternee',
  'avec', 'sans', 'poids', 'prise', 'corde',
  'banc', 'sur', 'la', 'le', 'les', 'de', 'des', 'du', 'au', 'aux', 'et', 'ou', 'a', 'en',
  'position', 'depart', 'finale', 'variante', 'type',
])

// mot-clé FR (substring, normalisé) -> substring à chercher dans le champ `equipment` WorkoutX
const EQUIPMENT_HINTS = [
  ['smith machine', 'smith machine'],
  ['barre ez', 'ez barbell'],
  ['kettlebell', 'kettlebell'],
  ['elastique', 'band'],
  ['câble', 'cable'],
  ['cable', 'cable'],
  ['poids du corps', 'body weight'],
  ['haltere', 'dumbbell'],
  ['halteres', 'dumbbell'],
  ['barre', 'barbell'],
  ['machine', 'machine'],
]

function equipmentHint(name) {
  const n = normalize(name)
  for (const [frWord, wxSubstring] of EQUIPMENT_HINTS) {
    if (n.includes(frWord)) return wxSubstring
  }
  return null
}

function normalize(str) {
  return str
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

function tokens(str) {
  return normalize(str)
    .split(/[\s-]+/)
    .filter((t) => t.length > 1 && !STOPWORDS.has(t))
}

function jaccard(aTokens, bTokens) {
  const a = new Set(aTokens)
  const b = new Set(bTokens)
  if (a.size === 0 || b.size === 0) return 0
  let inter = 0
  for (const t of a) if (b.has(t)) inter++
  return inter / new Set([...a, ...b]).size
}

function extractParenthetical(name) {
  const match = name.match(/\(([^)]+)\)/g)
  if (!match) return null
  return match[match.length - 1].slice(1, -1)
}

// Certaines parenthèses ne contiennent qu'une précision d'équipement en FR
// (ex: "Face pull (câble)"), pas un nom d'exercice anglais. Dans ce cas la
// comparer telle quelle au nom WorkoutX ferait matcher n'importe quel exercice
// utilisant ce même équipement — on l'ignore et on retombe sur le nom complet.
const EQUIPMENT_ONLY_WORDS = new Set([
  'cable', 'cables', 'câble', 'câbles', 'haltere', 'halteres', 'haltère', 'haltères',
  'barre', 'machine', 'elastique', 'elastiques', 'élastique', 'élastiques',
  'kettlebell', 'kettlebells', 'poids', 'corps', 'du',
])

function isEquipmentOnlyPhrase(phrase) {
  const t = tokens(phrase)
  return t.length > 0 && t.every((w) => EQUIPMENT_ONLY_WORDS.has(w))
}

// Score une entrée WorkoutX contre un jeu de tokens, avec bonus/malus selon que
// l'équipement mentionné dans le nom FR correspond (ou contredit) le champ
// `equipment` structuré de WorkoutX. Le champ equipment est une donnée fiable :
// on s'en sert pour départager les variantes plutôt que de deviner via les mots.
function scoreEntry(queryTokens, hint, entry) {
  const base = jaccard(queryTokens, tokens(entry.name))
  // le bonus équipement ne sert qu'à départager des candidats déjà plausibles,
  // pas à fabriquer un match à partir d'un chevauchement de mots quasi nul
  if (base < 0.3) return base
  let score = base
  if (hint) {
    const eq = (entry.equipment || '').toLowerCase()
    if (eq.includes(hint)) score += 0.2
    else if (eq && eq !== 'other') score -= 0.15
  }
  return Math.max(0, Math.min(1, score))
}

function findBestMatch(dbName, wxExercises) {
  const hint = equipmentHint(dbName)
  const rawParen = extractParenthetical(dbName)
  const paren = rawParen && !isEquipmentOnlyPhrase(rawParen) ? rawParen : null

  if (paren) {
    const normParen = normalize(paren)
    const exact = wxExercises.find((e) => normalize(e.name) === normParen)
    if (exact) return { entry: exact, score: 1, via: 'parenthese-exacte' }

    const parenTokens = tokens(paren)
    let best = null
    let bestScore = 0
    for (const e of wxExercises) {
      const score = scoreEntry(parenTokens, hint, e)
      if (score > bestScore) {
        bestScore = score
        best = e
      }
    }
    if (best && bestScore >= 0.6) return { entry: best, score: bestScore, via: 'parenthese-fuzzy' }
  }

  const fullTokens = tokens(dbName)
  let best = null
  let bestScore = 0
  for (const e of wxExercises) {
    const score = scoreEntry(fullTokens, hint, e)
    if (score > bestScore) {
      bestScore = score
      best = e
    }
  }
  if (best && bestScore >= 0.75) return { entry: best, score: bestScore, via: 'nom-complet-fuzzy' }

  return null
}

// Le cache local (gitignored) évite de re-consommer du quota API à chaque essai
// pendant le développement du matching. Absent, on récupère tout en direct
// (paginé, throttlé pour respecter la limite de 30 req/min du plan gratuit).
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

async function fetchAllWorkoutxExercises() {
  const pageSize = 10
  let all = []
  let offset = 0
  let total = Infinity
  while (offset < total) {
    let res = await fetch(`${WORKOUTX_BASE}/exercises?limit=${pageSize}&offset=${offset}`, {
      headers: { 'X-WorkoutX-Key': WORKOUTX_API_KEY },
    })
    if (res.status === 429) {
      const body = await res.json()
      await sleep((body.retryAfter || 5) * 1000 + 500)
      continue
    }
    if (!res.ok) throw new Error(`Échec récupération liste WorkoutX: HTTP ${res.status}`)
    const json = await res.json()
    total = json.total
    all = all.concat(json.data)
    offset += pageSize
    await sleep(2100)
  }
  return all
}

async function uploadGif(exerciseId, wxId) {
  const url = `${WORKOUTX_BASE}/gifs/${wxId}.gif`
  const res = await fetch(url, { headers: { 'X-WorkoutX-Key': WORKOUTX_API_KEY } })
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
  console.log('Chargement des exercices WorkoutX (cache local)...')
  const wxExercises = await loadWorkoutxExercises()

  console.log('Récupération des exercices du catalogue (is_custom = false)...')
  const { data: exercises, error } = await supabase
    .from('exercise')
    .select('id, name, image_url')
    .eq('is_custom', false)
    .order('name')

  if (error) {
    console.error('Erreur lecture exercise:', error.message)
    process.exit(1)
  }
  console.log(`  ${exercises.length} exercices globaux trouvés`)

  const matched = []
  const unmatched = []

  for (const ex of exercises) {
    const result = findBestMatch(ex.name, wxExercises)
    if (result) matched.push({ exercise: ex, ...result })
    else unmatched.push(ex)
  }

  console.log(`\nMatching : ${matched.length}/${exercises.length} exercices matchés`)
  console.log('\n--- Matchés ---')
  for (const m of matched) {
    console.log(`  [${m.via}, score ${m.score.toFixed(2)}] "${m.exercise.name}" -> "${m.entry.name}" (${m.entry.id})`)
  }
  console.log('\n--- Non matchés ---')
  for (const u of unmatched) {
    console.log(`  "${u.name}"`)
  }

  if (dryRun) {
    console.log('\n(dry-run, aucune image téléchargée/uploadée)')
    return
  }

  console.log('\nTéléchargement + upload des GIFs (throttlé à ~28 req/min)...')
  let done = 0
  for (const m of matched) {
    if (done >= limit) break
    const { exercise, entry } = m

    const url = await uploadGif(exercise.id, entry.id)
    if (!url) {
      done++
      continue
    }

    const { error: updateError } = await supabase
      .from('exercise')
      .update({ image_url: url })
      .eq('id', exercise.id)

    if (updateError) {
      console.error(`  ✗ "${exercise.name}": échec update DB:`, updateError.message)
    } else {
      console.log(`  ✓ "${exercise.name}"`)
    }
    done++
    await sleep(2200)
  }

  console.log('\nTerminé.')
}

main()

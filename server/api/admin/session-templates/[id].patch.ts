import { serverSupabaseServiceRole } from '#supabase/server'

export default defineEventHandler(async (event) => {
  await requireAdmin(event)

  const id = getRouterParam(event, 'id')
  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'Identifiant manquant' })
  }

  const body = await readBody(event)
  const title = body?.title?.trim()
  const category = body?.category?.trim()
  const description = body?.description?.trim() || null
  const exercises = Array.isArray(body?.exercises) ? body.exercises : []

  if (!title || !category) {
    throw createError({ statusCode: 400, statusMessage: 'Le titre et la catégorie sont requis' })
  }
  if (exercises.length === 0 || exercises.some((e: any) => !e?.exercise_id)) {
    throw createError({ statusCode: 400, statusMessage: 'Au moins un exercice valide est requis' })
  }

  const supabase = serverSupabaseServiceRole(event)

  const { data: template, error: templateError } = await supabase
    .from('session_template')
    .update({ title, category, description })
    .eq('id', id)
    .select()
    .single()

  if (templateError) {
    throw createError({ statusCode: 400, statusMessage: templateError.message })
  }

  const { error: deleteError } = await supabase
    .from('session_template_exercise')
    .delete()
    .eq('template_id', id)

  if (deleteError) {
    throw createError({ statusCode: 400, statusMessage: deleteError.message })
  }

  const exerciseRows = exercises.map((exercise: any, index: number) => ({
    template_id: id,
    exercise_id: exercise.exercise_id,
    order: index + 1,
    target_sets: exercise.target_sets || null,
    target_reps: exercise.target_reps?.trim() || null
  }))

  const { error: exercisesError } = await supabase
    .from('session_template_exercise')
    .insert(exerciseRows)

  if (exercisesError) {
    throw createError({ statusCode: 400, statusMessage: exercisesError.message })
  }

  return { success: true, data: template }
})

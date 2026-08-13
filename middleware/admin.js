import { adminFetch } from '~/composables/useAdminFetch'

export default defineNuxtRouteMiddleware(async () => {
  const user = useSupabaseUser()
  if (!user.value) {
    return navigateTo('/login')
  }

  try {
    const { isAdmin } = await adminFetch('/api/admin/check')
    if (!isAdmin) {
      return navigateTo('/catalogue')
    }
  } catch (error) {
    console.error('Erreur lors de la vérification des droits admin:', error)
    return navigateTo('/catalogue')
  }
})

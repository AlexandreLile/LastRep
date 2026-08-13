export default defineEventHandler(async (event) => {
  const isAdmin = await isAdminEvent(event)
  return { isAdmin }
})

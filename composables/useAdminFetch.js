// L'app stocke la session Supabase en localStorage (pas de cookies SSR), donc le
// serveur ne peut pas authentifier les requêtes /api/admin/* via les cookies : on
// transmet explicitement l'access_token en en-tête Authorization.
export async function adminFetch(url, options = {}) {
  const supabase = useSupabaseClient();
  const { data: { session } } = await supabase.auth.getSession();

  const headers = {
    ...(options.headers || {}),
    ...(session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {})
  };

  return $fetch(url, { ...options, headers });
}

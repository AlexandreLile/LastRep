# TODO

## Sécurité

- [ ] **Rotation des clés Supabase** — le project ref `jlfiuwpuixzvwcnsyxzw` est visible dans l'historique git (anciens fichiers markdown). Aucune clé n'a fuité, mais par précaution :
  1. Dashboard Supabase → Settings → API → Regenerate **anon key**
  2. Dashboard Supabase → Settings → API → Regenerate **service_role key**
  3. Mettre à jour les variables dans Vercel (prod + preview)
  4. Mettre à jour le `.env.local` en local

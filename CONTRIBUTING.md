# Contributing — LastRep

## Workflow de branches

```
production (déploiement Vercel réel — voir note ci-dessous)
 └── main (release-ready, pas encore déployé)
      └── develop (staging / intégration)
           ├── feature/xxx
           ├── fix/xxx
           ├── chore/xxx
           └── hotfix/xxx  ← part de main directement, merge dans main ET develop
```

**Règles :**
- `production` = branche surveillée par Vercel pour le déploiement en prod (voir note ci-dessous). Jamais touchée directement.
- `main` = release-ready, prête à être promue en prod, mais **pas encore déployée tant qu'elle n'est pas mergée dans `production`**. Jamais touché directement.
- `develop` = branche d'intégration. Toute nouvelle branche part d'ici.
- `hotfix/*` = seul cas où on part de `main` (bug critique en prod). Merger dans `main` ET `develop` après, puis suivre la mise en prod normale (`main` → `production`).
- Chaque branche de travail est supprimée après merge.

> **Note — pourquoi `production` existe :** le déploiement Vercel réel (environnement "Production" côté Vercel) est configuré pour suivre la branche `production`, pas `main`. Un push/merge sur `main` seul ne déclenche qu'un déploiement **Preview** sur Vercel, pas une mise en prod. Ce point n'est pas configuré dans les workflows GitHub Actions (`deploy-prod.yml`/`deploy-dev.yml`), qui échouent systématiquement depuis leur création (secret `VERCEL_TOKEN` manquant) et n'ont donc aucun effet — c'est l'intégration native GitHub de Vercel qui fait le vrai déploiement. Tant que ces workflows ne sont pas corrigés (ou supprimés), ignorer leur statut d'échec dans les checks de PR.

### Créer une branche de travail

```bash
git checkout develop
git pull origin develop
git checkout -b feature/ma-feature
```

### Nommage des branches

| Préfixe | Usage |
|---|---|
| `feature/` | Nouvelle fonctionnalité |
| `fix/` | Correction de bug (non critique) |
| `chore/` | Maintenance, dépendances, config |
| `hotfix/` | Bug critique en production |
| `docs/` | Documentation uniquement |
| `refactor/` | Refactoring sans changement de comportement |

Exemples : `feature/stripe-checkout`, `fix/refresh-token`, `chore/update-deps`

---

## Convention de commits — Conventional Commits

Format : `<type>(<scope optionnel>): <description courte>`

| Type | Usage |
|---|---|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `chore` | Maintenance, build, dépendances |
| `docs` | Documentation uniquement |
| `refactor` | Refactoring (pas de bug fix, pas de nouvelle feature) |
| `style` | Formatage, espaces, virgules (pas de changement logique) |
| `test` | Ajout ou correction de tests |
| `perf` | Amélioration de performance |
| `ci` | Changements CI/CD |

Exemples :
```
feat(auth): add OAuth Google login
fix(sessions): prevent duplicate exercise entries
chore: upgrade nuxt to 3.17
docs: update deployment guide
refactor(stats): extract chart helpers into composable
```

**Règles :**
- Description en minuscules, sans majuscule ni point final
- Corps du message si le "pourquoi" n'est pas évident (ligne vide, puis explication)
- Breaking change : ajouter `!` après le type — `feat!: remove legacy API`

---

## Processus Pull Request

1. Pousser sa branche : `git push origin feature/ma-feature`
2. Ouvrir une PR vers `develop` (jamais directement vers `main`)
3. Remplir le template de PR
4. Attendre la review (au moins 1 approbation)
5. **Squash & Merge** uniquement — 1 commit propre par feature
6. La branche source est supprimée automatiquement après le merge

### Merge vers main puis production (mise en prod)

Quand `develop` est stable et testé, la mise en prod se fait en **deux étapes** :

1. Ouvrir une PR `develop` → `main`
2. Valider manuellement via GitHub Environments (étape de confirmation)
3. Squash & Merge
4. Ouvrir une PR `main` → `production` (c'est ce merge qui déclenche le vrai déploiement Vercel)
5. Merge (pas de squash nécessaire ici, `main` est déjà propre)

**Étape 4 obligatoire** : sans elle, le code reste release-ready sur `main` mais n'est jamais réellement déployé en production.

---

## Règles absolues

- Aucun `git push` direct sur `main`, `develop` ou `production`
- Aucun `--force` sur ces branches
- Aucun commit sans message conforme à Conventional Commits
- Les fichiers `.env*` ne sont jamais commités (vérifier `.gitignore`)

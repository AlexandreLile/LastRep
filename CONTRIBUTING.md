# Contributing — LastRep

## Workflow de branches

```
production (déploiement Vercel réel)
 └── develop (staging / intégration)
      ├── feature/xxx
      ├── fix/xxx
      ├── chore/xxx
      └── hotfix/xxx  ← part de production directement, merge dans production ET develop
```

**Règles :**
- `production` = branche surveillée par Vercel pour le déploiement en prod. Jamais touchée directement.
- `develop` = branche d'intégration. Toute nouvelle branche part d'ici.
- `hotfix/*` = seul cas où on part de `production` (bug critique en prod). Merger dans `production` ET `develop` après.
- Chaque branche de travail est supprimée après merge.

> **Historique :** ce projet utilisait auparavant 3 branches (`develop` → `main` → `production`), `main` servant d'étape "release-ready" intermédiaire avant `production` (seule branche réellement suivie par Vercel — un merge sur `main` seul ne déclenchait qu'un déploiement Preview). Cette étape supplémentaire n'apportait pas de vraie valeur et créait des conflits récurrents entre branches divergentes à chaque mise en prod. `main` a été retirée du workflow : `develop` se merge désormais directement dans `production`.

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
2. Ouvrir une PR vers `develop` (jamais directement vers `production`)
3. Remplir le template de PR
4. Attendre la review (au moins 1 approbation)
5. **Squash & Merge** uniquement — 1 commit propre par feature
6. La branche source est supprimée automatiquement après le merge

### Merge vers production (mise en prod)

Quand `develop` est stable et testé :

1. Ouvrir une PR `develop` → `production`
2. Merger avec **"Create a merge commit"** — jamais squash. C'est ce merge qui déclenche le vrai déploiement Vercel.

> **Important :** le squash sur ce merge spécifique casse l'ancestry entre `develop` et `production` (un vrai commit de merge à 2 parents est nécessaire), ce qui fait réapparaître indéfiniment de faux conflits sur les fichiers déjà résolus lors d'un merge précédent.

---

## Règles absolues

- Aucun `git push` direct sur `develop` ou `production`
- Aucun `--force` sur ces branches
- Aucun commit sans message conforme à Conventional Commits
- Les fichiers `.env*` ne sont jamais commités (vérifier `.gitignore`)

# Convention de versioning — ifpen/helm-charts

> Document de référence pour comprendre les règles de versioning des images Docker
> et des charts Helm dans ce dépôt.

## Principe : deux axes indépendants

| Axe | Ce qu'il versionne | Déclencheur | Source de vérité |
|-----|-------------------|-------------|------------------|
| **Tag image** `ghcr.io/ifpen/filesender:x.y.z` | L'image Docker FileSender (PHP, SimpleSAMLphp, Nginx, AWS SDK, correctifs Docker) | Changement dans `docker/filesender/**` sur `main` | `ARG FILESENDER_VERSION` dans le Dockerfile + compteur `.z` |
| **Version chart** `charts/filesender/Chart.yaml: version` | Le packaging Helm (templates, values, dépendances) | Nouvelle image construite OU changement de packaging seul (`charts/filesender/**`) | `Chart.yaml: version` (géré par auto-commit `[skip ci]`) |

Les deux axes partagent la même base `x.y` (version FileSender) mais leurs compteurs `.z`
évoluent de façon **indépendante** selon les déclencheurs ci-dessus.

---

## Axe 1 — Tag de l'image FileSender

### Format

```
x.y.z
```

- `x.y` = version **FileSender**, lue depuis `ARG FILESENDER_VERSION` dans
  `docker/filesender/Dockerfile` (ex. `3.10`).
- `.z` = **patch** auto-incrémenté à chaque reconstruction de l'image causée par
  un composant **interne** au conteneur (PHP, SimpleSAMLphp, AWS SDK, correctifs
  Dockerfile), **sans** changement de `x.y`.
- Quand `x.y` change (nouvelle version FileSender), `.z` repart à **0**.

### Calcul du patch `.z`

Le script `.github/scripts/version-filesender.sh` :

1. Interroge l'API GHCR (`ghcr.io/v2/<owner>/filesender/tags/list`) pour trouver
   le dernier tag `x.y.*` déjà publié.
2. Si un tag `x.y.N` existe → `z = N + 1`.
3. Si aucun tag `x.y.*` n'existe (première build sur cette base) → `z = 0`.
4. En cas d'indisponibilité de l'API GHCR, fallback sur le patch du `Chart.yaml`
   local (même logique d'incrément).

### ⚠️ PostgreSQL exclu

L'image FileSender ne contient **pas** PostgreSQL (c'est une image officielle
`postgres` référencée dans `values.yaml`). Un bump du tag PostgreSQL dans
`values.yaml` **ne déclenche jamais** de reconstruction de l'image FileSender ;
il bumpe uniquement le **chart**.

### Tags sur `develop`

Sur la branche `develop`, l'image reçoit un tag prévisuel de la forme :

```
develop-<sha7>-<timestamp>
```

Aucun tag stable `x.y.z` n'est publié sur `develop`.

---

## Axe 2 — Version du chart Helm

### Format

```
x.y.z
```

Même base `x.y` que FileSender, mais `.z` est le **patch propre du chart**,
indépendant du patch de l'image.

### Règles de bump

Le chart est bumpé automatiquement (commit `[skip ci]`) dans ces cas :

| Cas | Workflow | Action |
|-----|---------|--------|
| Nouvelle image FileSender construite (`docker/filesender/**` modifié sur `main`) | `docker-build.yml` | Bump `version` chart + mise à jour `values.yaml: image.tag` + `appVersion` |
| Changement de packaging sans image (`charts/filesender/**` modifié, sans `docker/**`) | `chart-bump.yml` | Bump **patch** de `version` uniquement |

### Lien à sens unique (image → chart)

```
docker/filesender/Dockerfile
         │
         │  ARG FILESENDER_VERSION=x.y
         ▼
.github/scripts/version-filesender.sh
         │
         │  calcule image_tag=x.y.z  chart_version=x.y.z
         ▼
charts/filesender/values.yaml     charts/filesender/Chart.yaml
  image.tag: "x.y.z"               version: x.y.z
                                    appVersion: "x.y"
```

Un changement dans le chart (ex. bump PostgreSQL) **ne remonte jamais**
vers l'image Docker.

---

## Scénarios

| Scénario | Image reconstruite ? | Chart bumpé ? | Détail |
|---------|---------------------|--------------|--------|
| Bump tag PostgreSQL dans `values.yaml` | ❌ Non | ✅ Oui (patch) | `chart-bump.yml`, `image.tag` FileSender inchangé |
| Bump PHP / SimpleSAMLphp dans Dockerfile | ✅ Oui (`.z+1`) | ✅ Oui (même `x.y.z`) | `docker-build.yml` reconstruit l'image et met à jour le chart |
| Bump FileSender (`x.y` change, ex. `3.10` → `3.11`) | ✅ Oui (`z=0`) | ✅ Oui (base `x.y` change, `z=0`) | `docker-build.yml`, `appVersion` mis à jour |
| Modif `values.yaml` ou templates seule | ❌ Non | ✅ Oui (patch) | `chart-bump.yml` |
| Modif `.github/**` seule | ❌ Non | ❌ Non | `ci-self.yml` lint uniquement |

---

## Anti-boucle d'auto-commit

Tous les commits automatiques (auto-bump chart, mise à jour `image.tag`) portent
le suffixe `[skip ci]` dans leur message. GitHub Actions ignore automatiquement
les pushes dont le message contient ce suffixe, évitant toute boucle infinie.

---

## Resynchronisation initiale (PR de refonte)

Lors de la refonte des workflows (juin 2026), le chart a été resynchronisé :

- **Avant** : `version: 3.6.5`, `appVersion: "3.6"` — décalé de FileSender 3.10.
- **Après** : `version: 3.10.0`, `appVersion: "3.10"` — aligné sur FileSender 3.10.

La version `3.10.0 > 3.6.5` en semver, donc compatible avec `helm/chart-releaser-action`.

---

## Architecture multi-chart / multi-image

Les registres JSON pilotent les workflows :

- `.github/config/images.json` : liste des images à construire (contexte, Dockerfile,
  filtre de chemin, script de versioning).
- `.github/config/charts.json` : liste des charts (chemin, image liée, filtre de chemin).

Pour ajouter un nouveau chart ou une nouvelle image : ajouter une entrée dans le
registre correspondant. Les workflows `docker-build.yml`, `chart-bump.yml`,
`pr-validation.yml` et `rc-release.yml` s'adaptent automatiquement via des matrices
dynamiques générées depuis ces JSON.

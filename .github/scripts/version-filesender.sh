#!/usr/bin/env bash
# version-filesender.sh — Calcule les versions image et chart pour FileSender.
#
# Usage : .github/scripts/version-filesender.sh <dockerfile>
#
# Sorties (sur stdout, format clé=valeur) :
#   filesender_version  — x.y lu depuis ARG FILESENDER_VERSION dans le Dockerfile
#   image_tag           — x.y.z  (tag stable pour main ; voir règle de patch ci-dessous)
#   chart_version       — x.y.z  (version du chart alignée sur FileSender)
#   app_version         — x.y    (pour appVersion dans Chart.yaml)
#   description_suffix  — "FileSender vx.y" (pour la description du Chart.yaml)
#
# Règle de calcul du patch (z) :
#   • Si des tags ghcr.io/ifpen/filesender x.y.* existent déjà dans GHCR,
#     z = (dernier patch trouvé) + 1.
#   • Si aucun tag x.y.* n'existe encore, z = 0.
#   • Quand x.y change (nouvelle version FileSender), z repart à 0.
#   PostgreSQL n'entre jamais dans ce calcul.
#
# Méthode d'interrogation des tags GHCR :
#   On utilise l'API GitHub Container Registry (OCI Distribution Spec / ghcr.io/v2)
#   via curl. Si l'appel API échoue (réseau absent en test local), on retombe
#   sur une lecture du Chart.yaml courant pour dériver z.

set -euo pipefail

DOCKERFILE="${1:-}"

if [[ -z "$DOCKERFILE" ]]; then
  echo "::error::Usage: $0 <dockerfile>" >&2
  exit 1
fi

if [[ ! -f "$DOCKERFILE" ]]; then
  echo "::error::Dockerfile introuvable: $DOCKERFILE" >&2
  exit 1
fi

# ── 1. Lire FILESENDER_VERSION depuis le Dockerfile ──────────────────────────
FS_VERSION="$(grep -m1 '^ARG FILESENDER_VERSION=' "$DOCKERFILE" \
  | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ')"

if [[ -z "$FS_VERSION" ]]; then
  echo "::error::ARG FILESENDER_VERSION introuvable dans $DOCKERFILE" >&2
  exit 1
fi

# Valider le format x.y (ou x.y.z)
if ! echo "$FS_VERSION" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
  echo "::error::FILESENDER_VERSION mal formé: '$FS_VERSION' (attendu x.y ou x.y.z)" >&2
  exit 1
fi

# Normaliser en x.y uniquement
BASE_XY="$(echo "$FS_VERSION" | cut -d'.' -f1-2)"

# ── 2. Calculer le patch (z) ─────────────────────────────────────────────────
# Stratégie : interroger l'API GHCR pour lister les tags existants x.y.*
# En cas d'échec de l'API (pas de token, réseau coupé, premier build), fallback
# sur le Chart.yaml local.

PATCH=0
REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-ifpen}"
IMAGE_NAME="filesender"
GHCR_API="https://ghcr.io/v2/${REPO_OWNER}/${IMAGE_NAME}/tags/list"

# Tentative d'appel API GHCR (nécessite GITHUB_TOKEN ou accès public)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  TAGS_JSON="$(curl -sf \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${GHCR_API}" 2>/dev/null || echo "")"
else
  # Accès anonyme — fonctionne pour les packages publics
  TAGS_JSON="$(curl -sf "${GHCR_API}" 2>/dev/null || echo "")"
fi

if [[ -n "$TAGS_JSON" ]]; then
  # Extraire tous les tags de la forme x.y.z stables (sans suffixe rc/dev)
  BASE_XY_ESCAPED="${BASE_XY//./\\.}"
  LATEST_PATCH="$(echo "$TAGS_JSON" \
    | grep -oE "\"${BASE_XY_ESCAPED}\.[0-9]+\"" \
    | tr -d '"' \
    | grep -oE '[0-9]+$' \
    | sort -n \
    | tail -1 || echo "")"

  if [[ -n "$LATEST_PATCH" ]]; then
    PATCH=$((LATEST_PATCH + 1))
    echo "# version-filesender: patch calculé depuis GHCR (dernier=${LATEST_PATCH} → nouveau=${PATCH})" >&2
  else
    echo "# version-filesender: aucun tag ${BASE_XY}.* trouvé sur GHCR → patch=0" >&2
    PATCH=0
  fi
else
  # Fallback : lire le Chart.yaml local pour dériver z
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  CHART_YAML="${SCRIPT_DIR}/../../charts/filesender/Chart.yaml"

  if [[ -f "$CHART_YAML" ]]; then
    CHART_VERSION="$(grep '^version:' "$CHART_YAML" | awk '{print $2}')"
    CHART_BASE="$(echo "$CHART_VERSION" | cut -d'.' -f1-2)"
    CHART_PATCH="$(echo "$CHART_VERSION" | cut -d'.' -f3)"

    if [[ "$CHART_BASE" == "$BASE_XY" && -n "$CHART_PATCH" ]]; then
      # Même base x.y : on incrémente le patch du chart
      PATCH=$((CHART_PATCH + 1))
      echo "# version-filesender: patch calculé depuis Chart.yaml (${CHART_VERSION} → patch ${PATCH})" >&2
    else
      # Changement de x.y ou chart inexistant : on repart de 0
      PATCH=0
      echo "# version-filesender: base x.y a changé ou chart absent → patch=0" >&2
    fi
  else
    echo "# version-filesender: pas d'API GHCR ni de Chart.yaml → patch=0" >&2
    PATCH=0
  fi
fi

# ── 3. Émettre les variables de sortie ───────────────────────────────────────
IMAGE_TAG="${BASE_XY}.${PATCH}"
CHART_VERSION="${BASE_XY}.${PATCH}"

echo "filesender_version=${FS_VERSION}"
echo "image_tag=${IMAGE_TAG}"
echo "chart_version=${CHART_VERSION}"
echo "app_version=${BASE_XY}"
echo "description_suffix=FileSender v${BASE_XY}"

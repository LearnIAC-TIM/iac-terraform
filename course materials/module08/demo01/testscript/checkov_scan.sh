#!/usr/bin/env bash
set -euo pipefail

# Bruk: ./checkov_scan.sh <WORKDIR> [SARIF_DIR]

# Ta inn WORKDIR som $1
WORKDIR_IN="${1:-}"

# Avvis tom verdi
if [[ -z "${WORKDIR_IN}" ]]; then
  echo "Bruk: $0 <WORKDIR> [..]" >&2
  exit 2
fi

# Hvis stien ikke er absolutt, forsøk å forankre den i GITHUB_WORKSPACE
if [[ "${WORKDIR_IN}" != /* ]]; then
  if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    WORKDIR_CANDIDATE="${GITHUB_WORKSPACE}/${WORKDIR_IN}"
  else
    # fall-back til nåværende arbeidskatalog
    WORKDIR_CANDIDATE="${PWD}/${WORKDIR_IN}"
  fi
else
  WORKDIR_CANDIDATE="${WORKDIR_IN}"
fi

# Normaliser og verifiser
WORKDIR_ABS="$(cd "${WORKDIR_CANDIDATE}" 2>/dev/null && pwd -P)" || {
  echo "Fant ikke WORKDIR: ${WORKDIR_IN}" >&2
  exit 3
}

SARIF_DIR_ABS="${WORKDIR_ABS}/${SARIF_DIR_REL}"
mkdir -p "${SARIF_DIR_ABS}"

echo "=== Checkov ==="
echo "Arbeidskatalog: ${WORKDIR_ABS}"
echo "SARIF-katalog:  ${SARIF_DIR_ABS}"
echo

# Produser både CLI og SARIF. Bevar exit-koden, men sørg for at SARIF finnes.
set +e
checkov -d "${WORKDIR_ABS}" \
  --framework terraform \
  --compact \
  --output cli \
  --output sarif --output-file-path "${SARIF_DIR_REL}"
EXIT_CODE=$?
set -e

SARIF_FILE="$(find "${SARIF_DIR_ABS}" -maxdepth 1 -name '*.sarif' -print -quit || true)"
if [[ -z "${SARIF_FILE}" ]]; then
  echo "⚠️  Ingen SARIF-fil funnet etter Checkov-kjøring." >&2
  exit 4
fi

echo "✅ Checkov fullført. SARIF-fil: ${SARIF_FILE}"
exit "${EXIT_CODE}"

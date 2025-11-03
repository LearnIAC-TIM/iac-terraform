#!/usr/bin/env bash
set -euo pipefail

# Bruk: ./checkov_scan.sh <WORKDIR> [SARIF_DIR]

WORKDIR_IN="${1:-}"
SARIF_DIR_REL="${2:-results.sarif}"

if [[ -z "${WORKDIR_IN}" ]]; then
  echo "Bruk: $0 <WORKDIR> [SARIF_DIR]" >&2
  exit 2
fi

WORKDIR_ABS="$(cd "${WORKDIR_IN}" 2>/dev/null && pwd -P)" || {
  echo "Fann ikkje WORKDIR: ${WORKDIR_IN}" >&2
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

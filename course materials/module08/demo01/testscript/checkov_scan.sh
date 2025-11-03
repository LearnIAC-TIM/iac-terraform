#!/usr/bin/env bash
set -euo pipefail

# Bruk: ./checkov_scan.sh <WORKDIR> [SARIF_DIR]
# Eksempel: ./checkov_scan.sh "course materials/module08/demo01" "results.sarif"

# 1) Inndata med sikre standarder
WORKDIR_IN="${1:-}"
SARIF_DIR_REL="${2:-results.sarif}"

if [[ -z "${WORKDIR_IN}" ]]; then
  echo "Bruk: $0 <WORKDIR> [SARIF_DIR]" >&2
  exit 2
fi

# 2) Gjør WORKDIR absolutt, forankret i GITHUB_WORKSPACE om nødvendig
if [[ "${WORKDIR_IN}" != /* ]]; then
  if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    WORKDIR_CANDIDATE="${GITHUB_WORKSPACE}/${WORKDIR_IN}"
  else
    WORKDIR_CANDIDATE="${PWD}/${WORKDIR_IN}"
  fi
else
  WORKDIR_CANDIDATE="${WORKDIR_IN}"
fi

WORKDIR_ABS="$(cd "${WORKDIR_CANDIDATE}" 2>/dev/null && pwd -P)" || {
  echo "Fant ikke WORKDIR: ${WORKDIR_IN}" >&2
  exit 3
}

# 3) Beregn og opprett SARIF-katalogen (relativ til WORKDIR)
SARIF_DIR_ABS="${WORKDIR_ABS}/${SARIF_DIR_REL}"
mkdir -p "${SARIF_DIR_ABS}"

echo "=== Checkov ==="
echo "Arbeidskatalog: ${WORKDIR_ABS}"
echo "SARIF-katalog:  ${SARIF_DIR_ABS}"
echo

# 4) Kjør Checkov. Behold exit-kode, men sørg for at SARIF faktisk finnes.
set +e
checkov -d "${WORKDIR_ABS}" \
  --framework terraform \
  --compact \
  --output cli \
  --output sarif --output-file-path "${SARIF_DIR_REL}"
EXIT_CODE=$?
set -e

# 5) Verifiser SARIF og rapporter filsti
SARIF_FILE="$(find "${SARIF_DIR_ABS}" -maxdepth 1 -name '*.sarif' -print -quit || true)"
if [[ -z "${SARIF_FILE}" ]]; then
  echo "Ingen SARIF-fil funnet etter Checkov-kjøring." >&2
  exit 4
fi

echo "✅ Checkov fullført. SARIF-fil: ${SARIF_FILE}"
exit "${EXIT_CODE}"

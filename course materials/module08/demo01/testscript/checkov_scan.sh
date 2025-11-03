#!/usr/bin/env bash
set -euo pipefail

# Bruk: ./checkov_scan.sh <WORKDIR> [SARIF_FILE_REL]
# Eksempel: ./checkov_scan.sh "course materials/module08/demo01" "results.sarif/checkov.sarif"

WORKDIR_IN="${1:-}"
SARIF_FILE_REL="${2:-results.sarif/checkov.sarif}"

if [[ -z "${WORKDIR_IN}" ]]; then
  echo "Bruk: $0 <WORKDIR> [SARIF_FILE_REL]" >&2
  exit 2
fi

# Forankre relativ WORKDIR i GitHub-arbeidsområdet ved behov
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

# Sørg for at katalogen for SARIF-filen finnes
SARIF_DIR_ABS="${WORKDIR_ABS}/$(dirname "${SARIF_FILE_REL}")"
mkdir -p "${SARIF_DIR_ABS}"

echo "=== Checkov ==="
echo "Arbeidskatalog: ${WORKDIR_ABS}"
echo "SARIF-fil:      ${WORKDIR_ABS}/${SARIF_FILE_REL}"
echo

# Kjør Checkov og skriv både CLI og SARIF til en konkret fil
set +e
checkov -d "${WORKDIR_ABS}" \
  --framework terraform \
  --compact \
  --output cli \
  --output sarif --output-file-path "${SARIF_FILE_REL}"
EXIT_CODE=$?
set -e

# Verifisér at filen faktisk finnes
SARIF_ABS="${WORKDIR_ABS}/${SARIF_FILE_REL}"
if [[ ! -f "${SARIF_ABS}" ]]; then
  echo "Ingen SARIF-fil funnet: ${SARIF_ABS}" >&2
  exit 4
fi

echo "✅ Checkov fullført. SARIF-fil: ${SARIF_ABS}"
exit "${EXIT_CODE}"

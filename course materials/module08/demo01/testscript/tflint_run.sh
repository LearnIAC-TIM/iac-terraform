#!/usr/bin/env bash
set -euo pipefail

# Bruk: ./tflint_run.sh <WORKDIR>

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

echo "=== TFLint ==="
echo "Arbeidskatalog: ${WORKDIR_ABS}"
echo

# Kjør inne i katalogen for å unngå --chdir og relative sti-problemer
pushd "${WORKDIR_ABS}" >/dev/null

echo "[1/2] tflint --init"
tflint --init

echo "[2/2] tflint -f compact"
tflint -f compact

popd >/dev/null
echo "✅ TFLint fullført."

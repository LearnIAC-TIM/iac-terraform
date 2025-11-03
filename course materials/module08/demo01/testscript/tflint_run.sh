#!/usr/bin/env bash
set -euo pipefail

# Bruk: ./tflint_run.sh <WORKDIR>

WORKDIR_IN="${1:-}"
if [[ -z "${WORKDIR_IN}" ]]; then
  echo "Bruk: $0 <WORKDIR>" >&2
  exit 2
fi

WORKDIR_ABS="$(cd "${WORKDIR_IN}" 2>/dev/null && pwd -P)" || {
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

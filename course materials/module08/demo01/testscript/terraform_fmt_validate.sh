#!/usr/bin/env bash
set -euo pipefail

# Bruk: ./tflint_run.sh <WORKDIR>

WORKDIR="${1:-}"

if [[ -z "$WORKDIR" ]]; then
  echo "Bruk: $0 <WORKDIR>" >&2
  exit 2
fi

echo "=== TFLint starter ==="
echo "Arbeidskatalog: $WORKDIR"
echo

# 1) Init TFLint (henter plugins)
echo "[1/2] tflint --init"
tflint --chdir "$WORKDIR" --init

# 2) Kjør TFLint
echo "[2/2] tflint -f compact"
tflint --chdir "$WORKDIR" -f compact

echo "✅ TFLint fullført."

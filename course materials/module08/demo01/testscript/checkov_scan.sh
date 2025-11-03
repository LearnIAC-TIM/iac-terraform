#!/usr/bin/env bash
set -euo pipefail

# Bruk: ./checkov_scan.sh <WORKDIR> [SARIF_DIR]

WORKDIR="${1:-}"
SARIF_DIR="${2:-results.sarif}"

if [[ -z "$WORKDIR" ]]; then
  echo "Bruk: $0 <WORKDIR> [SARIF_DIR]" >&2
  exit 2
fi

mkdir -p "$WORKDIR/$SARIF_DIR"

echo "=== Checkov-sjekk starter ==="
echo "Arbeidskatalog: $WORKDIR"
echo "SARIF-output:   $WORKDIR/$SARIF_DIR"
echo

# Kjør Checkov og produser både CLI- og SARIF-output
set +e
checkov -d "$WORKDIR" \
  --framework terraform \
  --compact \
  --output cli \
  --output sarif --output-file-path "$SARIF_DIR"
EXIT_CODE=$?
set -e

# Sjekk at SARIF-fil finnes
SARIF_FILE=$(find "$WORKDIR/$SARIF_DIR" -maxdepth 1 -name '*.sarif' -print -quit || true)
if [[ -z "$SARIF_FILE" ]]; then
  echo "⚠️  Ingen SARIF-fil funnet etter Checkov-kjøring." >&2
  exit 3
fi

echo "✅ Checkov fullført. SARIF-fil: $SARIF_FILE"
exit "$EXIT_CODE"

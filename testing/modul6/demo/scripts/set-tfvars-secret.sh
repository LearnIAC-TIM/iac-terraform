#!/usr/bin/env bash
# =============================================================================
#  scripts/set-tfvars-secret.sh  –  ÉN tfvars-fil inn i Key Vault
# -----------------------------------------------------------------------------
#  Samme script som i Oppgave 5 og modul 5-videoen. Oppgave 6 ber studentene
#  bruke akkurat denne kommandoen for tfvars-prod, så den er tatt med uendret
#  i bruk:
#
#      ./set-tfvars-secret.sh <kv-navn> tfvars-prod ./prod.tfvars
#
#  02-last-opp-tfvars.sh kaller denne for alle tre miljøene.
# =============================================================================
set -euo pipefail

KV_NAME="${1:-}"          # Key Vault-navn
SECRET_NAME="${2:-}"      # f.eks. "tfvars-dev"
FILE_PATH="${3:-}"        # f.eks. "./dev.tfvars"
SUBSCRIPTION_ID="${4:-}"  # valgfritt

if [[ -z "$KV_NAME" || -z "$SECRET_NAME" || -z "$FILE_PATH" ]]; then
  echo "Bruk: $0 <kv-name> <secret-name> <path-to-.tfvars> [subscription-id]" >&2
  exit 1
fi
if [[ ! -f "$FILE_PATH" ]]; then
  echo "Fant ikke fil: $FILE_PATH" >&2
  exit 1
fi

if [[ -n "$SUBSCRIPTION_ID" ]]; then
  az account set --subscription "$SUBSCRIPTION_ID"
fi

BYTES=$(wc -c < "$FILE_PATH" | tr -d ' ')
if (( BYTES > 24500 )); then
  echo "Advarsel: Innholdet er ~${BYTES} byte (> ~25 KB)." >&2
fi

# --file leser hele fila som secret-verdi og bevarer linjeskift.
az keyvault secret set \
  --vault-name "$KV_NAME" \
  --name "$SECRET_NAME" \
  --file "$FILE_PATH" \
  --content-type 'application/tfvars; charset=utf-8' \
  --only-show-errors \
  --query '{id:id, name:name, contentType:contentType}'

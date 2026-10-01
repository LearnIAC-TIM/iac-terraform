#!/usr/bin/env bash
# =============================================================================
#  scripts/01-sjekk-azure.sh  –  finnes alt fra modul 4/5 i Azure?
# -----------------------------------------------------------------------------
#  Endrer ingenting. Sjekker at backend og Key Vault finnes, og at du selv har
#  lov til å skrive secrets (det trenger 02-last-opp-tfvars.sh).
#
#      az login
#      ./scripts/01-sjekk-azure.sh
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/config.sh"
krev_az

info "Innlogget som"
az account show --query '{bruker:user.name, subscription:name}' -o tsv | sed 's/^/  /'

info "Backend"
if az group show -n "$TFSTATE_RG" -o none 2>/dev/null; then ok "Resource group $TFSTATE_RG"; else feil "Resource group $TFSTATE_RG finnes ikke"; fi
if az storage account show -n "$TFSTATE_SA" -g "$TFSTATE_RG" -o none 2>/dev/null; then
  ok "Storage account $TFSTATE_SA"
  if az storage container exists --account-name "$TFSTATE_SA" -n "$TFSTATE_CONTAINER" \
       --auth-mode login --query exists -o tsv 2>/dev/null | grep -q true; then
    ok "Container $TFSTATE_CONTAINER"
  else
    feil "Container $TFSTATE_CONTAINER finnes ikke, eller du mangler Storage Blob Data-rolle"
  fi
else
  feil "Storage account $TFSTATE_SA finnes ikke i $TFSTATE_RG"
fi

info "Key Vault"
KV_ID="$(az keyvault show -n "$KEYVAULT_NAME" --query id -o tsv 2>/dev/null)"
if [[ -n "$KV_ID" ]]; then
  ok "Key Vault $KEYVAULT_NAME"
  # Leser bare navn, ikke verdier – krever likevel en lese-rolle på hvelvet.
  if az keyvault secret list --vault-name "$KEYVAULT_NAME" -o none 2>/dev/null; then
    ok "Du kan liste secrets"
  else
    feil "Du kan ikke liste secrets. Trenger f.eks. Key Vault Secrets Officer på hvelvet"
  fi
else
  feil "Key Vault $KEYVAULT_NAME finnes ikke, eller du har ikke tilgang"
fi

echo
if (( ${FEIL:-0} > 0 )); then echo "$FEIL feil."; exit 1; fi
echo "Alt på plass i Azure."

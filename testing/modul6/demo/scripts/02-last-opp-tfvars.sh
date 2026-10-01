#!/usr/bin/env bash
# =============================================================================
#  scripts/02-last-opp-tfvars.sh  –  tfvars-dev, -test og -prod inn i Key Vault
# -----------------------------------------------------------------------------
#  Laster opp tfvars/<miljø>.tfvars som secret tfvars-<miljø>, for alle tre.
#  Trygt å kjøre flere ganger: hver kjøring lager en ny versjon av secreten.
#
#      ./scripts/02-last-opp-tfvars.sh          # alle tre
#      ./scripts/02-last-opp-tfvars.sh prod     # bare prod
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/config.sh"
krev_az

if (( $# > 0 )); then MILJOER=("$@"); fi

for MILJO in "${MILJOER[@]}"; do
  FIL="$TFVARS_DIR/$MILJO.tfvars"
  info "tfvars-$MILJO  ←  tfvars/$MILJO.tfvars"
  "$SCRIPT_DIR/set-tfvars-secret.sh" "$KEYVAULT_NAME" "tfvars-$MILJO" "$FIL" >/dev/null
  ok "lastet opp"
done

info "Secrets i $KEYVAULT_NAME nå"
az keyvault secret list --vault-name "$KEYVAULT_NAME" \
  --query "[?starts_with(name, 'tfvars-')].{navn:name, oppdatert:attributes.updated}" -o table

#!/usr/bin/env bash
# =============================================================================
#  scripts/04-federated-credential-prod-plan.sh  –  den fjerde credentialen
# -----------------------------------------------------------------------------
#  Legger til federated credential for environmentet prod-plan på
#  App Registration-en, hvis den ikke finnes. Viser alle subject-strengene
#  etterpå.
#
#      ./scripts/04-federated-credential-prod-plan.sh
#
#  Videoen gjør dette i Azure Portal (kapittel 6). Bruk skriptet når du vil
#  hoppe over den biten, eller for å kontrollere subject-strengen etterpå.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/config.sh"
krev_az
krev_gh
krev_client_id

SUBJECT="repo:$GITHUB_REPO:environment:prod-plan"

info "App Registration $AZURE_CLIENT_ID"
if az ad app federated-credential list --id "$AZURE_CLIENT_ID" \
     --query "[].subject" -o tsv | grep -qx "$SUBJECT"; then
  ok "finnes allerede: $SUBJECT"
else
  az ad app federated-credential create --id "$AZURE_CLIENT_ID" --parameters "{
    \"name\": \"github-prod-plan\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"$SUBJECT\",
    \"audiences\": [\"api://AzureADTokenExchange\"],
    \"description\": \"GitHub Actions, environment prod-plan\"
  }" -o none
  ok "opprettet: $SUBJECT"
fi

info "Alle federated credentials"
az ad app federated-credential list --id "$AZURE_CLIENT_ID" \
  --query "[].{navn:name, subject:subject}" -o table

cat <<EOF

Kontroller at alle fire subject-strengene har formen
  repo:$GITHUB_REPO:environment:<dev|test|prod|prod-plan>
uten numeriske ID-er. Ellers kommer AADSTS700213.
EOF

#!/usr/bin/env bash
# =============================================================================
#  scripts/05-sjekk-oppsett.sh  –  er alt klart til å kjøre kjeden?
# -----------------------------------------------------------------------------
#  Endrer ingenting. Går gjennom alt workflowene forutsetter, i Azure og i
#  GitHub, og sier hva som mangler. Kjør før opptak, og igjen når noe feiler.
#
#      ./scripts/05-sjekk-oppsett.sh               # sluttilstanden
#      ./scripts/05-sjekk-oppsett.sh --for-opptak  # prod-plan skal IKKE finnes ennå
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/config.sh"
krev_az
krev_gh
krev_client_id

ALLE_ENVS=("${MILJOER[@]}" prod-plan)
if [[ "${1:-}" == "--for-opptak" ]]; then ALLE_ENVS=("${MILJOER[@]}"); fi

# ----------------------------------------------------------------- Azure -----
info "Key Vault: parameterfilene"
for MILJO in "${MILJOER[@]}"; do
  if az keyvault secret show --vault-name "$KEYVAULT_NAME" -n "tfvars-$MILJO" \
       --query id -o none 2>/dev/null; then
    ok "tfvars-$MILJO"
  else
    feil "tfvars-$MILJO mangler – kjør 02-last-opp-tfvars.sh"
  fi
done

info "App Registration: federated credentials"
SUBJECTS="$(az ad app federated-credential list --id "$AZURE_CLIENT_ID" --query "[].subject" -o tsv 2>/dev/null)"
for ENV in "${ALLE_ENVS[@]}"; do
  S="repo:$GITHUB_REPO:environment:$ENV"
  if grep -qx "$S" <<<"$SUBJECTS"; then ok "$S"; else feil "$S mangler"; fi
done

info "Service principal: rolletildelinger"
SP_ID="${AZURE_SP_OBJECT_ID:-$(az ad sp show --id "$AZURE_CLIENT_ID" --query id -o tsv 2>/dev/null)}"
if [[ -z "$SP_ID" ]]; then
  feil "Fant ingen service principal for $AZURE_CLIENT_ID"
else
  ROLLER="$(az role assignment list --assignee "$SP_ID" --all \
             --query "[].roleDefinitionName" -o tsv 2>/dev/null)"
  for R in "Contributor" "Storage Blob Data Contributor" "Key Vault Secrets User"; do
    if grep -qx "$R" <<<"$ROLLER" || { [[ "$R" == "Contributor" ]] && grep -qx "Owner" <<<"$ROLLER"; }; then
      ok "$R"
    else
      feil "$R mangler (eller ligger på en scope du ikke kan lese)"
    fi
  done
fi

# ---------------------------------------------------------------- GitHub -----
info "GitHub: repository secrets ($GITHUB_REPO)"
REPO_SECRETS="$(gh secret list --repo "$GITHUB_REPO" --json name -q '.[].name')"
for S in AZURE_CLIENT_ID AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID; do
  if grep -qx "$S" <<<"$REPO_SECRETS"; then ok "$S"; else feil "$S mangler – workflowene bruker akkurat dette navnet"; fi
done

info "GitHub: synlighet"
VIS="$(gh repo view "$GITHUB_REPO" --json visibility -q .visibility)"
if [[ "$VIS" == "PUBLIC" ]]; then ok "public"; else feil "repoet er $VIS – branch protection og environment-regler ignoreres på Free"; fi

info "GitHub: environments og KEYVAULT_NAME"
ENVS="$(gh api "repos/$GITHUB_REPO/environments" -q '.environments[].name')"
for ENV in "${ALLE_ENVS[@]}"; do
  if ! grep -qx "$ENV" <<<"$ENVS"; then
    feil "$ENV finnes ikke"
    continue
  fi
  if gh secret list --repo "$GITHUB_REPO" --env "$ENV" --json name -q '.[].name' | grep -qx KEYVAULT_NAME; then
    ok "$ENV, med KEYVAULT_NAME"
  else
    feil "$ENV mangler KEYVAULT_NAME"
  fi
done

info "GitHub: porten på prod (bare informasjon)"
gh api "repos/$GITHUB_REPO/environments/prod" -q '
  "  required reviewers:  " + ([.protection_rules[]? | select(.type=="required_reviewers") | .reviewers[].reviewer.login] | join(", ") | if . == "" then "ingen" else . end),
  "  prevent self-review: " + ([.protection_rules[]? | select(.type=="required_reviewers") | .prevent_self_review | tostring] | first // "–"),
  "  deployment branches: " + (if .deployment_branch_policy == null then "All branches" else "Selected" end)
' 2>/dev/null || echo "  (prod finnes ikke)"

info "GitHub: branch protection på main (bare informasjon)"
if gh api "repos/$GITHUB_REPO/branches/main/protection" --silent 2>/dev/null; then
  gh api "repos/$GITHUB_REPO/branches/main/protection" -q '
    "  required checks:   " + ([.required_status_checks.contexts[]?] | join(", ")),
    "  enforce admins:    " + (.enforce_admins.enabled | tostring) + "   (= Do not allow bypassing)"'
else
  echo "  ingen klassisk branch protection (eller den er satt som ruleset)"
fi

echo
if (( ${FEIL:-0} > 0 )); then echo "$FEIL feil."; exit 1; fi
echo "Alt workflowene trenger, er på plass."

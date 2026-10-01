#!/usr/bin/env bash
# =============================================================================
#  scripts/03-github-environments.sh  –  environments + KEYVAULT_NAME
# -----------------------------------------------------------------------------
#  Sørger for at dev, test og prod finnes i GitHub, og setter KEYVAULT_NAME
#  som ENVIRONMENT secret på hvert av dem.
#
#  Rører ALDRI protection rules: et environment som allerede finnes, blir ikke
#  sendt på nytt til API-et (en PUT uten regler kunne nullstilt dem).
#
#      ./scripts/03-github-environments.sh                 # dev, test, prod
#      ./scripts/03-github-environments.sh --med-prod-plan # + prod-plan
#
#  Videoen oppretter prod-plan PÅ SKJERMEN (kapittel 6). Bruk --med-prod-plan
#  bare når du vil hoppe over den biten, eller etter opptak.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/config.sh"
krev_gh

ENVS=("${MILJOER[@]}")
if [[ "${1:-}" == "--med-prod-plan" ]]; then ENVS+=(prod-plan); fi

info "Repo: $GITHUB_REPO"

for ENV in "${ENVS[@]}"; do
  info "$ENV"
  if gh api "repos/$GITHUB_REPO/environments/$ENV" --silent 2>/dev/null; then
    ok "environment finnes (protection rules urørt)"
  else
    gh api -X PUT "repos/$GITHUB_REPO/environments/$ENV" --silent
    ok "environment opprettet, uten protection rules"
  fi

  gh secret set KEYVAULT_NAME --repo "$GITHUB_REPO" --env "$ENV" --body "$KEYVAULT_NAME"
  ok "KEYVAULT_NAME satt som environment secret"
done

cat <<EOF

Gjenstår for hånd i GitHub (videoen viser det på skjermen):
  • prod: Required reviewers = deg selv, Prevent self-review AV,
          Deployment branches and tags → Selected branches → main
  • main: branch protection (kapittel 3 og 9)
EOF

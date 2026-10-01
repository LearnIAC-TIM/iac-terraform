#!/usr/bin/env bash
# =============================================================================
#  scripts/config.sh  –  felles verdier for alle skriptene
# -----------------------------------------------------------------------------
#  Leses inn (source) av de andre skriptene. Endre verdiene HER, ikke i hvert
#  skript. Kjøres ikke alene.
# =============================================================================

# Backend og Key Vault (fra backend-stacken i modul 4/5)
TFSTATE_RG="rg-tfstate-tim"
TFSTATE_SA="sttfstatetim123"
TFSTATE_CONTAINER="tfstate"
KEYVAULT_NAME="kv-tf-kv-tfstate-tim5m6b"

# Miljøene. prod-plan er ikke med her – den har ingen egen tfvars, den leser
# tfvars-prod. Se 03-github-environments.sh.
MILJOER=(dev test prod)

# GitHub-repoet som <org>/<repo>. Kan overstyres med miljøvariabel.
GITHUB_REPO="${GITHUB_REPO:-LearnIAC-TIM/iac-terraform}"

# App Registration-ens client-ID (= AZURE_CLIENT_ID-secreten i GitHub).
# GitHub lar deg ikke lese secrets tilbake, derfor står den her.
AZURE_CLIENT_ID="${AZURE_CLIENT_ID:-7306c3d1-ed22-4494-8a96-b495d211d6fd}"

# Service principal-ens OBJECT-ID (ikke client-ID). Brukes til å sjekke
# rolletildelingene. Tom = slås opp med az ad sp show.
AZURE_SP_OBJECT_ID="${AZURE_SP_OBJECT_ID:-ee1b75f1-dd0a-4cef-92ec-7b124a2eafed}"

# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TFVARS_DIR="$DEMO_DIR/tfvars"

ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
feil() { printf '  \033[31m✘\033[0m %s\n' "$*"; FEIL=$((${FEIL:-0} + 1)); }
info() { printf '\n\033[1m%s\033[0m\n' "$*"; }

krev_az() {
  command -v az >/dev/null || { echo "Fant ikke az (Azure CLI)." >&2; exit 1; }
  az account show >/dev/null 2>&1 || { echo "Ikke innlogget. Kjør: az login" >&2; exit 1; }
}

krev_gh() {
  command -v gh >/dev/null || { echo "Fant ikke gh (GitHub CLI)." >&2; exit 1; }
  gh auth status >/dev/null 2>&1 || { echo "Ikke innlogget. Kjør: gh auth login" >&2; exit 1; }
  if [[ -z "$GITHUB_REPO" ]]; then
    GITHUB_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
  fi
  [[ -n "$GITHUB_REPO" ]] || {
    echo "Vet ikke hvilket repo. Kjør fra klonen, eller: export GITHUB_REPO=<org>/<repo>" >&2
    exit 1
  }
}

krev_client_id() {
  [[ -n "$AZURE_CLIENT_ID" ]] || {
    echo "AZURE_CLIENT_ID mangler. Kjør: export AZURE_CLIENT_ID=<client-id til App Registration-en>" >&2
    exit 1
  }
}

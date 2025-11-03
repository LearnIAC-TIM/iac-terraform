#!/usr/bin/env bash
set -euo pipefail

# Bruk: ./terraform_fmt_validate.sh <WORKDIR> <BACKEND_HCL_PATH> <STATE_KEY>

WORKDIR_IN="${1:-}"
BACKEND_HCL_IN="${2:-}"
STATE_KEY="${3:-}"

if [[ -z "${WORKDIR_IN}" || -z "${BACKEND_HCL_IN}" || -z "${STATE_KEY}" ]]; then
  echo "Bruk: $0 <WORKDIR> <BACKEND_HCL_PATH> <STATE_KEY>" >&2
  exit 2
fi

# Gjør alle stier absolutte
WORKDIR_ABS="$(cd "${WORKDIR_IN}" 2>/dev/null && pwd -P)" || {
  echo "Fann ikkje WORKDIR: ${WORKDIR_IN}" >&2
  exit 3
}
BACKEND_HCL_ABS="$(cd "$(dirname "${BACKEND_HCL_IN}")" 2>/dev/null && pwd -P)/$(basename "${BACKEND_HCL_IN}")" || {
  echo "Fann ikkje BACKEND_HCL: ${BACKEND_HCL_IN}" >&2
  exit 4
}

echo "=== Terraform fmt/init/validate ==="
echo "Arbeidskatalog: ${WORKDIR_ABS}"
echo "Backend-konfig: ${BACKEND_HCL_ABS}"
echo "State key:      ${STATE_KEY}"
echo

# 1) fmt
echo "[1/3] terraform fmt -check -recursive"
terraform -chdir="${WORKDIR_ABS}" fmt -check -recursive || {
  echo "⚠️  fmt fant filer som ikke er formatert."
}

# 2) init
echo "[2/3] terraform init"
terraform -chdir="${WORKDIR_ABS}" init \
  -backend-config="${BACKEND_HCL_ABS}" \
  -backend-config="key=${STATE_KEY}" \
  -input=false -no-color

# 3) validate
echo "[3/3] terraform validate"
terraform -chdir="${WORKDIR_ABS}" validate -no-color

echo "✅ Terraform validering fullført."

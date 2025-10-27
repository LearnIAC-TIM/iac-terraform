# IaC-testing for Storage Account – Veiviser

## 🎯 Mål

* Flytte **testlogikk** ut i skript som kan kjøres **lokalt og i CI/CD**, mens YAML bare orkestrerer.
* Legge til:

  * **Offline-tester (lint & security)** i CI før plan.
  * **Plan-guardrail** i CI etter plan (f.eks. hindre utilsiktet destroy).
  * **Online-tester (verification + outcomes)** i CD etter apply (i DEV/TEST/PROD).

Dette er rett ut av *Infrastructure Code Testing Implementation* (kap. 18): offline → preview → verification → outcomes, med løskoblet testlogikk.

---

## 📁 Fil- og mappestruktur

Opprett disse (relative til repo-roten):

```
scripts/
  offline/
    lint.sh
    security.sh
    plan_guardrails.sh
  online/
    verify_storage.sh
    outcomes_storage.sh
```

> I workflowene dine brukes `WORKDIR="course materials/module07/buildOnce-deployMany/simple-terraform"`.
> Skriptene forventer at Terraform-filene ligger i `${WORKDIR}/terraform`.

---

## 🧩 Krav til Terraform outputs (enklere skript)

For at online-testene skal være robuste: legg (helst) til følgende i Terraform-koden din (hvis ikke allerede finnes):

```hcl
# i terraform/outputs.tf
output "storage_account_name" {
  value = azurerm_storage_account.this.name
}
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}
```

---

## 🧪 Skriptene

> **Alle skript kjører på Linux runner**, og forventer at `az` og `terraform` er tilgjengelig (slik workflowene dine allerede gjør).
> Bruk `chmod +x` på alle `.sh`-filer.

### 1) `scripts/offline/lint.sh`

Formål: fmt/validate + TFLint. Feiler ved brudd.

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${WORKDIR:?WORKDIR must be set (path to module root)}"
TF_DIR="${WORKDIR}/terraform"

echo "==> Lint: terraform fmt/validate + tflint"
terraform -chdir="${TF_DIR}" fmt -check -recursive
terraform -chdir="${TF_DIR}" init -input=false -no-color >/dev/null
terraform -chdir="${TF_DIR}" validate -no-color

if command -v tflint >/dev/null 2>&1; then
  echo "==> Running TFLint"
  tflint --init
  tflint --chdir "${TF_DIR}"
else
  echo "TFLint not installed; skipping (ok for local runs)."
fi
```

---

### 2) `scripts/offline/security.sh`

Formål: Sikkerhets-/policy-sjekker med Checkov (HTTPS only, TLS >= 1.2, ingen public blob-access, osv.).

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${WORKDIR:?WORKDIR must be set}"
TF_DIR="${WORKDIR}/terraform"

echo "==> Security: Checkov basic policies for Storage Account"

if ! command -v checkov >/dev/null 2>&1; then
  echo "Checkov not installed; attempting pip install (CI has python)."
  pip install --user checkov || true
fi

checkov -d "${TF_DIR}" \
  --quiet \
  --framework terraform
```

> **Tips:** Vil du håndheve bestemte regler, legg til en `.checkov.yaml` i repoet (frivillig).

---

### 3) `scripts/offline/plan_guardrails.sh`

Formål: En enkel “connected” sjekk **etter** `terraform plan`.
Eksempel: **feil PR** dersom planen for `prod` inneholder “will be destroyed”.

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${WORKDIR:?WORKDIR must be set}"
: "${ENVIRONMENT:?ENVIRONMENT must be set to dev|test|prod}"
TF_DIR="${WORKDIR}/terraform"
PLAN_FILE="${TF_DIR}/${ENVIRONMENT}.tfplan"

echo "==> Guardrails for environment: ${ENVIRONMENT}"

# Hvis planfilen ikke finnes, hent fallback (eksisterende workflow lager ofte en plan-output.txt)
if [[ ! -f "${PLAN_FILE}" ]]; then
  echo "No plan file ${PLAN_FILE} found; generating textual plan to /tmp/plan.txt"
  terraform -chdir="${TF_DIR}" show -no-color > /tmp/plan.txt || true
  PLAN_TXT="/tmp/plan.txt"
else
  terraform -chdir="${TF_DIR}" show -no-color "${PLAN_FILE}" > /tmp/plan.txt || true
  PLAN_TXT="/tmp/plan.txt"
fi

# Guardrail eksempel: blokkér destruksjon i prod
if [[ "${ENVIRONMENT}" == "prod" ]]; then
  if grep -q "will be destroyed" "${PLAN_TXT}"; then
    echo "::error ::Guardrail: Plan for PROD contains 'will be destroyed'. Blocked."
    exit 1
  fi
fi

echo "Guardrails passed."
```

---

### 4) `scripts/online/verify_storage.sh`

Formål: **Verification** – sjekke at driftet Storage-konto har riktige egenskaper.

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${WORKDIR:?WORKDIR must be set}"
TF_DIR="${WORKDIR}/terraform"

# Prøv å hente ut navn/rg fra terraform outputs
get_tf_output() {
  local key="$1"
  terraform -chdir="${TF_DIR}" output -raw "${key}" 2>/dev/null || true
}

SA_NAME="$(get_tf_output storage_account_name)"
RG_NAME="$(get_tf_output resource_group_name)"

# Fallback: finn SA i RG ved å lese variabler fra miljøet (valgfritt) eller søke
if [[ -z "${SA_NAME}" || -z "${RG_NAME}" ]]; then
  echo "Terraform outputs not found; trying to detect via Azure CLI..."
  # En enkel heuristikk: finn nyeste storageAccount i subscription med tag iac=terraform
  SA_JSON="$(az resource list --resource-type Microsoft.Storage/storageAccounts --query "[?tags.iac=='terraform'] | [-1]" -o json)"
  SA_NAME="$(echo "${SA_JSON}" | jq -r '.name')"
  RG_NAME="$(echo "${SA_JSON}" | jq -r '.resourceGroup')"
fi

echo "==> Verifying storage account properties"
az storage account show -n "${SA_NAME}" -g "${RG_NAME}" -o jsonc

HTTPS_ONLY=$(az storage account show -n "${SA_NAME}" -g "${RG_NAME}" --query "supportsHttpsTrafficOnly" -o tsv)
TLS_VER=$(az storage account show -n "${SA_NAME}" -g "${RG_NAME}" --query "minimumTlsVersion" -o tsv)
PUBLIC_BLOB=$(az storage account show -n "${SA_NAME}" -g "${RG_NAME}" --query "allowBlobPublicAccess" -o tsv)

[[ "${HTTPS_ONLY}" == "true" ]] || { echo "::error ::https_only not enforced"; exit 1; }
[[ "${TLS_VER}" == "TLS1_2" || "${TLS_VER}" == "TLS1_3" ]] || { echo "::error ::TLS minimum < 1.2"; exit 1; }
[[ "${PUBLIC_BLOB}" == "false" || -z "${PUBLIC_BLOB}" ]] || { echo "::error ::Public blob access is enabled"; exit 1; }

echo "Verification OK: https_only, TLS >= 1.2, no public blob access."
```

---

### 5) `scripts/online/outcomes_storage.sh`

Formål: **Outcomes** – bevis faktisk adferd: opplasting/lesing med autorisasjon fungerer, **anonym** tilgang feiler.

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${WORKDIR:?WORKDIR must be set}"
TF_DIR="${WORKDIR}/terraform"

get_tf_output() {
  local key="$1"
  terraform -chdir="${TF_DIR}" output -raw "${key}" 2>/dev/null || true
}

SA_NAME="$(get_tf_output storage_account_name)"
RG_NAME="$(get_tf_output resource_group_name)"

if [[ -z "${SA_NAME}" || -z "${RG_NAME}" ]]; then
  echo "::error ::Unable to resolve storage account name/resource group from Terraform outputs."
  exit 1
fi

# Hent connection string (krever at SP har rettigheter til list keys)
CONN_STR=$(az storage account show-connection-string -n "${SA_NAME}" -g "${RG_NAME}" -o tsv)

TMP_CONTAINER="ci-$(date +%s)-$RANDOM"
TMP_BLOB="probe.txt"
TMP_FILE="/tmp/${TMP_BLOB}"
echo "hello-from-ci" > "${TMP_FILE}"

echo "==> Creating temp container and uploading a test blob"
az storage container create --name "${TMP_CONTAINER}" --connection-string "${CONN_STR}" 1>/dev/null
az storage blob upload --container-name "${TMP_CONTAINER}" --name "${TMP_BLOB}" --file "${TMP_FILE}" --connection-string "${CONN_STR}" --no-progress 1>/dev/null

echo "==> Downloading blob (authorized)"
az storage blob download --container-name "${TMP_CONTAINER}" --name "${TMP_BLOB}" --file "/tmp/dl_${TMP_BLOB}" --connection-string "${CONN_STR}" --no-progress 1>/dev/null
diff -q "${TMP_FILE}" "/tmp/dl_${TMP_BLOB}"

echo "==> Anonymous access should fail (no public access)"
BLOB_URL="https://${SA_NAME}.blob.core.windows.net/${TMP_CONTAINER}/${TMP_BLOB}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BLOB_URL}")

# Ved privat blob forventer vi IKKE 200
if [[ "${HTTP_CODE}" == "200" ]]; then
  echo "::error ::Anonymous access returned 200 (should be forbidden or not found)."
  exit 1
fi

echo "Outcome OK: authorized read succeeded; anonymous read NOT 200 (=${HTTP_CODE})."

# Rydd opp
az storage blob delete --container-name "${TMP_CONTAINER}" --name "${TMP_BLOB}" --connection-string "${CONN_STR}" 1>/dev/null || true
az storage container delete --name "${TMP_CONTAINER}" --connection-string "${CONN_STR}" 1>/dev/null || true
rm -f "${TMP_FILE}" "/tmp/dl_${TMP_BLOB}" || true
```

---

## 🔧 Slik kobler du skriptene inn i **eksisterende** workflows

> Nedenfor er **minimale** tillegg. Behold alt du har – bare legg inn disse stegene.

### A) CI-workflow (`Terraform CI`)

**Job `validate`** – legg til **etter** “Terraform Validate”:

```yaml
      - name: Offline Lint (fmt/validate + TFLint)
        run: |
          chmod +x scripts/offline/lint.sh
          WORKDIR="${{ env.WORKDIR }}" scripts/offline/lint.sh

      - name: Offline Security (Checkov)
        run: |
          chmod +x scripts/offline/security.sh
          WORKDIR="${{ env.WORKDIR }}" scripts/offline/security.sh
```

**Job `plan-all-environments`** – legg til **etter** “Terraform Plan”-steget:

```yaml
      - name: Plan Guardrails
        if: always() # vi vil se feil selv om plan feilet
        run: |
          chmod +x scripts/offline/plan_guardrails.sh
          WORKDIR="${{ env.WORKDIR }}" \
          ENVIRONMENT="${{ env.ENVIRONMENT }}" \
          scripts/offline/plan_guardrails.sh
```

> Guardrails vil f.eks. blokkere PROD-PRer som (utilsiktet) planlegger destruksjon.

---

### B) CD-workflow (`Terraform CD`)

I **hver** av jobbene `deploy-dev`, `deploy-test`, `deploy-prod`, legg til **etter** “Terraform Apply”:

```yaml
      - name: Online Verification (storage properties)
        run: |
          chmod +x scripts/online/verify_storage.sh
          WORKDIR="${{ env.WORKDIR }}" scripts/online/verify_storage.sh

      - name: Online Outcomes (authorized read ok, anonymous blocked)
        run: |
          chmod +x scripts/online/outcomes_storage.sh
          WORKDIR="${{ env.WORKDIR }}" scripts/online/outcomes_storage.sh
```

---

## 🧪 Lokalt (frivillig)

For lokal kjøring (nyttig under utvikling):

```bash
export WORKDIR="course materials/module07/buildOnce-deployMany/simple-terraform"

# Offline
scripts/offline/lint.sh
scripts/offline/security.sh

# Etter en apply i DEV:
scripts/online/verify_storage.sh
scripts/online/outcomes_storage.sh
```

---



Her er en ferdig **Markdown-guide** (lim den inn som `TOOLS_TFLINT_CHECKOV.md` i repoet). Den forklarer *hva* TFLint og Checkov er, *hvordan* de installeres på GitHub Actions-runnere, og viser **grunnleggende bruk** – både lokalt og i CI.

---

# TFLint & Checkov – Installasjon, bruk og CI-integrasjon

## Hva er disse verktøyene?

### TFLint (Terraform Linter)

* **Formål:** Oppdager feil, anti-patterns og brudd på konvensjoner i Terraform-kode før du kjører plan/apply.
* **Verdien:** Tidlig feedback (raskt og gratis), konsistente standarder på tvers av team.
* **Typer regler:** Generelle regler (ressurstype/attributter), og providerspesifikke regler (Azure, AWS, etc.).

### Checkov (IaC Security & Compliance)

* **Formål:** Sikkerhets-/compliance-scan av IaC (Terraform m.fl.). Oppdager usikre innstillinger og policy-brudd.
* **Verdien:** Hindrer feil som eksponert lagring, manglende kryptering/HTTPS, svak TLS, manglende tags/krav.
* **Typer regler:** Innebygde policies + mulighet for egne regler/policy-profiler.

---

## Installasjon på GitHub Actions-runner

### Alternativ A (anbefalt): Bruk ferdige Actions

**TFLint**

```yaml
- name: Setup TFLint
  uses: terraform-linters/setup-tflint@v4

- name: Run TFLint
  run: |
    tflint --init
    tflint --chdir "course materials/module07/buildOnce-deployMany/simple-terraform/terraform"
```

**Checkov**

```yaml
- name: Install Checkov (pip)
  run: pip install checkov

- name: Run Checkov
  run: |
    checkov -d "course materials/module07/buildOnce-deployMany/simple-terraform/terraform" --quiet
```

> Merk: GitHub Ubuntu-runnere har Python/pip forhåndsinstallert, så `pip install checkov` fungerer rett ut av boksen.

### Alternativ B: Installer verktøy manuelt i et shell-steg

**TFLint (via curl)**

```yaml
- name: Install TFLint (manual)
  run: |
    curl -sSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    tflint --version
```

**Checkov (via pip)**

```yaml
- name: Install Checkov (manual)
  run: |
    python3 -m pip install --upgrade pip
    pip install checkov
    checkov --version
```

---

## Minimal integrasjon i eksisterende CI-workflow

Legg til etter `Terraform Validate` i jobben din:

```yaml
# TFLint
- name: TFLint
  uses: terraform-linters/setup-tflint@v4

- name: Run TFLint
  run: |
    tflint --init
    tflint --chdir "${{ env.WORKDIR }}/terraform"

# Checkov
- name: Install Checkov
  run: pip install checkov

- name: Run Checkov
  run: checkov -d "${{ env.WORKDIR }}/terraform" --quiet
```

Dette vil **feile jobben** (non-zero exit code) hvis det finnes alvorlige funn. Du kan gjøre Checkov mer “snill” ved å legge til `--soft-fail` under innføring, men *ikke* la det stå permanent hvis målet er håndheving.

---

## Grunnleggende bruk (lokalt og i CI)

### TFLint – basis

```bash
# én gang per repo (eller når regler/plugins endres)
tflint --init

# lint i gjeldende mappe
tflint

# lint i en spesifikk mappe (f.eks. terraform-modulen din)
tflint --chdir "course materials/module07/buildOnce-deployMany/simple-terraform/terraform"

# vis resultat som JSON (for videre prosessering)
tflint --format json
```

**Typisk flyt i CI:**

1. `terraform fmt -check -recursive`
2. `terraform init` og `terraform validate`
3. `tflint --init && tflint`

### Checkov – basis

```bash
# skann hele Terraform-mappen
checkov -d "course materials/module07/buildOnce-deployMany/simple-terraform/terraform"

# stillhet (kun feil)
checkov -d ./terraform --quiet

# bare Terraform (utelukk alt annet)
checkov -d ./terraform --framework terraform

# gjør funn til info (ikke break build) – *midlertidig* ved innføring
checkov -d ./terraform --soft-fail
```

**Tips:** Kjør Checkov etter TFLint i CI, så får dere først stil/konvensjoner (TFLint), deretter sikkerhet/policy (Checkov).

---

## Konfigurasjon (frivillig, men anbefales)

### `.tflint.hcl` (i repo-roten)

```hcl
plugin "azurerm" {
  enabled = true
}

config {
  call_module_type = "all"
}

rule "terraform_unused_declarations" {
  enabled = true
}

# Eksempel: skru av en regel (hvis dere har bevisst avvik)
# rule "azurerm_storage_account_invalid_name" {
#   enabled = false
# }
```

**Hvorfor:** Gir dere Azure-providerregler og kontroll på hvilke regler som er aktive.

### `.checkov.yaml` (i repo-roten)

```yaml
framework: terraform
quiet: true
skip-download: false

# Hvit-/svartelist enkelte policyer (ved behov):
# skip-check:
#   - CKV_AZURE_206  # Eksempel – dokumentér hvorfor dere skipper
```

**Hvorfor:** Holder Checkov-innstillinger i repoet, repeterbart for alle miljøer.

---

## Vanlige regler for Storage Account

**TFLint:** navn/konvensjoner, duplikate blokker, ubrukte variabler/outputs, osv.
**Checkov (eksempler):**

* HTTPS only (`supportsHttpsTrafficOnly == true`)
* Minimum TLS `>= 1.2`
* Ingen public blob access (`allowBlobPublicAccess == false`)
* Versioning/Soft delete aktivert (valgfritt, men anbefales i test)
* Tags påkrevde (f.eks. `environment`, `owner`, `cost_center`)

> Disse samsvarer med typiske **offline** og **connected** sjekker i en IaC-pipeline.

---

## Feilnivå og håndheving

* **Innfasingsstrategi:** Start med TFLint som “hard fail” og Checkov som `--soft-fail`. Når teamet er komfortabelt, fjern `--soft-fail` for å håndheve sikkerhet.
* **Pull Request-kommentarer:** Kjør TFLint og Checkov i PR, og post funn i en kommentar for rask feedback (kan enkelt skriptes).

---

## Eksempel: Komplett “offline”-steg (kopier til CI-jobb)

```yaml
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: 1.13.3
    terraform_wrapper: false

- name: Terraform fmt & validate
  working-directory: ${{ env.WORKDIR }}/terraform
  run: |
    terraform fmt -check -recursive
    terraform init -input=false -no-color
    terraform validate -no-color

- name: Setup TFLint
  uses: terraform-linters/setup-tflint@v4

- name: Run TFLint
  run: |
    tflint --init
    tflint --chdir "${{ env.WORKDIR }}/terraform"

- name: Install Checkov
  run: pip install checkov

- name: Run Checkov
  run: checkov -d "${{ env.WORKDIR }}/terraform" --framework terraform --quiet
```

---

## Feilsøking

* **`tflint: command not found`** → Sørg for at `setup-tflint@v4` steget kjører **før** du kaller `tflint`.
* **`checkov: command not found`** → Kjør `pip install checkov` først.
* **TFLint finner ikke regler for Azure** → legg `.tflint.hcl` med `plugin "azurerm" { enabled = true }`, og kjør `tflint --init`.
* **Checkov scanner feil mappe** → sjekk at `-d` peker til *Terraform-koden*, ikke repo-roten (hos dere: `${WORKDIR}/terraform`).
* **For “støyete” funn i Checkov** → start med `--quiet` og ev. `--soft-fail`, eller bruk `.checkov.yaml` for å styre regler – men dokumentér unntak.

---

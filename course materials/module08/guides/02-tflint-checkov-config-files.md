# Kom i gang med TFLint og Checkov

En praktisk guide for å sette opp kodekvalitet og sikkerhetsskanning for Terraform-prosjekter.

## 📚 Innholdsfortegnelse

- [Hva er TFLint og Checkov?](#hva-er-tflint-og-checkov)
- [Forutsetninger](#forutsetninger)
- [Del 1: Sett opp TFLint](#del-1-sett-opp-tflint)
- [Del 2: Sett opp Checkov](#del-2-sett-opp-checkov)
- [Del 3: Test mot din infrastruktur](#del-3-test-mot-din-infrastruktur)
- [Del 4: Legg til flere regler](#del-4-legg-til-flere-regler)
- [Hvor finner jeg mer informasjon?](#hvor-finner-jeg-mer-informasjon)
- [Feilsøking](#feilsøking)

---

## Hva er TFLint og Checkov?

### TFLint
**TFLint** er en linter for Terraform som:
- ✅ Sjekker syntaks og best practices
- ✅ Finner feil i Terraform-koden din
- ✅ Validerer Azure-spesifikke konfigurasjoner
- ✅ Hjelper deg skrive bedre og mer konsistent kode

### Checkov
**Checkov** er et sikkerhetsverktøy som:
- 🔒 Scanner for sikkerhetsproblemer
- 🔒 Sjekker compliance (f.eks. at HTTPS er påkrevd)
- 🔒 Validerer at best practices følges
- 🔒 Finner misconfigurations før deployment

**Analogi:** TFLint er som en grammatikksjekker for koden din, mens Checkov er som en sikkerhetskontroll.

---

## Forutsetninger

Før du starter, må du ha:

✅ **Terraform** installert
```bash
terraform --version
```

✅ **TFLint** installert
```bash
tflint --version
```

✅ **Checkov** installert
```bash
checkov --version
```

✅ **Et Terraform-prosjekt** med minst:
- `main.tf` (eller annen .tf fil)
- En enkel ressurs (f.eks. storage account)

---

## Del 1: Sett opp TFLint

### Steg 1.1: Opprett konfigurasjonsfilen

I samme mappe som dine `.tf`-filer, opprett en ny fil kalt **`.tflint.hcl`**

**Windows PowerShell:**
```powershell
New-Item -Name ".tflint.hcl" -ItemType File
```

**macOS/Linux:**
```bash
touch .tflint.hcl
```

**Eller:** Opprett filen manuelt i VS Code / din favoritt-editor.

### Steg 1.2: Legg til grunnleggende konfigurasjon

Åpne `.tflint.hcl` og lim inn følgende **minimale konfigurasjon**:
```hcl
# .tflint.hcl - Minimal konfigurasjon for å komme i gang
# Se Github repo for å sikre at en får med siste versjon: [TFLint Ruleset for terraform-provider-azurerm](https://github.com/terraform-linters/tflint-ruleset-azurerm)

plugin "azurerm" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
```

**Forklaring av hver linje:**

| Linje | Forklaring |
|-------|------------|
| `plugin "azurerm"` | Vi bruker Azure-plugin for Azure-spesifikke regler |
| `enabled = true` | Aktiverer plugin'en |
| `version = "0.27.0"` | Spesifiserer hvilken versjon av plugin'en vi vil bruke |
| `source = "github..."` | Hvor TFLint skal laste ned plugin'en fra |

### Steg 1.3: Initialiser TFLint

Kjør denne kommandoen for å laste ned Azure-plugin'en:
```bash
tflint --init
```

**Forventet output:**
```
Installing "azurerm" plugin...
Installed "azurerm" (source: github.com/terraform-linters/tflint-ruleset-azurerm, version: 0.27.0)
```

**Hva skjedde?**
- TFLint lastet ned Azure-plugin'en
- Plugin'en ble lagt i mappen `.tflint.d/`
- Du er nå klar til å kjøre TFLint!

### Steg 1.4: Test TFLint

Kjør TFLint på dine Terraform-filer:
```bash
tflint
```

**Første gang:** Du vil sannsynligvis få 0 feil hvis du ikke har lagt til noen regler ennå. Det er helt normalt!
```
0 issue(s) found
```

### Steg 1.5: Legg til din første regel

Oppdater `.tflint.hcl` til å inkludere noen enkle regler:
```hcl
# .tflint.hcl - Med enkle regler

plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Sjekk at variabelnavn følger snake_case (f.eks. storage_name, ikke storageName)
rule "terraform_naming_convention" {
  enabled = true
}

# Sjekk at alle variabler har en beskrivelse
rule "terraform_documented_variables" {
  enabled = true
}

# Sjekk at alle variabler har en type (string, number, etc.)
rule "terraform_typed_variables" {
  enabled = true
}
```

### Steg 1.6: Kjør TFLint igjen
```bash
tflint
```

Nå vil du sannsynligvis se noen advarsler eller feil! **Dette er bra** - TFLint hjelper deg forbedre koden.

**Eksempel på output:**
```
main.tf:5:1: Warning: variable "name" should have a description (terraform_documented_variables)
main.tf:5:1: Warning: variable "name" should have a type (terraform_typed_variables)
```

---

## Del 2: Sett opp Checkov

### Steg 2.1: Opprett konfigurasjonsfilen

I samme mappe som `.tflint.hcl`, opprett en fil kalt **`.checkov.yaml`**

**Windows PowerShell:**
```powershell
New-Item -Name ".checkov.yaml" -ItemType File
```

**macOS/Linux:**
```bash
touch .checkov.yaml
```

### Steg 2.2: Legg til grunnleggende konfigurasjon

Åpne `.checkov.yaml` og lim inn følgende **minimale konfigurasjon**:
```yaml
# .checkov.yaml - Minimal konfigurasjon for å komme i gang

framework:
  - terraform

output: cli

compact: true

quiet: false
```

**Forklaring av hver linje:**

| Linje | Forklaring |
|-------|------------|
| `framework: terraform` | Vi scanner Terraform-filer |
| `output: cli` | Vis resultater i terminalen |
| `compact: true` | Kompakt visning (mindre verbose) |
| `quiet: false` | Vis all informasjon (ikke bare feil) |

### Steg 2.3: Test Checkov

Kjør Checkov på dine Terraform-filer:
```bash
checkov -d .
```

**Forklaring:**
- `-d .` betyr "scan current directory" (alle .tf filer i denne mappen)

**Forventet output:**

Du vil se en liste over sikkerhetssjekker som **passed** (✅) og **failed** (❌).
```
Passed checks: 5, Failed checks: 3, Skipped checks: 0

Check: CKV_AZURE_1: "Ensure storage account allows only HTTPS traffic"
	FAILED for resource: azurerm_storage_account.example
	File: /main.tf:10-20
```

### Steg 2.4: Forstå Checkov-resultater

Checkov gir deg:

1. **Check ID** (f.eks. `CKV_AZURE_1`) - En unik identifikator for regelen
2. **Beskrivelse** - Hva regelen sjekker
3. **Status** - PASSED eller FAILED
4. **Ressurs** - Hvilken ressurs som feiler
5. **Fil og linje** - Hvor i koden feilen er

### Steg 2.5: Fiks en sikkerhetsfeil

La oss si Checkov fant denne feilen:
```
Check: CKV_AZURE_3: "Ensure storage account enables encryption"
	FAILED for resource: azurerm_storage_account.example
```

**Fiks i main.tf:**
```terraform
resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # LEGG TIL DENNE LINJEN:
  enable_https_traffic_only = true  # ✅ Fiks CKV_AZURE_1
  
  # LEGG TIL DENNE LINJEN:
  min_tls_version = "TLS1_2"  # ✅ Best practice
}
```

Kjør Checkov igjen:
```bash
checkov -d .
```

Nå skal du ha færre feil! 🎉

---

## Del 3: Test mot din infrastruktur

### Eksempel: Storage Account med Container

La oss si du har denne infrastrukturen:

**`main.tf`:**
```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "norwayeast"
  
  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "stexample12345"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}
```

**`variables.tf`:**
```terraform
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "norwayeast"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Dev"
}
```

### Kjør begge verktøyene

**1. TFLint:**
```bash
tflint --init
tflint
```

**2. Checkov:**
```bash
checkov -d .
```

### Vanlige problemer Checkov vil finne

| Problem | Regel | Løsning |
|---------|-------|---------|
| HTTPS ikke påkrevd | `CKV_AZURE_3` | Legg til `enable_https_traffic_only = true` |
| Ingen minimum TLS | `CKV_AZURE_44` | Legg til `min_tls_version = "TLS1_2"` |
| Public access åpent | `CKV_AZURE_59` | Legg til `allow_blob_public_access = false` |

**Oppdatert `main.tf` med fikser:**
```terraform
resource "azurerm_storage_account" "example" {
  name                     = "stexample12345"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # ✅ Sikkerhetsforbedringer
  enable_https_traffic_only = true
  min_tls_version          = "TLS1_2"
  allow_blob_public_access = false
  
  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}
```

---

## Del 4: Legg til flere regler

### Utvid TFLint-konfigurasjonen

**`.tflint.hcl` med flere regler:**
```hcl
# .tflint.hcl - Utvidet konfigurasjon

plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# ============================================================
# NAMING CONVENTIONS (Navnekonvensjoner)
# ============================================================

rule "terraform_naming_convention" {
  enabled = true
  
  # Ressurser må bruke snake_case (storage_account, ikke storageAccount)
  resource {
    format = "snake_case"
  }
  
  # Variabler må bruke snake_case
  variable {
    format = "snake_case"
  }
  
  # Outputs må bruke snake_case
  output {
    format = "snake_case"
  }
}

# ============================================================
# DOCUMENTATION (Dokumentasjon)
# ============================================================

# Alle variabler må ha en beskrivelse
rule "terraform_documented_variables" {
  enabled = true
}

# Alle outputs må ha en beskrivelse
rule "terraform_documented_outputs" {
  enabled = true
}

# ============================================================
# TYPE SAFETY (Typesikkerhet)
# ============================================================

# Alle variabler må ha en definert type
rule "terraform_typed_variables" {
  enabled = true
}

# ============================================================
# CODE QUALITY (Kodekvalitet)
# ============================================================

# Finn ubrukt kode (variabler som ikke brukes)
rule "terraform_unused_declarations" {
  enabled = true
}

# ============================================================
# AZURE-SPECIFIC RULES (Azure-spesifikke regler)
# ============================================================

# Sjekk at storage account navn er gyldig
rule "azurerm_storage_account_invalid_name" {
  enabled = true
}

# Sjekk at resource group navn er gyldig
rule "azurerm_resource_group_invalid_name" {
  enabled = true
}
```

### Utvid Checkov-konfigurasjonen

**`.checkov.yaml` med mer kontroll:**
```yaml
# .checkov.yaml - Utvidet konfigurasjon

framework:
  - terraform

output: cli

# Vis kompakt output (mindre verbose)
compact: true

# Vis ikke bare feil, vis også advarsler
quiet: false

# Ikke stopp på første feil
soft-fail: false

# Skip spesifikke sjekker (hvis nødvendig)
# Uncomment linjene under for å skip en sjekk:
# skip-check:
#   - CKV_AZURE_1  # Eksempel: Skip HTTPS-sjekk
#   - CKV_AZURE_2  # Eksempel: Skip en annen sjekk

# Fargekoding i output
no-color: false

# Vis bare feil (skjul passed checks)
# quiet: true  # Uncomment for å bare se feil
```

---

## Hvor finner jeg mer informasjon?

### TFLint

**📚 Alle regler:**
- **Core regler:** https://github.com/terraform-linters/tflint/tree/master/docs/rules
- **Azure regler:** https://github.com/terraform-linters/tflint-ruleset-azurerm/tree/master/docs/rules


**📖 Siste versjon av Azure plugin:**
https://github.com/terraform-linters/tflint-ruleset-azurerm/releases

### Checkov

**📚 Alle Azure-sjekker:**
https://www.checkov.io/5.Policy%20Index/azure.html

**🔍 Søk etter en spesifikk sjekk:**
```bash
checkov --list
```

**📖 Dokumentasjon:**
https://www.checkov.io/

**💡 Forstå en spesifikk feil:**

Hvis du får `CKV_AZURE_1`, søk på Google:
```
checkov CKV_AZURE_1
```

Eller gå til: https://www.checkov.io/5.Policy%20Index/azure.html og søk etter `CKV_AZURE_1`

---

## Opprett et valideringsskript

For å gjøre det enkelt å kjøre begge verktøyene, lag et skript:

**`validate.ps1` (Windows):**
```powershell
#Requires -Version 5.1

Write-Host "🔍 Running Terraform validation..." -ForegroundColor Blue
Write-Host ""

# 1. Terraform Format
Write-Host "📝 Checking Terraform formatting..." -ForegroundColor Cyan
terraform fmt -check -recursive
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Run 'terraform fmt -recursive' to fix formatting" -ForegroundColor Red
}

# 2. Terraform Validate
Write-Host "`n✅ Running terraform validate..." -ForegroundColor Cyan
terraform validate

# 3. TFLint
Write-Host "`n🔎 Running TFLint..." -ForegroundColor Cyan
tflint --init
tflint

# 4. Checkov
Write-Host "`n🛡️  Running Checkov..." -ForegroundColor Cyan
checkov -d . --compact

Write-Host "`n✅ Validation complete!" -ForegroundColor Green
```

**`validate.sh` (macOS/Linux):**
```bash
#!/bin/bash
set -e

echo "🔍 Running Terraform validation..."
echo ""

# 1. Terraform Format
echo "📝 Checking Terraform formatting..."
terraform fmt -check -recursive || {
    echo "❌ Run 'terraform fmt -recursive' to fix formatting"
}

# 2. Terraform Validate
echo ""
echo "✅ Running terraform validate..."
terraform validate

# 3. TFLint
echo ""
echo "🔎 Running TFLint..."
tflint --init
tflint

# 4. Checkov
echo ""
echo "🛡️  Running Checkov..."
checkov -d . --compact

echo ""
echo "✅ Validation complete!"
```

**Kjør skriptet:**

Windows:
```powershell
.\validate.ps1
```

macOS/Linux:
```bash
chmod +x validate.sh
./validate.sh
```

---

## Feilsøking

### Problem: "Plugin not found"

**Løsning:**
```bash
# Slett plugin-cache
rm -rf .tflint.d/

# Reinitialiser
tflint --init
```

### Problem: TFLint finner ingen feil

**Mulige årsaker:**
1. Du har ikke aktivert noen regler i `.tflint.hcl`
2. Koden din er perfekt! 🎉
3. TFLint ikke initialisert

**Løsning:**
```bash
# Sjekk at plugins er lastet
tflint --version

# Reinitialiser
tflint --init

# Kjør med verbose output
tflint --loglevel=debug
```

### Problem: Checkov tar lang tid

**Løsning:**
```bash
# Scan bare Terraform-filer (ikke andre IaC)
checkov -d . --framework terraform

# Skip eksterne modules
checkov -d . --skip-framework kubernetes
```

### Problem: For mange feil i Checkov

**Løsning:**

Du kan midlertidig skippe sjekker mens du fikser en om gangen:
```yaml
# .checkov.yaml
skip-check:
  - CKV_AZURE_1
  - CKV_AZURE_2
```

Eller kjør med soft-fail:
```bash
checkov -d . --soft-fail
```

---

## 📋 Quick Reference

### Daglige kommandoer
```bash
# Kjør alle valideringer
terraform fmt -recursive
terraform validate
tflint --init
tflint
checkov -d .

# Eller bruk valideringsskriptet
./validate.sh  # macOS/Linux
.\validate.ps1  # Windows
```

### Fil-oversikt
```
ditt-prosjekt/
├── .tflint.hcl          # TFLint konfigurasjon
├── .checkov.yaml        # Checkov konfigurasjon
├── .tflint.d/           # TFLint plugins (auto-generert)
├── main.tf              # Dine Terraform-filer
├── variables.tf
└── outputs.tf
```

### Nyttige lenker

| Verktøy | Dokumentasjon |
|---------|---------------|
| **TFLint** | https://github.com/terraform-linters/tflint |
| **TFLint Azure Rules** | https://github.com/terraform-linters/tflint-ruleset-azurerm/tree/master/docs/rules |
| **Checkov** | https://www.checkov.io/ |
| **Checkov Azure Checks** | https://www.checkov.io/5.Policy%20Index/azure.html |

---

## 🎯 Oppsummering

1. **Opprett `.tflint.hcl`** med minimal konfigurasjon
2. **Kjør `tflint --init`** for å laste ned plugins
3. **Opprett `.checkov.yaml`** med minimal konfigurasjon
4. **Kjør `tflint` og `checkov -d .`** for å validere koden
5. **Fiks feilene** én om gangen
6. **Utvid med flere regler** etter hvert som dere blir komfortable

**Lykke til!** 🚀
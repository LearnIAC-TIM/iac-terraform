# Installasjonsveiledning - TFLint og Checkov

Denne guiden viser hvordan du installerer TFLint og Checkov på Windows og macOS.

## 📋 Innholdsfortegnelse

- [TFLint](#tflint)
  - [Windows](#tflint-windows)
  - [macOS](#tflint-macos)
- [Checkov](#checkov)
  - [Windows](#checkov-windows)
  - [macOS](#checkov-macos)
- [Verifisering](#verifisering)
- [Oppsett og Konfigurasjon](#oppsett-og-konfigurasjon)

---

## TFLint

TFLint er en linter for Terraform som finner mulige feil, best practices og sikkerhetsproblemer i Terraform-kode.

### TFLint - Windows

#### Metode 1: Chocolatey (Anbefalt)

**Installer Chocolatey først (hvis ikke allerede installert):**

1. Åpne PowerShell som Administrator
2. Kjør:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```
NOTE: The Chocolatey package is NOT directly maintained by the TFLint maintainers. The latest version is always available by manual installation.
**Installer TFLint:**
```powershell
choco install tflint
```

#### Metode 2: Scoop

**Installer Scoop først (hvis ikke allerede installert):**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

**Installer TFLint:**
```powershell
scoop install tflint
```

#### Metode 3: Manuell installasjon

1. Last ned siste versjon fra [TFLint releases](https://github.com/terraform-linters/tflint/releases)
2. Velg `tflint_windows_amd64.zip`
3. Pakk ut `tflint.exe`
4. Legg til i PATH eller flytt til en mappe som er i PATH (f.eks. `C:\Windows\System32`)

### TFLint - macOS

#### Metode 1: Homebrew (Anbefalt)

**Installer Homebrew først (hvis ikke allerede installert):**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Installer TFLint:**
```bash
brew install tflint
```

#### Metode 2: Manuell installasjon
```bash
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
```

---

## Checkov

Checkov er et statisk kodeanalyseverktøy for Infrastructure as Code (IaC) som scanner for sikkerhet og compliance-problemer.

### Checkov - Windows

#### Forutsetninger: Python

Checkov krever Python 3.8 eller nyere.

**Installer Python:**

1. **Via Microsoft Store (Enklest):**
   - Åpne Microsoft Store
   - Søk etter "Python 3.12" (eller nyeste versjon)
   - Klikk "Installer"

2. **Via Chocolatey:**
```powershell
choco install python
```

3. **Manuelt:**
   - Last ned fra [python.org](https://www.python.org/downloads/)
   - Husk å krysse av "Add Python to PATH" under installasjonen

**Verifiser Python-installasjon:**
```powershell
python --version
pip --version
```

#### Installer Checkov
```powershell
pip install checkov
```

**Alternativ: Installer med pipx (isolert miljø):**
```powershell
# Installer pipx først
pip install pipx
pipx ensurepath

# Installer checkov
pipx install checkov
```

### Checkov - macOS

#### Metode 1: Homebrew (Enklest)
```bash
brew install checkov
```

#### Metode 2: pip (Python)

**Sjekk om Python er installert:**
```bash
python3 --version
pip3 --version
```

**Hvis Python ikke er installert:**
```bash
brew install python3
```

**Installer Checkov:**
```bash
pip3 install checkov
```

**Alternativ: Installer med pipx (isolert miljø):**
```bash
# Installer pipx først
brew install pipx
pipx ensurepath

# Installer checkov
pipx install checkov
```

---

## Verifisering

Etter installasjon, verifiser at alt fungerer:

### TFLint
```bash
# Sjekk versjon
tflint --version

# Kjør i en Terraform-mappe
tflint --init
tflint
```

### Checkov
```bash
# Sjekk versjon
checkov --version

# Test på en Terraform-fil
checkov -f main.tf

# Scan hele mappen
checkov -d .
```

---

## Oppsett og Konfigurasjon

### TFLint Konfigurasjon

Opprett `.tflint.hcl` i prosjektmappen:
```hcl
plugin "azurerm" {
  enabled = true
  version = "0.25.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}
```

**Initialiser plugins:**
```bash
tflint --init
```

### Checkov Konfigurasjon

Opprett `.checkov.yaml` i prosjektmappen (valgfritt):
```yaml
framework:
  - terraform

output: cli

soft-fail: false

skip-check:
  # Eksempel: Skip spesifikke sjekker hvis nødvendig
  # - CKV_AZURE_1

compact: true

quiet: false
```

### Integrere i Git Hooks (Pre-commit)

**Installer pre-commit:**

Windows:
```powershell
pip install pre-commit
```

macOS:
```bash
brew install pre-commit
# eller
pip3 install pre-commit
```

**Opprett `.pre-commit-config.yaml`:**
```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.86.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_checkov
```

**Aktiver pre-commit:**
```bash
pre-commit install
```

---

## Nyttige Kommandoer

### TFLint
```bash
# Scan med detaljert output
tflint --format=compact

# Scan bestemt fil
tflint main.tf

# Ignore spesifikke regler
tflint --disable-rule=terraform_unused_declarations
```

### Checkov
```bash
# Scan med spesifikt framework
checkov -d . --framework terraform

# Output til JSON
checkov -d . -o json

# Skip spesifikke sjekker
checkov -d . --skip-check CKV_AZURE_1,CKV_AZURE_2

# Vis kun feil (ikke advarsler)
checkov -d . --compact --quiet
```

---

## Feilsøking

### Windows - Python ikke funnet

Hvis `python` kommando ikke fungerer etter installasjon:
1. Sjekk at Python er i PATH
2. Prøv å bruke `py` i stedet for `python`
3. Start terminalen på nytt

### macOS - Permission denied

Hvis du får tilgangsproblemer:
```bash
sudo pip3 install checkov
# eller
pip3 install --user checkov
```

### TFLint - Plugin feil

Hvis plugins ikke lastes:
```bash
# Slett plugin-cache og reinstaller
rm -rf .tflint.d/
tflint --init
```

---

## Ressurser

- **TFLint:** [https://github.com/terraform-linters/tflint](https://github.com/terraform-linters/tflint)
- **Checkov:** [https://www.checkov.io/](https://www.checkov.io/)
- **TFLint Azure Ruleset:** [https://github.com/terraform-linters/tflint-ruleset-azurerm](https://github.com/terraform-linters/tflint-ruleset-azurerm)
- **Checkov Azure Policies:** [https://www.checkov.io/5.Policy%20Index/azure.html](https://www.checkov.io/5.Policy%20Index/azure.html)
# Terraform Azure Authentication og Multi-Environment Deployment

## 📋 Innholdsfortegnelse
- [Environment Variables](#environment-variables)
- [Azure Authentication Variables](#azure-authentication-variables)
- [Terraform Kommandoer](#terraform-kommandoer)
- [Ressurser](#ressurser)

---

## Environment Variables

### Hva er Environment Variables?

Environment variables (miljøvariabler) er nøkkel-verdi par som operativsystemet og applikasjoner kan bruke for å hente konfigurasjonsinformasjon. De eksisterer kun i den aktive shell-sesjonen (terminal/kommandolinje) med mindre de lagres permanent i system- eller brukerprofiler.

### Hvordan fungerer de?
```
┌─────────────────────────────────────┐
│  Din Terminal/Shell Session         │
│                                     │
│  Environment Variables:             │
│  ├─ ARM_CLIENT_ID = "abc123..."     │
│  ├─ ARM_TENANT_ID = "def456..."     │
│  └─ ARM_SUBSCRIPTION_ID = "ghi789"  │
│                                     │
│  Når Terraform kjører:              │
│  └─> Leser automatisk disse         │
│      variablene for autentisering   │
└─────────────────────────────────────┘
```

### Fordeler med Environment Variables

✅ **Sikkerhet**: Sensitive verdier (som secrets) lagres ikke i kode  
✅ **Fleksibilitet**: Enkelt å bytte konfigurasjon uten å endre kode  
✅ **Miljøspesifikk**: Ulike verdier for dev/test/prod  
✅ **CI/CD-vennlig**: GitHub Actions og andre kan sette disse automatisk

---

## Azure Authentication Variables

### ARM_CLIENT_ID

**Hva**: Application (Client) ID for din Azure App Registration/Service Principal

**Hvor finner jeg den?**
1. Azure Portal → App Registrations
2. Velg din app
3. Kopier "Application (client) ID" fra Overview
```bash
# Bash/Linux/macOS
export ARM_CLIENT_ID="12345678-1234-1234-1234-123456789abc"

# PowerShell
$env:ARM_CLIENT_ID = "12345678-1234-1234-1234-123456789abc"
```

### ARM_TENANT_ID

**Hva**: Azure Active Directory (Entra ID) Tenant ID for din organisasjon

**Verdi i dette kurset**: `6980af2f-acfc-4513-ac50-552bcfdb01a0`
```bash
# Bash/Linux/macOS
export ARM_TENANT_ID="6980af2f-acfc-4513-ac50-552bcfdb01a0"

# PowerShell
$env:ARM_TENANT_ID = "6980af2f-acfc-4513-ac50-552bcfdb01a0"
```

### ARM_SUBSCRIPTION_ID

**Hva**: Azure Subscription ID hvor ressursene skal deployes

**Verdi i dette kurset**: `7a3c6854-0fe1-42eb-b5b9-800af1e53d70`
```bash
# Bash/Linux/macOS
export ARM_SUBSCRIPTION_ID="7a3c6854-0fe1-42eb-b5b9-800af1e53d70"

# PowerShell
$env:ARM_SUBSCRIPTION_ID = "7a3c6854-0fe1-42eb-b5b9-800af1e53d70"
```

### Sette alle variabler på en gang

**Bash/Linux/macOS**:
```bash
export ARM_CLIENT_ID="SKRIV INN DIN EGEN APP ID"
export ARM_SUBSCRIPTION_ID="7a3c6854-0fe1-42eb-b5b9-800af1e53d70"
export ARM_TENANT_ID="6980af2f-acfc-4513-ac50-552bcfdb01a0"
```

**PowerShell**:
```powershell
$env:ARM_CLIENT_ID = "SKRIV INN DIN EGEN APP ID"
$env:ARM_SUBSCRIPTION_ID = "7a3c6854-0fe1-42eb-b5b9-800af1e53d70"
$env:ARM_TENANT_ID = "6980af2f-acfc-4513-ac50-552bcfdb01a0"
```

> **💡 Tips**: Du kan verifisere at variablene er satt korrekt:
> - Bash: `echo $ARM_CLIENT_ID`
> - PowerShell: `echo $env:ARM_CLIENT_ID`

---

## Terraform Kommandoer

### Forutsetninger

Før du kjører Terraform-kommandoene:
1. ✅ Environment variables er satt (se over)
2. ✅ Du står i `environments/[miljø]` mappen (dev/test/prod)
3. ✅ Azure CLI er innlogget: `az login`

### Kommandostruktur
```
terraform -chdir=../../terraform [command] [options]
```

**Forklaring**:
- `-chdir=../../terraform`: Går to nivåer opp og inn i `terraform` mappen
- Fra `environments/dev/` → Opp til `iac-fasttrack-DEMO/` → Inn i `terraform/`

---

## DEV Environment

### 1. Initialize (Init)
```bash
terraform -chdir=../../terraform init -backend-config="../environments/dev/backend-dev.hcl"
```

**Hva gjør den?**
- Initialiserer Terraform working directory
- Laster ned nødvendige providers (Azure)
- Konfigurerer remote state backend (Azure Storage Account)

**Backend config**: Peker til `backend-dev.hcl` som inneholder:
- Resource group for state
- Storage account for state
- Container navn
- State file key

### 2. Plan
```bash
terraform -chdir=../../terraform plan -var-file="../environments/dev/dev.tfvars"
```

**Hva gjør den?**
- Sammenligner ønsket state (kode) med faktisk state (Azure)
- Viser hva som vil bli opprettet, endret eller slettet
- Oppretter IKKE ressurser (trygg operasjon)

**Var-file**: Bruker miljøspesifikke variabler fra `dev.tfvars`:
- Resource group navn
- Storage account navn
- Location
- Environment tag

### 3. Apply
```bash
terraform -chdir=../../terraform apply -var-file="../environments/dev/dev.tfvars" -auto-approve
```

**Hva gjør den?**
- Gjennomfører endringene som ble vist i plan
- Oppretter/endrer/sletter ressurser i Azure
- Oppdaterer state file

**Flagg**:
- `-auto-approve`: Hopper over manuell bekreftelse (bruk med forsiktighet!)

> **⚠️ Obs**: Uten `-auto-approve` må du skrive "yes" for å bekrefte

---

## TEST Environment

### Initialize med -reconfigure
```bash
terraform -chdir=../../terraform init -backend-config="../environments/test/backend-test.hcl" -reconfigure
```

**Hvorfor `-reconfigure`?**
- Terraform husker forrige backend-konfigurasjon (dev)
- `-reconfigure` forteller Terraform å ignorere cached backend settings
- Nødvendig når du bytter mellom miljøer med ulik backend

### Plan og Apply
```bash
terraform -chdir=../../terraform plan -var-file="../environments/test/test.tfvars"
terraform -chdir=../../terraform apply -var-file="../environments/test/test.tfvars" -auto-approve
```

Samme prosess som DEV, men med test-spesifikke variabler.

---

## PROD Environment

### Initialize med -reconfigure
```bash
terraform -chdir=../../terraform init -backend-config="../environments/prod/backend-prod.hcl" -reconfigure
```

### Plan og Apply
```bash
terraform -chdir=../../terraform plan -var-file="../environments/prod/prod.tfvars"
terraform -chdir=../../terraform apply -var-file="../environments/prod/prod.tfvars" -auto-approve
```

> **🚨 Produksjon**: Vær EKSTRA forsiktig i prod! Vurder å kjøre uten `-auto-approve` først.

---

## Terraform Workflow - Best Practices
```
┌─────────────────────────────────────────────┐
│ 1. SET ENVIRONMENT VARIABLES                │
│    export ARM_CLIENT_ID="..."               │
│    export ARM_SUBSCRIPTION_ID="..."         │
│    export ARM_TENANT_ID="..."               │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│ 2. NAVIGATE TO ENVIRONMENT FOLDER           │
│    cd environments/dev                      │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│ 3. INITIALIZE                               │
│    terraform init -backend-config=...       │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│ 4. PLAN (review changes)                    │
│    terraform plan -var-file=...             │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│ 5. APPLY (create resources)                 │
│    terraform apply -var-file=...            │
└─────────────────────────────────────────────┘
```

---

## Typiske Feilmeldinger og Løsninger

### ❌ "Error: Backend initialization required"

**Problem**: Ikke kjørt `terraform init` eller brukt feil backend config

**Løsning**:
```bash
terraform -chdir=../../terraform init -backend-config="../environments/dev/backend-dev.hcl" -reconfigure
```

### ❌ "Error: building account: getting authenticated object ID: parsing json result from Azure CLI"

**Problem**: Environment variables er ikke satt eller Azure CLI ikke innlogget

**Løsning**:
1. Sjekk at ARM_* variablene er satt: `echo $ARM_CLIENT_ID`
2. Logg inn på Azure: `az login`

### ❌ "Error: file '../environments/dev/backend-dev.hcl' could not be read"

**Problem**: Feil working directory eller feil sti

**Løsning**: Sørg for at du står i riktig mappe (`environments/dev/`)

---

## Ressurser

### Offisiell Dokumentasjon

**Terraform Environment Variables**:
- [Terraform Environment Variables](https://developer.hashicorp.com/terraform/cli/config/environment-variables)
- [Terraform Azure Provider Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)

**Azure Provider**:
- [AzureRM Provider - Environment Variables](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#argument-reference)
- Liste over alle `ARM_*` variabler som kan brukes

**Terraform Commands**:
- [terraform init](https://developer.hashicorp.com/terraform/cli/commands/init)
- [terraform plan](https://developer.hashicorp.com/terraform/cli/commands/plan)
- [terraform apply](https://developer.hashicorp.com/terraform/cli/commands/apply)

### Azure Dokumentasjon

**Service Principal Authentication**:
- [Azure Service Principals](https://learn.microsoft.com/en-us/cli/azure/azure-cli-sp-tutorial-1)
- [Create Azure Service Principal](https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)

**Azure CLI**:
- [Azure CLI Environment Variables](https://learn.microsoft.com/en-us/cli/azure/use-cli-effectively#environment-variables)

### Shell/OS Dokumentasjon

**Bash Environment Variables**:
- [GNU Bash Manual - Environment](https://www.gnu.org/software/bash/manual/html_node/Environment.html)

**PowerShell Environment Variables**:
- [PowerShell Environment Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables)

---

## Sikkerhetstips 🔒

1. **ALDRI commit credentials til Git**
   - Bruk `.gitignore` for `.tfvars` filer med sensitive data
   - Bruk environment variables i stedet for hardkodede verdier

2. **Bruk ulike Service Principals per miljø**
   - DEV SP har kun tilgang til dev-ressurser
   - PROD SP har kun tilgang til prod-ressurser

3. **Bruk Azure Key Vault** for production secrets

---

## Oppsummering

Environment variables er en trygg og fleksibel måte å håndtere konfigurasjon på:

| Variabel | Formål | Hvor finner jeg den? |
|----------|--------|---------------------|
| `ARM_CLIENT_ID` | App Registration ID | Azure Portal → App Registrations |
| `ARM_TENANT_ID` | Azure AD Tenant | Azure Portal → Tenant Properties |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription | Azure Portal → Subscriptions |

Terraform-kommandoer følger alltid samme mønster:
1. **init** - Klargjør Terraform
2. **plan** - Forhåndsvis endringer
3. **apply** - Gjennomfør endringer

**Nøkkelen til suksess**: Alltid kjør `plan` før `apply`! 🎯
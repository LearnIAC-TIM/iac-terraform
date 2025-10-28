# Terraform Azure Infrastructure - Kursmateriale

Komplett Terraform-kurs for Azure Infrastructure as Code (IaC). Dette repositoriet inneholder eksempler, scripts og workflows for å lære Terraform best practices.

## 📚 Innhold

- **Progressive prosjekter** fra grunnleggende til avansert
- **Testing på alle nivåer** (static, unit, integration, drift detection)
- **CI/CD workflows** med GitHub Actions
- **Best practices** for produksjonsklare miljøer
- **Automatiserte scripts** for oppsett og validering

## 🗂️ Mappestruktur

```
terraform-azure-course/
├── shared/                          # Delt konfigurasjon
│   ├── backend.hcl.example         # Template for backend config
│   └── common-variables.tf         # Delte variabler
├── projects/                        # Kursprosjekter
│   ├── 01-basic-infrastructure/    # Grunnleggende infrastruktur
│   ├── 02-with-modules/            # Med moduler (opprett selv)
│   └── 03-testing-example/         # Testing eksempel (opprett selv)
├── scripts/                         # Hjelpescripts
│   ├── init-project.sh             # Opprett nytt prosjekt
│   ├── validate-all.sh             # Valider alle prosjekter
│   └── setup-github-secrets.sh     # Setup GitHub secrets
├── .github/workflows/               # CI/CD workflows
│   ├── terraform-validate.yml      # Validering
│   └── terraform-test.yml          # Testing og deployment
├── .gitignore                       # Git ignore regler
├── .tflint.hcl                     # TFLint konfigurasjon
└── README.md                        # Denne filen
```

## 🚀 Kom i gang

### Forutsetninger

Installer følgende verktøy:

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Git](https://git-scm.com/downloads)
- [TFLint](https://github.com/terraform-linters/tflint) (valgfri, anbefalt)
- [GitHub CLI](https://cli.github.com/) (valgfri, for secrets setup)

### Azure Setup

Du trenger tilgang til:
- ✅ Azure subscription
- ✅ Resource Group for Terraform state
- ✅ Storage Account med container for state files
- ✅ Key Vault (valgfri)
- ✅ App Registration med:
  - Service Principal
  - Federated credentials for GitHub Actions

### Steg 1: Klon repository

```bash
git clone <ditt-repo-url>
cd terraform-azure-course
```

### Steg 2: Konfigurer backend

```bash
# Kopier template
cp shared/backend.hcl.example shared/backend.hcl

# Rediger med dine verdier
nano shared/backend.hcl
```

Fyll inn dine Azure ressurser:
```hcl
resource_group_name  = "rg-<ditt-studentnummer>-tfstate"
storage_account_name = "st<studentnr>tfstate"
container_name       = "tfstate"
key                  = "PROJECT_NAME/terraform.tfstate"
use_oidc             = true
```

### Steg 3: Logg inn på Azure

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

### Steg 4: Start med første prosjekt

```bash
cd projects/01-basic-infrastructure

# Kopier terraform.tfvars
cp terraform.tfvars.example terraform.tfvars

# Rediger med dine verdier
nano terraform.tfvars

# Initialiser Terraform
terraform init -backend-config=../../shared/backend.hcl \
  -backend-config="key=01-basic-infrastructure/terraform.tfstate"

# Valider
terraform validate

# Plan
terraform plan

# Apply
terraform apply
```

## 📖 Prosjekter

### 01-basic-infrastructure ✅

**Nivå**: Nybegynner  
**Innhold**: Resource Group, Storage Account, Storage Container  
**Læringsmål**: 
- Terraform grunnleggende
- Azure Provider
- Remote backend
- Output values

**Start her**: `cd projects/01-basic-infrastructure`

### 02-with-modules (Opprett selv)

**Nivå**: Intermediate  
**Innhold**: Modulbasert struktur  
**Læringsmål**:
- Terraform moduler
- Gjenbrukbarhet
- Modul-testing

**Opprett**: `./scripts/init-project.sh 02-with-modules "Infrastructure with modules"`

### 03-testing-example (Opprett selv)

**Nivå**: Avansert  
**Innhold**: Omfattende testing  
**Læringsmål**:
- Unit testing
- Integration testing
- Drift detection

**Opprett**: `./scripts/init-project.sh 03-testing-example "Testing examples"`

## 🧪 Testing

### Alle test-nivåer

```bash
# 1. Format
terraform fmt -check -recursive

# 2. Validate
terraform validate

# 3. Lint
tflint --init
tflint

# 4. Plan
terraform plan

# 5. Integration tests (etter apply)
./test/integration_test.sh

# 6. Drift detection
./test/drift_detection.sh
```

### Valider alle prosjekter

```bash
./scripts/validate-all.sh
```

## 🔧 Nyttige scripts

### Opprett nytt prosjekt

```bash
./scripts/init-project.sh <navn> [beskrivelse]

# Eksempel
./scripts/init-project.sh 04-advanced "Advanced infrastructure patterns"
```

### Setup GitHub Secrets

```bash
./scripts/setup-github-secrets.sh
```

Følg instruksjonene for å sette opp secrets for CI/CD.

## 🔄 CI/CD med GitHub Actions

### Workflows

#### 1. Terraform Validation (Automatisk)
Kjører på push og pull requests:
- Format check
- Syntax validation
- TFLint

#### 2. Terraform Test & Deploy (Manuell)
Kjør via GitHub Actions UI:
- Velg prosjekt
- Velg action (plan/apply/destroy)
- Velg environment

### Setup GitHub Actions

1. Fork/klon dette repositoriet til GitHub
2. Kjør `./scripts/setup-github-secrets.sh`
3. Følg instruksjonene for å sette secrets
4. Push kode til GitHub
5. GitHub Actions vil automatisk validere på push

## 📊 Testing Nivåer - Oversikt

| Nivå | Type | Verktøy | Når |
|------|------|---------|-----|
| 1 | **Static** | `terraform fmt` | Før commit |
| 2 | **Syntax** | `terraform validate` | Før commit |
| 3 | **Linting** | `tflint` | Før commit |
| 4 | **Plan** | `terraform plan` | Før apply |
| 5 | **Unit** | Terratest | På moduler |
| 6 | **Integration** | Bash/Python | Etter apply |
| 7 | **System** | End-to-end | Pre-prod |
| 8 | **Drift** | `terraform plan` | Daglig/ukentlig |

## 🎯 Best Practices

### ✅ DO

- ✅ Bruk remote backend for state
- ✅ Versjonskontroll for all kode
- ✅ Valider før hver apply
- ✅ Bruk moduler for gjenbruk
- ✅ Dokumenter variabler og outputs
- ✅ Bruk tags konsekvent
- ✅ Test i dev først
- ✅ Kjør drift detection regelmessig
- ✅ Bruk naming conventions
- ✅ Enable security features

### ❌ DON'T

- ❌ Commit `terraform.tfvars` til Git
- ❌ Commit `backend.hcl` til Git
- ❌ Gjør manuelle endringer i Azure Portal
- ❌ Del state files mellom studenter
- ❌ Skip `terraform plan`
- ❌ Hardcode sensitive verdier
- ❌ Ignorer validation errors
- ❌ Deploy til prod uten testing
- ❌ Bruk default naming
- ❌ Disable security features

## 🔒 Sikkerhet

### State Management

- State files inneholder sensitive data
- Bruk encrypted backend (Azure Storage)
- Begrens tilgang til state
- Aldri commit state til Git

### Credentials

- Bruk federated credentials (OIDC)
- Ikke hardcode secrets
- Bruk Key Vault for secrets
- Roter credentials regelmessig

### Tagging

Alle ressurser skal ha disse tags:
```hcl
tags = {
  ManagedBy   = "Terraform"
  Environment = "dev|test|prod"
  Course      = "IaC-2025"
}
```

## 📝 Naming Conventions

### Ressurser

| Type | Pattern | Eksempel |
|------|---------|----------|
| Resource Group | `rg-<student>-<env>` | `rg-student01-dev` |
| Storage Account | `st<student><env>` | `ststudent01dev` |
| Key Vault | `kv-<student>-<env>` | `kv-student01-dev` |
| Virtual Network | `vnet-<student>-<env>` | `vnet-student01-dev` |

### Terraform filer

- `main.tf` - Hovedressurser
- `variables.tf` - Input variabler
- `outputs.tf` - Output verdier
- `provider.tf` - Provider konfigurasjon
- `terraform.tfvars` - Verdier (ikke i Git)
- `backend.tf` - Backend konfigurasjon (valgfri)

## 🐛 Troubleshooting

### Problem: Backend init feiler

```bash
# Sjekk backend konfigurasjon
cat shared/backend.hcl

# Verifiser storage account
az storage account show --name <STORAGE_ACCOUNT_NAME>

# Sjekk container
az storage container show --name tfstate --account-name <STORAGE_ACCOUNT_NAME>
```

### Problem: Authentication feiler

```bash
# Re-login
az login

# Sjekk subscription
az account show

# Sett riktig subscription
az account set --subscription <SUBSCRIPTION_ID>
```

### Problem: State lock

```bash
# Se locks
az storage blob lease list \
  --container-name tfstate \
  --account-name <STORAGE_ACCOUNT_NAME>

# Break lock (forsiktig!)
terraform force-unlock <LOCK_ID>
```

### Problem: Naming conflicts

Storage account navn må være globalt unike:
```bash
# Legg til unikt suffix
student_name = "student01xyz"
```

## 📚 Ressurser

### Offisiell dokumentasjon

- [Terraform Docs](https://www.terraform.io/docs)
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)

### Best Practices

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)

### Testing

- [Terratest](https://terratest.gruntwork.io/)
- [TFLint](https://github.com/terraform-linters/tflint)
- [Checkov](https://www.checkov.io/)

## 🤝 Support

For spørsmål eller problemer:

1. Sjekk README i relevant prosjekt-mappe
2. Les troubleshooting-seksjonen
3. Søk i Issues (hvis GitHub)
4. Kontakt kursleder

## 📄 Lisens

Dette kursmaterialet er laget for undervisningsformål.

---

**Lykke til med Terraform! 🚀**

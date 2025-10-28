
# 🎓 Terraform Azure Infrastructure - Komplett Setup Guide

## 📁 Mappestruktur

```
terraform-azure-course/
├── shared/
│   ├── backend.hcl              # Backend config (brukes av alle dine prosjekter)
│   ├── backend.hcl.example      # Template
│   └── common-variables.tf      # (Optional) Delte variabler
├── projects/
│   ├── 01-basic-infrastructure/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   └── terraform.tfvars.example
│   ├── 02-with-modules/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── modules/
│   │       ├── resource-group/
│   │       └── storage-account/
│   └── 03-testing-example/
│       ├── main.tf
│       ├── test/
│       └── ...
├── scripts/
│   ├── init-project.sh          # Initialiser nytt prosjekt
│   ├── validate-all.sh          # Valider alle prosjekter
│   └── setup-github-secrets.sh  # Setup GitHub secrets
├── .github/
│   └── workflows/
│       ├── terraform-validate.yml
│       └── terraform-test.yml
├── .gitignore
└── README.md
```

## 🚀 Steg-for-steg Setup

### Steg 1: Klon repo og setup shared config

```bash
# Klon ditt repository
git clone https://github.com/<din-bruker>/terraform-azure-course.git
cd terraform-azure-course

# Opprett mappestruktur
mkdir -p shared projects scripts .github/workflows
```

### Steg 2: Opprett backend.hcl

**shared/backend.hcl.example:**
```hcl
# Template - kopier til backend.hcl og fyll inn dine verdier
# IKKE commit backend.hcl til Git!

resource_group_name  = "rg-<DITT_STUDENTNUMMER>-tfstate"
storage_account_name = "st<STUDENTNR>tfstate"
container_name       = "tfstate"
key                  = "PROJECT_NAME/terraform.tfstate"  # Endres per prosjekt

# Autentisering via Service Principal (federated credentials)
use_oidc             = true
```

**Opprett din egen backend.hcl:**
```bash
# Kopier template
cp shared/backend.hcl.example shared/backend.hcl

# Rediger med dine verdier (bruk din favoritt editor)
nano shared/backend.hcl
```

**shared/backend.hcl** (ditt eksempel):
```hcl
resource_group_name  = "rg-student01-tfstate"
storage_account_name = "ststu01tfstate"
container_name       = "tfstate"
key                  = "PROJECT_NAME/terraform.tfstate"

use_oidc             = true
```

### Steg 3: Setup .gitignore

**.gitignore:**
```gitignore
# Terraform
**/.terraform/*
**/.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log

# Sensitive files
shared/backend.hcl
**/terraform.tfvars
**/secrets.tfvars
**/*.auto.tfvars

# Key files
*.pem
*.key
*.p12

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Test artifacts
test-results/
*.test
coverage/
```

### Steg 4: Setup script for nye prosjekter

**scripts/init-project.sh:**
```bash
#!/bin/bash

set -e

# Farger for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Sjekk at backend.hcl eksisterer
if [ ! -f "shared/backend.hcl" ]; then
    echo -e "${RED}❌ shared/backend.hcl ikke funnet!${NC}"
    echo -e "${YELLOW}Kopier shared/backend.hcl.example til shared/backend.hcl og fyll inn dine verdier${NC}"
    exit 1
fi

# Argumenter
PROJECT_NAME=$1
PROJECT_DESCRIPTION=$2

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ Bruk: ./scripts/init-project.sh <project-name> [description]${NC}"
    echo -e "${YELLOW}Eksempel: ./scripts/init-project.sh 01-basic-infrastructure 'Basic Azure resources'${NC}"
    exit 1
fi

PROJECT_DIR="projects/${PROJECT_NAME}"

# Sjekk om prosjekt allerede eksisterer
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Prosjekt ${PROJECT_NAME} eksisterer allerede!${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Oppretter nytt Terraform prosjekt: ${PROJECT_NAME}${NC}"

# Opprett prosjekt-mappe
mkdir -p "$PROJECT_DIR"

# Opprett provider.tf
cat > "$PROJECT_DIR/provider.tf" <<'EOF'
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    # Konfigurasjon kommer fra shared/backend.hcl
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  # Bruk environment variables eller federated credentials
  use_oidc = true
}

# Hent nåværende Azure context
data "azurerm_client_config" "current" {}
EOF

# Opprett variables.tf
cat > "$PROJECT_DIR/variables.tf" <<EOF
variable "student_name" {
  description = "Ditt studentnavn/nummer (brukes i naming)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "norwayeast"
}

variable "tags" {
  description = "Standard tags for alle ressurser"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Course      = "IaC-2025"
    Environment = "dev"
  }
}
EOF

# Opprett main.tf med basis-ressurser
cat > "$PROJECT_DIR/main.tf" <<'EOF'
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.student_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "st${var.student_name}${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Sikkerhet
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  tags = var.tags
}

# Storage Container
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
EOF

# Opprett outputs.tf
cat > "$PROJECT_DIR/outputs.tf" <<'EOF'
output "resource_group_name" {
  description = "Navn på resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Navn på storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID til storage account"
  value       = azurerm_storage_account.main.id
}
EOF

# Opprett terraform.tfvars.example
cat > "$PROJECT_DIR/terraform.tfvars.example" <<EOF
# Kopier til terraform.tfvars og fyll inn dine verdier
# IKKE commit terraform.tfvars til Git!

student_name = "student01"
environment  = "dev"
location     = "norwayeast"
EOF

# Opprett README.md
cat > "$PROJECT_DIR/README.md" <<EOF
# ${PROJECT_NAME}

${PROJECT_DESCRIPTION}

## Forutsetninger

- Azure CLI installert og innlogget
- Terraform >= 1.0 installert
- Tilgang til Azure subscription
- Backend storage account satt opp

## Oppsett

1. **Kopier terraform.tfvars fra template:**
   \`\`\`bash
   cp terraform.tfvars.example terraform.tfvars
   # Rediger terraform.tfvars med dine verdier
   \`\`\`

2. **Initialiser Terraform med backend:**
   \`\`\`bash
   # Fra prosjekt-mappen
   terraform init -backend-config=../../shared/backend.hcl \\
     -backend-config="key=${PROJECT_NAME}/terraform.tfstate"
   \`\`\`

3. **Valider konfigurasjon:**
   \`\`\`bash
   terraform validate
   terraform fmt -check
   \`\`\`

4. **Planlegg deployment:**
   \`\`\`bash
   terraform plan -out=tfplan
   \`\`\`

5. **Deploy infrastruktur:**
   \`\`\`bash
   terraform apply tfplan
   \`\`\`

## Testing

### Static Testing
\`\`\`bash
terraform fmt -check -recursive
terraform validate
\`\`\`

### Linting (krever tflint)
\`\`\`bash
tflint --init
tflint
\`\`\`

### Plan Testing
\`\`\`bash
terraform plan -detailed-exitcode
\`\`\`

## Opprydding

\`\`\`bash
terraform destroy -auto-approve
\`\`\`

## Ressurser opprettet

- Resource Group: \`rg-<student>-<env>\`
- Storage Account: \`st<student><env>\`
- Storage Container: \`data\`
EOF

# Opprett terraform.tfvars (ikke i git)
cat > "$PROJECT_DIR/terraform.tfvars" <<EOF
# Fyll inn dine verdier
student_name = "student01"
environment  = "dev"
location     = "norwayeast"
EOF

echo -e "${GREEN}✅ Prosjekt opprettet: ${PROJECT_DIR}${NC}"
echo ""
echo -e "${BLUE}📝 Neste steg:${NC}"
echo -e "  1. ${YELLOW}cd ${PROJECT_DIR}${NC}"
echo -e "  2. ${YELLOW}Rediger terraform.tfvars med dine verdier${NC}"
echo -e "  3. ${YELLOW}terraform init -backend-config=../../shared/backend.hcl -backend-config='key=${PROJECT_NAME}/terraform.tfstate'${NC}"
echo -e "  4. ${YELLOW}terraform plan${NC}"
echo ""
```

**Gjør scriptet kjørbart:**
```bash
chmod +x scripts/init-project.sh
```

### Steg 5: Opprett ditt første prosjekt

```bash
# Opprett prosjekt
./scripts/init-project.sh 01-basic-infrastructure "Basic Azure infrastructure"

# Gå til prosjekt-mappen
cd projects/01-basic-infrastructure

# Rediger terraform.tfvars med dine verdier
nano terraform.tfvars

# Initialiser med backend
terraform init -backend-config=../../shared/backend.hcl \
  -backend-config="key=01-basic-infrastructure/terraform.tfstate"

# Valider
terraform validate

# Plan
terraform plan

# Apply
terraform apply
```

### Steg 6: Validerings-script for alle prosjekter

**scripts/validate-all.sh:**
```bash
#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Validerer alle Terraform-prosjekter...${NC}"
echo ""

FAILED=0
SUCCEEDED=0

for project_dir in projects/*/; do
    if [ ! -d "$project_dir" ]; then
        continue
    fi
    
    PROJECT_NAME=$(basename "$project_dir")
    echo -e "${BLUE}📁 Validerer: ${PROJECT_NAME}${NC}"
    
    cd "$project_dir"
    
    # Format check
    if terraform fmt -check -recursive > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Format check passed${NC}"
    else
        echo -e "  ${RED}❌ Format check failed${NC}"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        continue
    fi
    
    # Init (uten backend)
    if terraform init -backend=false > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Init passed${NC}"
    else
        echo -e "  ${RED}❌ Init failed${NC}"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        continue
    fi
    
    # Validate
    if terraform validate > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Validate passed${NC}"
        SUCCEEDED=$((SUCCEEDED + 1))
    else
        echo -e "  ${RED}❌ Validate failed${NC}"
        FAILED=$((FAILED + 1))
    fi
    
    cd - > /dev/null
    echo ""
done

echo -e "${BLUE}📊 Resultat:${NC}"
echo -e "  ${GREEN}✅ Succeeded: ${SUCCEEDED}${NC}"
echo -e "  ${RED}❌ Failed: ${FAILED}${NC}"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
```

```bash
chmod +x scripts/validate-all.sh
```

### Steg 7: GitHub Actions setup

**Først, setup GitHub secrets:**

**scripts/setup-github-secrets.sh:**
```bash
#!/bin/bash

set -e

echo "🔐 Setting up GitHub secrets for Terraform..."
echo ""

# Les backend.hcl
if [ ! -f "shared/backend.hcl" ]; then
    echo "❌ shared/backend.hcl ikke funnet!"
    exit 1
fi

# Parse verdier fra backend.hcl
RG_NAME=$(grep 'resource_group_name' shared/backend.hcl | cut -d'"' -f2)
SA_NAME=$(grep 'storage_account_name' shared/backend.hcl | cut -d'"' -f2)
CONTAINER_NAME=$(grep 'container_name' shared/backend.hcl | cut -d'"' -f2)

echo "📋 Verdier funnet i backend.hcl:"
echo "  Resource Group: $RG_NAME"
echo "  Storage Account: $SA_NAME"
echo "  Container: $CONTAINER_NAME"
echo ""

# Hent Azure subscription info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "📋 Azure info:"
echo "  Subscription ID: $SUBSCRIPTION_ID"
echo "  Tenant ID: $TENANT_ID"
echo ""

# Hent Service Principal info fra App Registration
echo "ℹ️  Hent CLIENT_ID fra din App Registration i Azure Portal"
echo "    Azure Portal → App Registrations → Din app → Overview → Application (client) ID"
echo ""
read -p "Skriv inn CLIENT_ID: " CLIENT_ID

echo ""
echo "📝 Kjør følgende kommandoer for å sette GitHub secrets:"
echo "   (Erstatt <owner>/<repo> med ditt repository)"
echo ""

cat <<EOF
gh secret set AZURE_CLIENT_ID --body="$CLIENT_ID" --repo <owner>/<repo>
gh secret set AZURE_SUBSCRIPTION_ID --body="$SUBSCRIPTION_ID" --repo <owner>/<repo>
gh secret set AZURE_TENANT_ID --body="$TENANT_ID" --repo <owner>/<repo>
gh secret set TF_STATE_RG --body="$RG_NAME" --repo <owner>/<repo>
gh secret set TF_STATE_SA --body="$SA_NAME" --repo <owner>/<repo>
gh secret set TF_STATE_CONTAINER --body="$CONTAINER_NAME" --repo <owner>/<repo>
EOF

echo ""
echo "✅ Eller legg til secrets manuelt i GitHub:"
echo "   Settings → Secrets and variables → Actions → New repository secret"
```

```bash
chmod +x scripts/setup-github-secrets.sh
./scripts/setup-github-secrets.sh
```

**.github/workflows/terraform-validate.yml:**
```yaml
name: Terraform Validation

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  validate:
    name: Validate All Projects
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Terraform Format Check
        run: |
          echo "🎨 Checking Terraform formatting..."
          terraform fmt -check -recursive
      
      - name: Validate All Projects
        run: |
          echo "🔍 Validating all projects..."
          ./scripts/validate-all.sh
      
      - name: Setup TFLint
        uses: terraform-linters/setup-tflint@v4
        with:
          tflint_version: latest
      
      - name: Init TFLint
        run: tflint --init
      
      - name: Run TFLint
        run: |
          echo "🔎 Running TFLint..."
          for project_dir in projects/*/; do
            if [ -d "$project_dir" ]; then
              echo "Linting $(basename $project_dir)..."
              cd "$project_dir"
              tflint --format compact
              cd - > /dev/null
            fi
          done
```

**.github/workflows/terraform-test.yml:**
```yaml
name: Terraform Test & Deploy

on:
  workflow_dispatch:
    inputs:
      project:
        description: 'Project to test/deploy'
        required: true
        type: choice
        options:
          - 01-basic-infrastructure
          - 02-with-modules
          - 03-testing-example
      action:
        description: 'Action to perform'
        required: true
        type: choice
        options:
          - plan
          - apply
          - destroy

permissions:
  id-token: write
  contents: read

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_USE_OIDC: true

jobs:
  terraform:
    name: Terraform ${{ github.event.inputs.action }}
    runs-on: ubuntu-latest
    
    defaults:
      run:
        working-directory: projects/${{ github.event.inputs.project }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Azure Login (OIDC)
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Create backend config
        run: |
          cat <<EOF > backend.hcl
          resource_group_name  = "${{ secrets.TF_STATE_RG }}"
          storage_account_name = "${{ secrets.TF_STATE_SA }}"
          container_name       = "${{ secrets.TF_STATE_CONTAINER }}"
          key                  = "${{ github.event.inputs.project }}/terraform.tfstate"
          use_oidc             = true
          EOF
      
      - name: Terraform Init
        run: terraform init -backend-config=backend.hcl
      
      - name: Terraform Validate
        run: terraform validate
      
      - name: Terraform Plan
        if: github.event.inputs.action == 'plan' || github.event.inputs.action == 'apply'
        run: terraform plan -out=tfplan
      
      - name: Terraform Apply
        if: github.event.inputs.action == 'apply'
        run: terraform apply -auto-approve tfplan
      
      - name: Terraform Destroy
        if: github.event.inputs.action == 'destroy'
        run: terraform destroy -auto-approve
```

### Steg 8: Testing setup

**Opprett test-mappe i prosjektet:**

```bash
cd projects/01-basic-infrastructure
mkdir -p test
```

**test/integration_test.sh:**
```bash
#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Running integration tests...${NC}"
echo ""

# Hent outputs fra Terraform
RG_NAME=$(terraform output -raw resource_group_name)
STORAGE_NAME=$(terraform output -raw storage_account_name)

echo -e "${BLUE}Testing Resource Group: ${RG_NAME}${NC}"

# Test 1: Resource Group eksisterer
if az group show --name "$RG_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Resource Group exists${NC}"
else
    echo -e "${RED}❌ Resource Group not found${NC}"
    exit 1
fi

# Test 2: Storage Account eksisterer
echo -e "${BLUE}Testing Storage Account: ${STORAGE_NAME}${NC}"
if az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Storage Account exists${NC}"
else
    echo -e "${RED}❌ Storage Account not found${NC}"
    exit 1
fi

# Test 3: HTTPS er påkrevd
HTTPS_ONLY=$(az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" --query "enableHttpsTrafficOnly" -o tsv)
if [ "$HTTPS_ONLY" == "true" ]; then
    echo -e "${GREEN}✅ HTTPS traffic only is enabled${NC}"
else
    echo -e "${RED}❌ HTTPS traffic only is NOT enabled${NC}"
    exit 1
fi

# Test 4: TLS version
TLS_VERSION=$(az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" --query "minimumTlsVersion" -o tsv)
if [ "$TLS_VERSION" == "TLS1_2" ]; then
    echo -e "${GREEN}✅ Minimum TLS version is 1.2${NC}"
else
    echo -e "${RED}❌ TLS version is not 1.2 (found: $TLS_VERSION)${NC}"
    exit 1
fi

# Test 5: Tags
TAGS=$(az group show --name "$RG_NAME" --query "tags" -o json)
if echo "$TAGS" | grep -q "ManagedBy"; then
    echo -e "${GREEN}✅ Required tags are present${NC}"
else
    echo -e "${RED}❌ Required tags are missing${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All integration tests passed!${NC}"
```

```bash
chmod +x test/integration_test.sh
```

**test/drift_detection.sh:**
```bash
#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Running drift detection...${NC}"
echo ""

# Kjør terraform plan og sjekk exit code
terraform plan -detailed-exitcode -out=drift.tfplan

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ No drift detected - infrastructure matches code${NC}"
    rm -f drift.tfplan
    exit 0
elif [ $EXIT_CODE -eq 2 ]; then
    echo -e "${YELLOW}⚠️  DRIFT DETECTED!${NC}"
    echo ""
    echo -e "${RED}Manual changes have been detected in your infrastructure.${NC}"
    echo -e "${YELLOW}Review the plan above to see what changed.${NC}"
    echo ""
    echo "Options:"
    echo "  1. Apply changes to align infrastructure with code: terraform apply drift.tfplan"
    echo "  2. Update code to match infrastructure changes"
    echo ""
    rm -f drift.tfplan
    exit 1
else
    echo -e "${RED}❌ Error running terraform plan${NC}"
    rm -f drift.tfplan
    exit 1
fi
```

```bash
chmod +x test/drift_detection.sh
```

### Steg 9: TFLint konfigurasjon

**.tflint.hcl** (i root):
```hcl
plugin "azurerm" {
  enabled = true
  version = "0.25.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

rule "terraform_naming_convention" {
  enabled = true
  
  format = "snake_case"
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "azurerm_resource_tag" {
  enabled = true
  tags = ["Environment", "ManagedBy"]
}
```

## 📚 Komplett bruksguide

### Daglig workflow

```bash
# 1. Opprett nytt prosjekt
./scripts/init-project.sh 02-with-modules "Module example"

# 2. Gå til prosjekt
cd projects/02-with-modules

# 3. Rediger tfvars
nano terraform.tfvars

# 4. Init med backend
terraform init -backend-config=../../shared/backend.hcl \
  -backend-config="key=02-with-modules/terraform.tfstate"

# 5. Valider
terraform validate
terraform fmt -check

# 6. Plan
terraform plan -out=tfplan

# 7. Apply
terraform apply tfplan

# 8. Test
./test/integration_test.sh

# 9. Drift detection
./test/drift_detection.sh

# 10. Cleanup
terraform destroy -auto-approve
```

### Test all prosjekter

```bash
# Fra root
./scripts/validate-all.sh
```

### Bytt mellom prosjekter

```bash
# Prosjekt 1
cd projects/01-basic-infrastructure
terraform workspace select default

# Prosjekt 2
cd ../02-with-modules
terraform workspace select default
```

## 🎯 Testing nivåer - Quick reference

| Test Type | Kommando | Når |
|-----------|----------|-----|
| **Format** | `terraform fmt -check` | Før commit |
| **Validate** | `terraform validate` | Før commit |
| **Lint** | `tflint` | Før commit |
| **Plan** | `terraform plan` | Før apply |
| **Integration** | `./test/integration_test.sh` | Etter apply |
| **Drift** | `./test/drift_detection.sh` | Daglig/ukentlig |

## 🔧 Troubleshooting

### Problem: Backend init feiler

```bash
# Sjekk at backend.hcl har riktige verdier
cat shared/backend.hcl

# Sjekk at storage account eksisterer
az storage account show --name <STORAGE_ACCOUNT_NAME>

# Sjekk at container eksisterer
az storage container show --name tfstate --account-name <STORAGE_ACCOUNT_NAME>
```

### Problem: Authentication feiler

```bash
# Logg inn på nytt
az login

# Sjekk subscription
az account show

# Sett riktig subscription
az account set --subscription <SUBSCRIPTION_ID>
```

### Problem: State lock

```bash
# List locks
az storage blob lease list \
  --container-name tfstate \
  --account-name <STORAGE_ACCOUNT_NAME>

# Break lock (bruk med forsiktighet!)
terraform force-unlock <LOCK_ID>
```

## 📖 Ressurser

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---
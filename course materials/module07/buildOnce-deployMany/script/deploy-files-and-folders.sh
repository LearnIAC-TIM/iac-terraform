#!/bin/bash
# ============================================
# BASH SCRIPT: setup-project.sh
# ============================================
# Genererer komplett prosjektstruktur for Del 1: Build Once, Deploy Many
# 
# Bruk:
#   ./setup-project.sh
#   eller
#   ./setup-project.sh my-terraform-demo

set -e

PROJECT_NAME="${1:-simple-terraform}"

echo "🚀 Oppretter prosjekt: $PROJECT_NAME"
echo ""

# Opprett hovedmappe
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Opprett mappestruktur
echo "📁 Oppretter mappestruktur..."
mkdir -p terraform
mkdir -p environments
mkdir -p backend-configs
mkdir -p .github/workflows
mkdir -p scripts

echo "  ✓ terraform"
echo "  ✓ environments"
echo "  ✓ backend-configs"
echo "  ✓ .github/workflows"
echo "  ✓ scripts"
echo ""

echo "📝 Genererer filer..."

# ============================================
# TERRAFORM FILES
# ============================================

# terraform/versions.tf
echo "  ✓ terraform/versions.tf"
cat > terraform/versions.tf << 'EOF'
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
EOF

# terraform/backend.tf
echo "  ✓ terraform/backend.tf"
cat > terraform/backend.tf << 'EOF'
# Backend configuration provided via -backend-config flag
# This keeps the backend block flexible for different environments
terraform {
  backend "azurerm" {
    # Configuration will be provided via backend-configs/*.tfvars
  }
}
EOF

# terraform/variables.tf
echo "  ✓ terraform/variables.tf"
cat > terraform/variables.tf << 'EOF'
variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "norwayeast"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "demo"
}
EOF

# terraform/main.tf
echo "  ✓ terraform/main.tf"
cat > terraform/main.tf << 'EOF'
# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                = "st${var.project_name}${var.environment}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Storage Container
resource "azurerm_storage_container" "demo" {
  name                  = "demo-data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
EOF

# terraform/outputs.tf
echo "  ✓ terraform/outputs.tf"
cat > terraform/outputs.tf << 'EOF'
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "environment" {
  description = "Deployed environment"
  value       = var.environment
}
EOF

# ============================================
# ENVIRONMENT CONFIGS
# ============================================

echo "  ✓ environments/dev.tfvars"
cat > environments/dev.tfvars << 'EOF'
environment  = "dev"
location     = "norwayeast"
project_name = "demo"
EOF

echo "  ✓ environments/test.tfvars"
cat > environments/test.tfvars << 'EOF'
environment  = "test"
location     = "norwayeast"
project_name = "demo"
EOF

# ============================================
# BACKEND CONFIGS
# ============================================

echo "  ✓ backend-configs/backend-dev.tfvars"
cat > backend-configs/backend-dev.tfvars << 'EOF'
resource_group_name  = "rg-terraform-state"
storage_account_name = "sttfstatedev"
container_name       = "tfstate"
key                  = "dev/terraform.tfstate"
EOF

echo "  ✓ backend-configs/backend-test.tfvars"
cat > backend-configs/backend-test.tfvars << 'EOF'
resource_group_name  = "rg-terraform-state"
storage_account_name = "sttfstatetest"
container_name       = "tfstate"
key                  = "test/terraform.tfstate"
EOF

# ============================================
# SCRIPTS
# ============================================

echo "  ✓ scripts/build.sh"
cat > scripts/build.sh << 'EOFSCRIPT'
#!/bin/bash
set -e

echo "📦 Building Terraform Artifact..."
echo ""

# Generate version from git or timestamp
if git rev-parse --git-dir > /dev/null 2>&1; then
  VERSION=$(git rev-parse --short HEAD)
else
  VERSION=$(date +%Y%m%d-%H%M%S)
fi

echo "Version: $VERSION"
echo ""

# Validate Terraform
echo "1️⃣ Validating Terraform..."
cd terraform
terraform fmt -check -recursive || (echo "⚠️  Run 'terraform fmt -recursive' to fix formatting" && exit 1)
terraform init -backend=false
terraform validate
cd ..

echo "✅ Validation complete!"
echo ""

# Create artifact
echo "2️⃣ Creating artifact..."
ARTIFACT_NAME="terraform-${VERSION}.tar.gz"

tar -czf $ARTIFACT_NAME \
  terraform/ \
  environments/ \
  backend-configs/

echo "✅ Artifact created: $ARTIFACT_NAME"
echo ""

# Show artifact info
echo "📊 Artifact Information:"
ls -lh $ARTIFACT_NAME
echo ""
echo "🎯 Next steps:"
echo "  - Deploy to dev:  ./scripts/deploy.sh dev $ARTIFACT_NAME"
echo "  - Deploy to test: ./scripts/deploy.sh test $ARTIFACT_NAME"
EOFSCRIPT

chmod +x scripts/build.sh

echo "  ✓ scripts/deploy.sh"
cat > scripts/deploy.sh << 'EOFSCRIPT'
#!/bin/bash
set -e

# Usage: ./scripts/deploy.sh <environment> <artifact>

ENVIRONMENT=$1
ARTIFACT=$2

if [ -z "$ENVIRONMENT" ]; then
  echo "❌ Error: Environment required"
  echo "Usage: ./scripts/deploy.sh <environment> <artifact>"
  exit 1
fi

if [ -z "$ARTIFACT" ]; then
  echo "❌ Error: Artifact required"
  exit 1
fi

if [ ! -f "$ARTIFACT" ]; then
  echo "❌ Error: Artifact not found: $ARTIFACT"
  exit 1
fi

echo "🚀 Deploying to $ENVIRONMENT environment..."
echo ""

# Create workspace
WORKSPACE="workspace-${ENVIRONMENT}"
rm -rf $WORKSPACE
mkdir -p $WORKSPACE

# Extract artifact
echo "1️⃣ Extracting artifact..."
tar -xzf $ARTIFACT -C $WORKSPACE
echo "✅ Artifact extracted"
echo ""

cd $WORKSPACE/terraform

# Initialize with backend
echo "2️⃣ Initializing Terraform..."
terraform init -backend-config=../backend-configs/backend-${ENVIRONMENT}.tfvars
echo ""

# Plan
echo "3️⃣ Planning deployment..."
terraform plan -var-file=../environments/${ENVIRONMENT}.tfvars -out=tfplan
echo ""

# Apply
echo "4️⃣ Applying changes..."
terraform apply -auto-approve tfplan
echo ""

# Show outputs
echo "✅ Deployment complete!"
echo ""
echo "📤 Outputs:"
terraform output

cd ../..
EOFSCRIPT

chmod +x scripts/deploy.sh

# ============================================
# GITHUB ACTIONS
# ============================================

echo "  ✓ .github/workflows/pipeline.yml"
cat > .github/workflows/pipeline.yml << 'EOF'
name: Build Once Deploy Many - Demo

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

env:
  TF_VERSION: '1.5.7'

jobs:
  # ==========================================
  # BUILD STAGE - Kjører ÉN gang
  # ==========================================
  build:
    name: 'Build Artifact'
    runs-on: ubuntu-latest
    
    outputs:
      artifact_version: ${{ steps.version.outputs.version }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Generate version
        id: version
        run: |
          VERSION=$(git rev-parse --short HEAD)
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "📌 Building version: $VERSION"
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Format Check
        run: |
          cd terraform
          terraform fmt -check -recursive
      
      - name: Terraform Init (no backend)
        run: |
          cd terraform
          terraform init -backend=false
      
      - name: Terraform Validate
        run: |
          cd terraform
          terraform validate
      
      - name: Create Artifact
        run: |
          VERSION=${{ steps.version.outputs.version }}
          
          tar -czf terraform-${VERSION}.tar.gz \
            terraform/ \
            environments/ \
            backend-configs/
          
          echo "✅ Created artifact: terraform-${VERSION}.tar.gz"
          ls -lh terraform-${VERSION}.tar.gz
      
      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: terraform-artifact
          path: terraform-*.tar.gz
          retention-days: 30
      
      - name: Build Summary
        run: |
          echo "### Build Complete 📦" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "- **Version**: ${{ steps.version.outputs.version }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Terraform**: ${{ env.TF_VERSION }}" >> $GITHUB_STEP_SUMMARY

  # ==========================================
  # DEPLOY TO DEV - Bruker samme artifact
  # ==========================================
  deploy-dev:
    name: 'Deploy to Dev'
    needs: build
    runs-on: ubuntu-latest
    environment: dev
    
    steps:
      - name: Download Artifact
        uses: actions/download-artifact@v4
        with:
          name: terraform-artifact
      
      - name: Extract Artifact
        run: |
          mkdir -p workspace
          tar -xzf terraform-*.tar.gz -C workspace
          echo "📂 Artifact contents:"
          ls -la workspace
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Terraform Init
        run: |
          cd workspace/terraform
          terraform init -backend-config=../backend-configs/backend-dev.tfvars
      
      - name: Terraform Plan
        run: |
          cd workspace/terraform
          terraform plan -var-file=../environments/dev.tfvars -out=tfplan
      
      - name: Terraform Apply
        run: |
          cd workspace/terraform
          terraform apply -auto-approve tfplan
      
      - name: Deployment Summary
        run: |
          echo "### Dev Deployment ✅" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "- **Artifact**: ${{ needs.build.outputs.artifact_version }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Environment**: Development" >> $GITHUB_STEP_SUMMARY

  # ==========================================
  # DEPLOY TO TEST - Bruker samme artifact!
  # ==========================================
  deploy-test:
    name: 'Deploy to Test'
    needs: [build, deploy-dev]
    runs-on: ubuntu-latest
    environment: test
    
    steps:
      - name: Download SAME Artifact
        uses: actions/download-artifact@v4
        with:
          name: terraform-artifact
      
      - name: Extract Artifact
        run: |
          mkdir -p workspace
          tar -xzf terraform-*.tar.gz -C workspace
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Terraform Init (TEST Backend)
        run: |
          cd workspace/terraform
          terraform init -backend-config=../backend-configs/backend-test.tfvars
      
      - name: Terraform Plan
        run: |
          cd workspace/terraform
          terraform plan -var-file=../environments/test.tfvars -out=tfplan
      
      - name: Terraform Apply
        run: |
          cd workspace/terraform
          terraform apply -auto-approve tfplan
      
      - name: Deployment Summary
        run: |
          echo "### Test Deployment ✅" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "- **Artifact**: ${{ needs.build.outputs.artifact_version }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Environment**: Test" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Note**: Same artifact as Dev! ✨" >> $GITHUB_STEP_SUMMARY
EOF

# ============================================
# DOCUMENTATION
# ============================================

echo "  ✓ README.md"
cat > README.md << 'EOF'
# Simple Terraform - Build Once, Deploy Many Demo

Dette prosjektet demonstrerer "Build Once, Deploy Many" prinsippet med Terraform og Azure.

## 🎯 Konsept

**Build Once, Deploy Many** betyr:
- Bygg artifact ÉN gang
- Deploy SAMME artifact til flere miljøer
- Garantert konsistens mellom miljøer

## 📁 Struktur

```
simple-terraform/
├── terraform/          # Terraform kode (felles)
├── environments/       # Miljø-spesifikk config
├── backend-configs/    # Backend config per miljø
├── .github/workflows/  # GitHub Actions pipeline
└── scripts/           # Build og deploy scripts
```

## 🚀 Lokal Testing

### Forutsetninger
- Terraform >= 1.5.0
- Azure CLI
- Git (for versjonering)

### Steg 1: Bygg Artifact

```bash
./scripts/build.sh
```

Dette oppretter: `terraform-<version>.tar.gz`

### Steg 2: Deploy til Dev

```bash
./scripts/deploy.sh dev terraform-<version>.tar.gz
```

### Steg 3: Deploy SAMME Artifact til Test

```bash
./scripts/deploy.sh test terraform-<version>.tar.gz
```

## 🔍 Verifiser Build Once, Deploy Many

```bash
# Sammenlign lock files (skal være identiske!)
diff workspace-dev/terraform/.terraform.lock.hcl \
     workspace-test/terraform/.terraform.lock.hcl

# Ingen output = success! ✅
```

## ☁️ GitHub Actions

Pipeline kjører automatisk ved push til main:
1. **Build** - Lager artifact
2. **Deploy Dev** - Deployer til dev
3. **Deploy Test** - Deployer SAMME artifact til test

## 🧹 Cleanup

```bash
# Destroy dev
cd workspace-dev/terraform
terraform destroy -var-file=../environments/dev.tfvars -auto-approve

# Destroy test
cd ../../workspace-test/terraform
terraform destroy -var-file=../environments/test.tfvars -auto-approve
```

## 📚 Læringsmål

- ✅ Forstå Build Once, Deploy Many
- ✅ Se forskjellen på artifact og deployment
- ✅ Håndtere miljø-spesifikk konfigurasjon
- ✅ Verifisere konsistens mellom miljøer

## 🎓 Neste Steg

Del 2: Artifact Storage i Azure og eksisterende infrastruktur
EOF

echo "  ✓ .gitignore"
cat > .gitignore << 'EOF'
# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
.terraform.lock.hcl

# Artifacts
*.tar.gz
workspace-*/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db
EOF

# ============================================
# FINISH
# ============================================

echo ""
echo "✅ Prosjekt opprettet!"
echo ""
echo "📂 Prosjekt: $PROJECT_NAME"
echo ""
echo "🎯 Neste steg:"
echo "  1. cd $PROJECT_NAME"
echo "  2. Les README.md for instruksjoner"
echo "  3. Bygg artifact: ./scripts/build.sh"
echo "  4. Deploy: ./scripts/deploy.sh dev <artifact>"
echo ""
echo "💡 Tips: Sjekk README.md for full guide"
echo ""

cd ..
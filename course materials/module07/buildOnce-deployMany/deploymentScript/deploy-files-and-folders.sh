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
mkdir -p scripts

echo "  ✓ terraform"
echo "  ✓ environments"
echo "  ✓ backend-configs"
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
      version = "~> 4.40"
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
  resource_provider_registrations = "none"
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

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Storage Container
resource "azurerm_storage_container" "demo" {
  name                  = "demo-data"
  storage_account_id   = azurerm_storage_account.main.id
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

echo "  ✓ scripts/cleanup.sh"
cat > scripts/cleanup.sh << 'EOFSCRIPT'

#!/bin/bash
set -e

echo "🧹 Cleanup Script for Terraform Demo"
echo ""

# Function to destroy environment
destroy_environment() {
    local ENV=$1
    local WORKSPACE="workspace-${ENV}"
    
    echo "───────────────────────────────────────"
    echo "Cleaning up: $ENV environment"
    echo "───────────────────────────────────────"
    echo ""
    
    if [ ! -d "$WORKSPACE" ]; then
        echo "⚠️  Workspace not found: $WORKSPACE"
        echo "   Skipping terraform destroy (use Azure cleanup if needed)"
        echo ""
        return
    fi
    
    # Get subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null)
    if [ -z "$SUBSCRIPTION_ID" ]; then
        echo "❌ Error: Not logged in to Azure"
        echo "   Please run: az login"
        return 1
    fi
    
    export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
    
    cd "$WORKSPACE/terraform"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        echo "🔧 Initializing Terraform..."
        terraform init -backend-config=../backend-configs/backend-${ENV}.tfvars
        echo ""
    fi
    
    # Show what will be destroyed
    echo "📋 Planning destruction..."
    terraform plan -destroy -var-file=../environments/${ENV}.tfvars
    echo ""
    
    # Confirm
    read -p "❓ Destroy $ENV environment? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "⏭️  Skipped $ENV"
        cd ../..
        echo ""
        return
    fi
    
    # Destroy
    echo ""
    echo "💥 Destroying infrastructure..."
    terraform destroy -var-file=../environments/${ENV}.tfvars -auto-approve
    
    cd ../..
    echo ""
    echo "✅ $ENV environment destroyed"
    echo ""
}

# Main menu
echo "Select cleanup option:"
echo ""
echo "  1) Destroy DEV environment"
echo "  2) Destroy TEST environment"
echo "  3) Destroy PROD environment"
echo "  4) Destroy ALL environments"
echo "  5) Clean local files only (workspaces, artifacts)"
echo "  6) Force cleanup via Azure CLI (if terraform fails)"
echo "  7) Full cleanup (everything)"
echo "  0) Cancel"
echo ""
read -p "Enter choice [0-7]: " choice

case $choice in
    1)
        destroy_environment "dev"
        ;;
    2)
        destroy_environment "test"
        ;;
    3)
        destroy_environment "prod"
        ;;
    4)
        destroy_environment "dev"
        destroy_environment "test"
        destroy_environment "prod"
        ;;
    5)
        echo "🧹 Cleaning local files..."
        echo ""
        
        # Remove workspaces
        if ls -d workspace-* 2>/dev/null; then
            echo "  Removing workspaces..."
            rm -rf workspace-*
            echo "  ✅ Workspaces removed"
        fi
        
        # Remove artifacts
        if ls terraform-*.tar.gz 2>/dev/null; then
            echo "  Removing artifacts..."
            rm -f terraform-*.tar.gz
            echo "  ✅ Artifacts removed"
        fi
        
        echo ""
        echo "✅ Local cleanup complete"
        echo ""
        ;;
    6)
        echo "💥 Force cleanup via Azure CLI"
        echo ""
        echo "⚠️  WARNING: This will delete resource groups directly!"
        echo "   Use this only if terraform destroy fails."
        echo ""
        read -p "Continue? (yes/no): " confirm
        
        if [ "$confirm" == "yes" ]; then
            echo ""
            echo "Available resource groups:"
            az group list --query "[?starts_with(name, 'rg-demo-')].{Name:name, Location:location}" -o table
            echo ""
            read -p "Enter resource group name to delete (or 'all' for all demo groups): " rg_name
            
            if [ "$rg_name" == "all" ]; then
                echo ""
                echo "🔥 Deleting all demo resource groups..."
                for rg in $(az group list --query "[?starts_with(name, 'rg-demo-')].name" -o tsv); do
                    echo "  Deleting: $rg"
                    az group delete --name "$rg" --yes --no-wait
                done
                echo ""
                echo "✅ Deletion initiated (running in background)"
                echo "   Check status: az group list -o table"
            elif [ ! -z "$rg_name" ]; then
                echo ""
                echo "🔥 Deleting: $rg_name"
                az group delete --name "$rg_name" --yes --no-wait
                echo ""
                echo "✅ Deletion initiated"
            fi
        fi
        echo ""
        ;;
    7)
        echo "🔥 FULL CLEANUP - Everything will be removed!"
        echo ""
        read -p "Are you sure? (yes/no): " confirm
        
        if [ "$confirm" == "yes" ]; then
            # Destroy all environments
            destroy_environment "dev"
            destroy_environment "test"
            destroy_environment "prod"
            
            # Clean local files
            echo "🧹 Cleaning local files..."
            rm -rf workspace-*
            rm -f terraform-*.tar.gz
            
            echo ""
            echo "✅ Full cleanup complete!"
        fi
        echo ""
        ;;
    0)
        echo "Cancelled"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo "───────────────────────────────────────"
echo "Cleanup script finished"
echo "───────────────────────────────────────"
EOFSCRIPT

chmod +x scripts/cleanup.sh

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
terraform fmt -recursive || (echo "⚠️  Run 'terraform fmt -recursive' to fix formatting" && exit 1)
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

# Get subscription ID from Azure CLI
echo "🔍 Getting Azure subscription ID..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

if [ -z "$SUBSCRIPTION_ID" ]; then
  echo "❌ Error: Could not get subscription ID. Please run 'az login' first."
  exit 1
fi

echo "✅ Using subscription: $SUBSCRIPTION_ID"
echo ""

# Export as environment variable for Terraform
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID

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

**Linux/Mac:**
```bash
./scripts/cleanup.sh dev terraform-<version>.tar.gz
```


## 📚 Læringsmål

- ✅ Forstå Build Once, Deploy Many
- ✅ Se forskjellen på artifact og deployment
- ✅ Håndtere miljø-spesifikk konfigurasjon
- ✅ Verifisere konsistens mellom miljøer

## 🎓 Neste Steg

Del 2: Artifact Storage i Azure og eksisterende infrastruktur
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
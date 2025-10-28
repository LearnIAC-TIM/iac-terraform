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
    echo -e "${YELLOW}Eksempel: ./scripts/init-project.sh 02-with-modules 'Infrastructure with modules'${NC}"
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
mkdir -p "$PROJECT_DIR/test"

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

## Oppsett

1. **Kopier terraform.tfvars fra template:**
   \`\`\`bash
   cp terraform.tfvars.example terraform.tfvars
   # Rediger terraform.tfvars med dine verdier
   \`\`\`

2. **Initialiser Terraform med backend:**
   \`\`\`bash
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

\`\`\`bash
terraform fmt -check -recursive
terraform validate
./test/integration_test.sh
./test/drift_detection.sh
\`\`\`

## Opprydding

\`\`\`bash
terraform destroy -auto-approve
\`\`\`
EOF

echo -e "${GREEN}✅ Prosjekt opprettet: ${PROJECT_DIR}${NC}"
echo ""
echo -e "${BLUE}📝 Neste steg:${NC}"
echo -e "  1. ${YELLOW}cd ${PROJECT_DIR}${NC}"
echo -e "  2. ${YELLOW}cp terraform.tfvars.example terraform.tfvars${NC}"
echo -e "  3. ${YELLOW}Rediger terraform.tfvars med dine verdier${NC}"
echo -e "  4. ${YELLOW}terraform init -backend-config=../../shared/backend.hcl -backend-config='key=${PROJECT_NAME}/terraform.tfstate'${NC}"
echo -e "  5. ${YELLOW}terraform plan${NC}"
echo ""

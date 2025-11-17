#!/usr/bin/env bash

set -euo pipefail

ROOT="iac-storage"

echo "Oppretter rotmappe: $ROOT"
mkdir -p "$ROOT"

echo "Oppretter Terraform-rotmodul i $ROOT/terraform"
mkdir -p "$ROOT/terraform"

echo "Oppretter miljømapper i $ROOT/environments/{dev,test,prod}"
mkdir -p "$ROOT/environments/dev"
mkdir -p "$ROOT/environments/test"
mkdir -p "$ROOT/environments/prod"

###############################################
# Terraform-rotmodul: terraform/
###############################################

cat <<EOF > "$ROOT/terraform/versions.tf"
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.47"
    }
  }
}
EOF

cat <<EOF > "$ROOT/terraform/backend.tf"
terraform {
  backend "azurerm" {}
}
EOF

cat <<EOF > "$ROOT/terraform/variables.tf"
variable "location" {
  type        = string
  description = "Azure region for the resources."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique name of the Storage Account."
}

variable "storage_account_tier" {
  type        = string
  default     = "Standard"
  description = "Storage account tier (Standard/Premium)."
}

variable "storage_account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Replication type (LRS, GRS, RAGRS, ZRS, etc.)."
}

variable "container_name" {
  type        = string
  description = "Name of the blob container."
}

variable "environment" {
  type        = string
  description = "Environment name (dev, test, prod)."
}
EOF

cat <<EOF > "$ROOT/terraform/main.tf"
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type

  allow_blob_public_access = false

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}
EOF

cat <<EOF > "$ROOT/terraform/outputs.tf"
output "storage_account_id" {
  value       = azurerm_storage_account.this.id
  description = "The ID of the storage account."
}

output "storage_account_name" {
  value       = azurerm_storage_account.this.name
  description = "The name of the storage account."
}

output "container_name" {
  value       = azurerm_storage_container.this.name
  description = "The name of the container."
}
EOF

###############################################
# Miljøspesifikke tfvars-filer
# Plasseres i environments/<env>/<env>.tfvars
###############################################

cat <<EOF > "$ROOT/environments/dev/dev.tfvars"
location                        = "northeurope"
resource_group_name             = "rg-storage-dev"
storage_account_name            = "stdev$RANDOM"
storage_account_tier            = "Standard"
storage_account_replication_type = "LRS"
container_name                  = "appdata-dev"
environment                     = "dev"
EOF

cat <<EOF > "$ROOT/environments/test/test.tfvars"
location                        = "northeurope"
resource_group_name             = "rg-storage-test"
storage_account_name            = "sttest$RANDOM"
storage_account_tier            = "Standard"
storage_account_replication_type = "LRS"
container_name                  = "appdata-test"
environment                     = "test"
EOF

cat <<EOF > "$ROOT/environments/prod/prod.tfvars"
location                        = "northeurope"
resource_group_name             = "rg-storage-prod"
storage_account_name            = "stprod$RANDOM"
storage_account_tier            = "Standard"
storage_account_replication_type = "GRS"
container_name                  = "appdata-prod"
environment                     = "prod"
EOF

###############################################
# Backend-konfigurasjon per miljø
# Plasseres i environments/<env>/backend.hcl
###############################################

cat <<EOF > "$ROOT/environments/dev/backend.hcl"
resource_group_name  = "rg-iac-state"
storage_account_name = "staciacstate001"
container_name       = "tfstate"
key                  = "storage/dev/terraform.tfstate"
EOF

cat <<EOF > "$ROOT/environments/test/backend.hcl"
resource_group_name  = "rg-iac-state"
storage_account_name = "staciacstate001"
container_name       = "tfstate"
key                  = "storage/test/terraform.tfstate"
EOF

cat <<EOF > "$ROOT/environments/prod/backend.hcl"
resource_group_name  = "rg-iac-state"
storage_account_name = "staciacstate001"
container_name       = "tfstate"
key                  = "storage/prod/terraform.tfstate"
EOF

###############################################
# Enkel README for studenten
###############################################

cat <<'EOF' > "$ROOT/README.md"
# iac-storage – enkel struktur for dev, test og prod

Denne mappen inneholder et enkelt Terraform-oppsett for en ressursgruppe, en Storage Account og en container i Azure. Samme kode brukes for dev, test og prod. Miljøene skilles av egne backend-filer og egne tfvars-filer.

## Strukturen

- `terraform/`
  - Felles Terraform-kode (root-modul):
    - `versions.tf`
    - `backend.tf`
    - `variables.tf`
    - `main.tf`
    - `outputs.tf`
- `environments/dev`
  - `backend.hcl` – backend-konfigurasjon for dev-state
  - `dev.tfvars` – variabler for dev-miljøet
- `environments/test`
  - `backend.hcl` – backend-konfigurasjon for test-state
  - `test.tfvars` – variabler for test-miljøet
- `environments/prod`
  - `backend.hcl` – backend-konfigurasjon for prod-state
  - `prod.tfvars` – variabler for prod-miljøet

## Eksempelkommandoer

Fra rotmappen `iac-storage`:

### Dev

```bash
terraform -chdir=terraform init \
  -backend-config="../environments/dev/backend.hcl"

terraform -chdir=terraform plan \
  -var-file="../environments/dev/dev.tfvars"

terraform -chdir=terraform apply \
  -var-file="../environments/dev/dev.tfvars"

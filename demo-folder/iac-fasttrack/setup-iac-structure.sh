#!/usr/bin/env bash

# Oppretter rotmappe
ROOT="iac-storage"
mkdir -p "$ROOT"

echo "Oppretter mappe: $ROOT"

# Oppretter Terraform-rootmodul
mkdir -p "$ROOT/terraform"

# Oppretter miljømapper
mkdir -p "$ROOT/environments"
mkdir -p "$ROOT/backends"

###############################################
# Oppretter Terraform-filer i terraform/
###############################################

cat <<EOF > "$ROOT/terraform/versions.tf"
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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
}

variable "storage_account_replication_type" {
  type        = string
  default     = "LRS"
}

variable "container_name" {
  type        = string
  description = "Name of the blob container."
}

variable "environment" {
  type        = string
  description = "Environment name (dev/test/prod)."
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
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "container_name" {
  value = azurerm_storage_container.this.name
}
EOF

###############################################
# Miljøspesifikke tfvars-filer
###############################################

cat <<EOF > "$ROOT/environments/dev.tfvars"
location                   = "northeurope"
resource_group_name        = "rg-storage-dev"
storage_account_name       = "stdev$RANDOM"
storage_account_tier       = "Standard"
storage_account_replication_type = "LRS"
container_name             = "appdata-dev"
environment                = "dev"
EOF

cat <<EOF > "$ROOT/environments/test.tfvars"
location                   = "northeurope"
resource_group_name        = "rg-storage-test"
storage_account_name       = "sttest$RANDOM"
storage_account_tier       = "Standard"
storage_account_replication_type = "LRS"
container_name             = "appdata-test"
environment                = "test"
EOF

cat <<EOF > "$ROOT/environments/prod.tfvars"
location                   = "northeurope"
resource_group_name        = "rg-storage-prod"
storage_account_name       = "stprod$RANDOM"
storage_account_tier       = "Standard"
storage_account_replication_type = "GRS"
container_name             = "appdata-prod"
environment                = "prod"
EOF

###############################################
# Backend-konfigurasjoner for dev/test/prod
###############################################

cat <<EOF > "$ROOT/backends/backend-dev.hcl"
resource_group_name  = "rg-iac-state"
storage_account_name = "staciacstate001"
container_name       = "tfstate"
key                  = "storage/dev/terraform.tfstate"
EOF

cat <<EOF > "$ROOT/backends/backend-test.hcl"
resource_group_name  = "rg-iac-state"
storage_account_name = "staciacstate001"
container_name       = "tfstate"
key                  = "storage/test/terraform.tfstate"
EOF

cat <<EOF > "$ROOT/backends/backend-prod.hcl"
resource_group_name  = "rg-iac-state"
storage_account_name = "staciacstate001"
container_name       = "tfstate"
key                  = "storage/prod/terraform.tfstate"
EOF

###############################################
# Avslutning
###############################################

echo "-----------------------------------------------------"
echo "Ferdig!"
echo "Oppsettet ble generert i mappen: $ROOT"
echo "Klar til å brukes med:"
echo "  terraform -chdir=terraform init -backend-config=../backends/backend-dev.hcl"
echo "  terraform -chdir=terraform plan -var-file=../environments/dev.tfvars"
echo "-----------------------------------------------------"

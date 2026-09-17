terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "a3adf20e-4966-4afb-b717-4de1baae6db1"
  use_cli         = true # Bruker pålogging via `az login`
}

# Ressursgruppe
resource "azurerm_resource_group" "rg" {
  name     = "rg-tfstate-tim"
  location = "westeurope"

  tags = {
    keep      = "true"
    owner     = "tim"
    purpose   = "terraform-backend"
    managedby = "terraform"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Storage Account
resource "azurerm_storage_account" "sa" {
  name                            = "sttfstatetim123" # må være globalt unikt
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
}

# Container for state files
resource "azurerm_storage_container" "sc" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

# Hent innlogget bruker fra Entra ID
data "azurerm_client_config" "current" {}

# Tildel data-rolle til innlogget bruker på STORAGE-KONTO-nivå
# Dette dekker både listing av containere og listing/lesing/skriving av blobs.
resource "azurerm_role_assignment" "blob_contrib_self_account_scope" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"

  # Sørg for at kontoen er ferdig opprettet før RBAC forsøkes
  depends_on = [
    azurerm_storage_account.sa,
    azurerm_storage_container.sc
  ]
}

variable "pipeline_service_principal_id" {
  description = "Object ID of the service principal used by the pipeline"
  type        = string
  default     = "ee1b75f1-dd0a-4cef-92ec-7b124a2eafed" # Placeholder, replace with actual SP object ID
}

resource "azurerm_role_assignment" "pipeline_blob_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.pipeline_service_principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [
    azurerm_storage_account.sa,
    azurerm_storage_container.sc
  ]
}

# ---------------------------------------------------------------------------
#  Key Vault – kilden til parameterfilene
# ---------------------------------------------------------------------------
variable "kvname" {
  description = "Name of the Key Vault"
  type        = string
  default     = "kv-tfstate-tim"
}

resource "azurerm_key_vault" "kv" {
  name                       = substr(lower("kv-tf-${var.kvname}${random_string.suffix.result}"), 0, 24)
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  rbac_authorization_enabled = true
  sku_name                   = "standard"
  purge_protection_enabled   = false
}

resource "azurerm_role_assignment" "kv_officer_meg" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_role_assignment" "kv_user_pipeline" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.pipeline_service_principal_id
  principal_type       = "ServicePrincipal"
}

output "keyvault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Legges inn som environment secret KEYVAULT_NAME i GitHub."
}
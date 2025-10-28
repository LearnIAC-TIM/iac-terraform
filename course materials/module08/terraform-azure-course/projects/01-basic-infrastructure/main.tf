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
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

# Storage Container
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Key Vault (valgfri - fjern kommentar for å aktivere)
# resource "azurerm_key_vault" "main" {
#   name                       = "kv-${var.student_name}-${var.environment}"
#   resource_group_name        = azurerm_resource_group.main.name
#   location                   = azurerm_resource_group.main.location
#   tenant_id                  = data.azurerm_client_config.current.tenant_id
#   sku_name                   = "standard"
#   soft_delete_retention_days = 7
#   purge_protection_enabled   = false  # For test-miljø
#   
#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id
#     
#     secret_permissions = ["Get", "List", "Set", "Delete"]
#   }
#   
#   tags = var.tags
# }

# Key Vault Secret - lagrer storage connection string
# resource "azurerm_key_vault_secret" "connection_string" {
#   name         = "storage-connection-string"
#   value        = azurerm_storage_account.main.primary_connection_string
#   key_vault_id = azurerm_key_vault.main.id
# }

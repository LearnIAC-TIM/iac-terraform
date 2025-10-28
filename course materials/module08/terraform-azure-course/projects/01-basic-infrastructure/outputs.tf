output "resource_group_name" {
  description = "Navn på resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID til resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location for resource group"
  value       = azurerm_resource_group.main.location
}

output "storage_account_name" {
  description = "Navn på storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID til storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_container_name" {
  description = "Navn på storage container"
  value       = azurerm_storage_container.data.name
}

# Uncomment hvis Key Vault er aktivert
# output "key_vault_name" {
#   description = "Navn på Key Vault"
#   value       = azurerm_key_vault.main.name
# }

# output "key_vault_uri" {
#   description = "URI til Key Vault"
#   value       = azurerm_key_vault.main.vault_uri
# }

output "resource_group_name" {
  description = "Navn på Resource Group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Navn på Storage Account"
  value       = azurerm_storage_account.tfstate.name
}

output "storage_account_primary_access_key" {
  description = "Primary access key for Storage Account (bruk med forsiktighet!)"
  value       = azurerm_storage_account.tfstate.primary_access_key
  sensitive   = true
}

output "container_name" {
  description = "Navn på container for Terraform state"
  value       = azurerm_storage_container.tfstate.name
}

output "key_vault_name" {
  description = "Navn på Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI til Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "backend_config" {
  description = "Backend konfigurasjon for studenter å bruke i sine Terraform prosjekter"
  value       = <<-EOT
  
  # Legg denne backend konfigurasjonen i dine Terraform prosjekter:
  terraform {
    backend "azurerm" {
      resource_group_name  = "${azurerm_resource_group.main.name}"
      storage_account_name = "${azurerm_storage_account.tfstate.name}"
      container_name       = "${azurerm_storage_container.tfstate.name}"
      key                  = "terraform.tfstate"
    }
  }
  EOT
}
output "keyvault_name" {
  value = azurerm_key_vault.demo.name
}

# Lim inn i ../backend.hcl
output "backend_hcl" {
  value = <<-EOT
    resource_group_name  = "${azurerm_resource_group.backend.name}"
    storage_account_name = "${azurerm_storage_account.state.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    use_azuread_auth     = true
  EOT
}

output "backend_resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "backend_storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "backend_container_name" {
  value = azurerm_storage_container.tfstate.name
}

output "backend_hcl_template" {
  value = <<EOT
resource_group_name  = "${azurerm_resource_group.rg.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name       = "${azurerm_storage_container.tfstate.name}"
use_azuread_auth     = true
use_cli              = true
EOT
}

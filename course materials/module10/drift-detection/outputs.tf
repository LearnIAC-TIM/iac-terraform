output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "web_app_url" {
  value = azurerm_linux_web_app.main.default_hostname
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "application_insights_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}
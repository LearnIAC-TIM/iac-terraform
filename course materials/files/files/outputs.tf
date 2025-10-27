output "resource_group_name" {
  value       = azurerm_resource_group.lab.name
  description = "Resource Group navn"
}

output "app_service_name" {
  value       = azurerm_linux_web_app.lab.name
  description = "Web App navn"
}

output "production_url" {
  value       = "https://${azurerm_linux_web_app.lab.default_hostname}"
  description = "Production URL"
}

output "staging_url" {
  value       = "https://${azurerm_linux_web_app_slot.staging.default_hostname}"
  description = "Staging URL"
}

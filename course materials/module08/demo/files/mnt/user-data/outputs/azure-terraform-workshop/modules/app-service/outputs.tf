# App Service Module Outputs

output "app_service_plan_id" {
  description = "App Service Plan ID"
  value       = azurerm_service_plan.main.id
}

output "app_service_plan_name" {
  description = "App Service Plan navn"
  value       = azurerm_service_plan.main.name
}

output "app_service_id" {
  description = "App Service ID"
  value       = azurerm_linux_web_app.main.id
}

output "app_service_name" {
  description = "App Service navn"
  value       = azurerm_linux_web_app.main.name
}

output "app_service_default_hostname" {
  description = "App Service default hostname"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "app_service_outbound_ip_addresses" {
  description = "App Service outbound IP addresses"
  value       = azurerm_linux_web_app.main.outbound_ip_addresses
}

output "app_service_possible_outbound_ip_addresses" {
  description = "App Service possible outbound IP addresses"
  value       = azurerm_linux_web_app.main.possible_outbound_ip_addresses
}

output "principal_id" {
  description = "Managed Identity Principal ID"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

output "tenant_id" {
  description = "Managed Identity Tenant ID"
  value       = azurerm_linux_web_app.main.identity[0].tenant_id
}

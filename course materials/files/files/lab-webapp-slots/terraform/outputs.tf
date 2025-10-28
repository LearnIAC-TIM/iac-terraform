output "webapp_name" {
  description = "Navn på Web App"
  value       = azurerm_linux_web_app.lab.name
}

output "webapp_url" {
  description = "URL til production slot"
  value       = "https://${azurerm_linux_web_app.lab.default_hostname}"
}

output "staging_url" {
  description = "URL til staging slot"
  value       = "https://${azurerm_linux_web_app.lab.name}-staging.azurewebsites.net"
}

output "resource_group_name" {
  description = "Resource group navn"
  value       = azurerm_resource_group.lab.name
}

# Networking Module Outputs

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual Network navn"
  value       = azurerm_virtual_network.main.name
}

output "app_subnet_id" {
  description = "App Service subnet ID"
  value       = azurerm_subnet.app.id
}

output "app_subnet_name" {
  description = "App Service subnet navn"
  value       = azurerm_subnet.app.name
}

output "db_subnet_id" {
  description = "Database subnet ID"
  value       = azurerm_subnet.db.id
}

output "db_subnet_name" {
  description = "Database subnet navn"
  value       = azurerm_subnet.db.name
}

output "app_nsg_id" {
  description = "App Service NSG ID"
  value       = azurerm_network_security_group.app.id
}

output "db_nsg_id" {
  description = "Database NSG ID"
  value       = azurerm_network_security_group.db.id
}

output "db_private_dns_zone_id" {
  description = "PostgreSQL Private DNS Zone ID"
  value       = azurerm_private_dns_zone.postgres.id
}

output "db_private_dns_zone_name" {
  description = "PostgreSQL Private DNS Zone navn"
  value       = azurerm_private_dns_zone.postgres.name
}

# Database Module Outputs

output "server_id" {
  description = "PostgreSQL Server ID"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  description = "PostgreSQL Server navn"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  description = "PostgreSQL Server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
  sensitive   = true
}

output "database_name" {
  description = "Database navn"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "database_id" {
  description = "Database ID"
  value       = azurerm_postgresql_flexible_server_database.main.id
}

output "admin_username" {
  description = "Database admin username"
  value       = var.admin_username
  sensitive   = true
}

output "connection_string_secret_name" {
  description = "Key Vault secret navn for connection string"
  value       = azurerm_key_vault_secret.connection_string.name
}

output "connection_string_secret_uri" {
  description = "Key Vault secret URI for connection string"
  value       = azurerm_key_vault_secret.connection_string.versionless_id
  sensitive   = true
}

output "connection_string_uri_secret_name" {
  description = "Key Vault secret navn for URI-format connection string"
  value       = azurerm_key_vault_secret.connection_string_uri.name
}

output "db_fqdn_secret_name" {
  description = "Key Vault secret navn for database FQDN"
  value       = azurerm_key_vault_secret.db_fqdn.name
}

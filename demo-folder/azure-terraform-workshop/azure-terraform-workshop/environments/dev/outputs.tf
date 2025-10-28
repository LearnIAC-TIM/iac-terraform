# Outputs for Dev Environment
# Disse verdiene blir tilgjengelige etter terraform apply

# ============================================
# General Information
# ============================================

output "resource_group_name" {
  description = "Resource Group hvor ressursene er deployet"
  value       = data.azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region"
  value       = var.location
}

output "environment" {
  description = "Miljønavn"
  value       = var.environment
}

# ============================================
# Networking Outputs
# ============================================

output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Virtual Network navn"
  value       = module.networking.vnet_name
}

output "app_subnet_id" {
  description = "App Service subnet ID"
  value       = module.networking.app_subnet_id
}

output "db_subnet_id" {
  description = "Database subnet ID"
  value       = module.networking.db_subnet_id
}

# ============================================
# App Service Outputs
# ============================================

output "app_service_name" {
  description = "App Service navn"
  value       = module.app_service.app_service_name
}

output "app_service_hostname" {
  description = "App Service default hostname"
  value       = module.app_service.app_service_default_hostname
}

output "app_service_url" {
  description = "App Service URL"
  value       = "https://${module.app_service.app_service_default_hostname}"
}

output "app_service_identity_principal_id" {
  description = "App Service Managed Identity Principal ID"
  value       = module.app_service.principal_id
}

# ============================================
# Database Outputs
# ============================================

output "database_server_name" {
  description = "PostgreSQL Server navn"
  value       = module.database.server_name
}

output "database_server_fqdn" {
  description = "PostgreSQL Server FQDN"
  value       = module.database.server_fqdn
  sensitive   = true
}

output "database_name" {
  description = "Database navn"
  value       = module.database.database_name
}

output "database_admin_username" {
  description = "Database admin username"
  value       = module.database.admin_username
  sensitive   = true
}

output "database_connection_string_secret_name" {
  description = "Key Vault secret navn for database connection string"
  value       = module.database.connection_string_secret_name
}

# ============================================
# Monitoring Outputs
# ============================================

output "application_insights_name" {
  description = "Application Insights navn"
  value       = module.monitoring.app_insights_name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = module.monitoring.app_insights_instrumentation_key
  sensitive   = true
}

output "application_insights_app_id" {
  description = "Application Insights App ID"
  value       = module.monitoring.app_insights_app_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

# ============================================
# Key Vault Outputs
# ============================================

output "key_vault_name" {
  description = "Key Vault navn"
  value       = data.azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = data.azurerm_key_vault.main.vault_uri
}

# ============================================
# Quick Access Commands
# ============================================

output "quick_commands" {
  description = "Nyttige kommandoer for å jobbe med infrastrukturen"
  value = <<-EOT
    
    🚀 Quick Access Commands:
    
    # Åpne Web App i browser
    az webapp browse --name ${module.app_service.app_service_name} --resource-group ${data.azurerm_resource_group.main.name}
    
    # Koble til database
    az postgres flexible-server connect --name ${module.database.server_name} --admin-user ${module.database.admin_username} --database-name ${module.database.database_name}
    
    # Se App Service logs
    az webapp log tail --name ${module.app_service.app_service_name} --resource-group ${data.azurerm_resource_group.main.name}
    
    # Restart Web App
    az webapp restart --name ${module.app_service.app_service_name} --resource-group ${data.azurerm_resource_group.main.name}
    
    # Åpne Application Insights i portal
    az monitor app-insights component show --app ${module.monitoring.app_insights_name} --resource-group ${data.azurerm_resource_group.main.name}
    
    # Hent connection string fra Key Vault
    az keyvault secret show --vault-name ${data.azurerm_key_vault.main.name} --name ${module.database.connection_string_secret_name} --query value -o tsv
    
  EOT
}

# ============================================
# Summary
# ============================================

output "deployment_summary" {
  description = "Oppsummering av deployment"
  value = {
    app_url              = "https://${module.app_service.app_service_default_hostname}"
    database_server      = module.database.server_name
    monitoring_enabled   = true
    vnet_enabled         = true
    managed_identity     = true
    key_vault_integration = true
  }
}

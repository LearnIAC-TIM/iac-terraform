# Monitoring Module Outputs

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace navn"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_workspace_id" {
  description = "Log Analytics Workspace Workspace ID (GUID)"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_analytics_workspace_primary_shared_key" {
  description = "Log Analytics Workspace primary shared key"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "app_insights_id" {
  description = "Application Insights ID"
  value       = azurerm_application_insights.main.id
}

output "app_insights_name" {
  description = "Application Insights navn"
  value       = azurerm_application_insights.main.name
}

output "app_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights Connection String"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "app_insights_app_id" {
  description = "Application Insights App ID"
  value       = azurerm_application_insights.main.app_id
}

output "action_group_id" {
  description = "Monitor Action Group ID"
  value       = azurerm_monitor_action_group.main.id
}

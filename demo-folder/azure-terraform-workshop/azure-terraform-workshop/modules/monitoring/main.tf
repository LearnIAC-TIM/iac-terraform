# Monitoring Module
# Oppretter Application Insights og Log Analytics Workspace for monitoring og logging

# ============================================
# Log Analytics Workspace
# ============================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-law-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # Retention
  retention_in_days = var.retention_in_days
  
  # SKU
  sku = "PerGB2018"
  
  tags = var.tags
}

# ============================================
# Application Insights
# ============================================

resource "azurerm_application_insights" "main" {
  name                = "${var.name_prefix}-appi-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # Application type
  application_type = "web"
  
  # Link to Log Analytics Workspace
  workspace_id = azurerm_log_analytics_workspace.main.id
  
  # Retention (application-specific)
  retention_in_days = var.retention_in_days
  
  # Sampling (for høy-volum apps)
  sampling_percentage = 100  # 100% = ingen sampling
  
  tags = var.tags
}

# ============================================
# Alert Rules (valgfritt)
# ============================================

# Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${var.name_prefix}-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "AlertAG"
  
  # Email notification (legg til etter behov)
  # email_receiver {
  #   name          = "sendtoadmin"
  #   email_address = "admin@example.com"
  # }
  
  tags = var.tags
}

# High response time alert
resource "azurerm_monitor_metric_alert" "response_time" {
  name                = "${var.name_prefix}-high-response-time"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert når response time er over 3 sekunder"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  
  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "requests/duration"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 3000  # 3 sekunder i millisekunder
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = var.tags
}

# Failed requests alert
resource "azurerm_monitor_metric_alert" "failed_requests" {
  name                = "${var.name_prefix}-high-failed-requests"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert når failed requests rate er høy"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  
  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "requests/failed"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 10
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = var.tags
}

# ============================================
# Log Analytics Solutions (valgfritt)
# ============================================

# Container insights (hvis du bruker containers)
# resource "azurerm_log_analytics_solution" "container_insights" {
#   solution_name         = "ContainerInsights"
#   location              = var.location
#   resource_group_name   = var.resource_group_name
#   workspace_resource_id = azurerm_log_analytics_workspace.main.id
#   workspace_name        = azurerm_log_analytics_workspace.main.name
#   
#   plan {
#     publisher = "Microsoft"
#     product   = "OMSGallery/ContainerInsights"
#   }
#   
#   tags = var.tags
# }

# ============================================
# Diagnostic Settings for Log Analytics (valgfritt)
# ============================================

# Dette kan brukes for å sende logs fra andre ressurser til Log Analytics
# Eksempel: Send App Service logs til Log Analytics
# resource "azurerm_monitor_diagnostic_setting" "app_service" {
#   name                       = "app-service-diagnostics"
#   target_resource_id         = var.app_service_id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
#   
#   enabled_log {
#     category = "AppServiceHTTPLogs"
#   }
#   
#   enabled_log {
#     category = "AppServiceConsoleLogs"
#   }
#   
#   metric {
#     category = "AllMetrics"
#   }
# }

# App Service Module
# Oppretter App Service Plan og Web App med Managed Identity og VNet integration

# ============================================
# App Service Plan
# ============================================

resource "azurerm_service_plan" "main" {
  name                = "${var.name_prefix}-asp-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # Linux-basert plan
  os_type  = "Linux"
  sku_name = var.app_service_sku
  
  # Worker count (kan justeres for scaling)
  worker_count = 1
  
  tags = var.tags
}

# ============================================
# Linux Web App
# ============================================

resource "azurerm_linux_web_app" "main" {
  name                = "${var.name_prefix}-app-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  
  # HTTPS kun
  https_only = true
  
  # Site configuration
  site_config {
    # Always on (holder appen våken)
    always_on = var.app_service_sku != "F1" && var.app_service_sku != "D1" ? true : false
    
    # Runtime stack configuration
    application_stack {
      # Dynamisk runtime stack basert på variabel
      # Node.js
      node_version = var.app_runtime_stack == "node" ? var.app_runtime_version : null
      
      # Python
      python_version = var.app_runtime_stack == "python" ? var.app_runtime_version : null
      
      # .NET
      dotnet_version = var.app_runtime_stack == "dotnet" ? var.app_runtime_version : null
      
      # Java
      java_version = var.app_runtime_stack == "java" ? var.app_runtime_version : null
      
      # PHP
      php_version = var.app_runtime_stack == "php" ? var.app_runtime_version : null
    }
    
    # Health check
    health_check_path = var.health_check_path
    
    # HTTP2
    http2_enabled = true
    
    # Minimum TLS version
    minimum_tls_version = "1.2"
    
    # FTP
    ftps_state = "FtpsOnly"
    
    # Logging
    detailed_error_logging_enabled = true
    http_logging_enabled           = true
  }
  
  # App Settings (Environment Variables)
  app_settings = var.app_settings
  
  # Managed Identity (System-assigned)
  identity {
    type = "SystemAssigned"
  }
  
  # Logs configuration
  logs {
    application_logs {
      file_system_level = "Information"
    }
    
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
  
  tags = var.tags
}

# ============================================
# VNet Integration
# ============================================

resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_linux_web_app.main.id
  subnet_id      = var.subnet_id
}

# ============================================
# Key Vault Access for Managed Identity
# ============================================

# Grant Web App's Managed Identity access to Key Vault
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = var.key_vault_id
  tenant_id    = azurerm_linux_web_app.main.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.main.identity[0].principal_id
  
  secret_permissions = [
    "Get",
    "List"
  ]
}

# ============================================
# Deployment Slot (for Blue-Green deployments) - Valgfritt
# ============================================

# Uncomment for å aktivere staging slot
# resource "azurerm_linux_web_app_slot" "staging" {
#   name           = "staging"
#   app_service_id = azurerm_linux_web_app.main.id
#   
#   site_config {
#     always_on = true
#     
#     application_stack {
#       node_version = var.app_runtime_stack == "node" ? var.app_runtime_version : null
#       python_version = var.app_runtime_stack == "python" ? var.app_runtime_version : null
#     }
#   }
#   
#   app_settings = var.app_settings
#   
#   identity {
#     type = "SystemAssigned"
#   }
#   
#   tags = var.tags
# }

# ============================================
# Auto-scaling (valgfritt for produksjon)
# ============================================

# resource "azurerm_monitor_autoscale_setting" "main" {
#   name                = "${var.name_prefix}-autoscale"
#   resource_group_name = var.resource_group_name
#   location            = var.location
#   target_resource_id  = azurerm_service_plan.main.id
#   
#   profile {
#     name = "defaultProfile"
#     
#     capacity {
#       default = 1
#       minimum = 1
#       maximum = 3
#     }
#     
#     rule {
#       metric_trigger {
#         metric_name        = "CpuPercentage"
#         metric_resource_id = azurerm_service_plan.main.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "GreaterThan"
#         threshold          = 70
#       }
#       
#       scale_action {
#         direction = "Increase"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT5M"
#       }
#     }
#     
#     rule {
#       metric_trigger {
#         metric_name        = "CpuPercentage"
#         metric_resource_id = azurerm_service_plan.main.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "LessThan"
#         threshold          = 30
#       }
#       
#       scale_action {
#         direction = "Decrease"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT5M"
#       }
#     }
#   }
#   
#   tags = var.tags
# }

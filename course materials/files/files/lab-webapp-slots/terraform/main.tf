terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.location

  tags = var.required_tags
}

# App Service Plan (Linux)
resource "azurerm_service_plan" "lab" {
  name                = "${var.prefix}-asp"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier for kostnadseffektivitet

  tags = var.required_tags
}

# Web App
resource "azurerm_linux_web_app" "lab" {
  name                = "${var.prefix}-webapp-${var.environment}"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  service_plan_id     = azurerm_service_plan.lab.id

  # Sikkerhetskonfigurasjon
  https_only = true

  site_config {
    minimum_tls_version = "1.2"
    
    application_stack {
      python_version = "3.11"
    }

    # Health check
    health_check_path = "/health"
  }

  app_settings = {
    "ENVIRONMENT"      = "production"
    "FEATURE_TOGGLE_X" = "false"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  # FTP deaktivert for sikkerhet
  ftp_publish_basic_authentication_enabled = false
  
  tags = var.required_tags
}

# Staging Slot
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.lab.id

  https_only = true

  site_config {
    minimum_tls_version = "1.2"
    
    application_stack {
      python_version = "3.11"
    }

    health_check_path = "/health"
  }

  app_settings = {
    "ENVIRONMENT"      = "staging"
    "FEATURE_TOGGLE_X" = "true"  # Feature toggle aktivert i staging
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  ftp_publish_basic_authentication_enabled = false

  tags = merge(var.required_tags, {
    Slot = "staging"
  })
}

terraform {
  required_version = ">= 1.0"
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

resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.location
  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

resource "azurerm_service_plan" "lab" {
  name                = "${var.app_name}-plan"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "lab" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  service_plan_id     = azurerm_service_plan.lab.id
  https_only          = true

  site_config {
    minimum_tls_version = "1.2"
    always_on           = true
    application_stack {
      node_version = "18-lts"
    }
    health_check_path = "/health"
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "18-lts"
    "SLOT_NAME"                    = "production"
    "FEATURE_TOGGLE_NEW_UI"        = "false"
  }

  tags = var.tags
}

resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.lab.id
  https_only     = true

  site_config {
    minimum_tls_version = "1.2"
    always_on           = true
    application_stack {
      node_version = "18-lts"
    }
    health_check_path = "/health"
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "18-lts"
    "SLOT_NAME"                    = "staging"
    "FEATURE_TOGGLE_NEW_UI"        = "true"
  }

  tags = var.tags
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-demo-backend-tim"
    storage_account_name = "sademobackendtim"
    container_name       = "tfstate"
    key                  = "drift-detection.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Random string for storage account name
resource "random_string" "storage_account_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

# Local variables for naming convention
locals {
  # Base names using student prefix
  base_name = lower(var.student_name)

  # Resource specific names
  rg_name              = "${local.base_name}-${var.environment}-rg"
  app_service_plan     = "${local.base_name}-${var.environment}-asp"
  web_app_name         = "${local.base_name}-${var.environment}-webapp"
  storage_account_name = "${local.base_name}${random_string.storage_account_suffix.result}"
  app_insights_name    = "${local.base_name}-${var.environment}-appins"

  # Common tags
  common_tags = {
    environment = var.environment
    owner       = var.student_name
    cost-center = var.cost_center
    created-by  = "terraform"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.location

  tags = local.common_tags
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = local.app_service_plan
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"

  tags = local.common_tags
}

# Web App
resource "azurerm_linux_web_app" "main" {
  name                = local.web_app_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      node_version = "20-lts"
    }
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~20"
    "ENVIRONMENT"                  = var.environment
    "NODE_ENV"                     = var.environment
  }

  tags = local.common_tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = local.common_tags
}
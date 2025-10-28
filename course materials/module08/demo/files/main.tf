# Main Terraform Configuration - Dev Environment
# Dette er root module som orkestrerer alle sub-modules

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  # Bruk OIDC for authentication (federated credentials fra GitHub Actions)
  use_oidc = true
  
  # Subscription ID settes via variabel eller environment variable
  subscription_id = var.subscription_id
}

# Data source for eksisterende Resource Group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Data source for eksisterende Key Vault
data "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

# Data source for current client (for Key Vault access)
data "azurerm_client_config" "current" {}

# Random suffix for å unngå navnekollisjoner
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Locals for naming consistency
locals {
  # Naming convention: {project}-{environment}-{resource}-{suffix}
  name_prefix = "${var.project_name}-${var.environment}"
  name_suffix = random_string.suffix.result
  
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedDate = timestamp()
    }
  )
}

# ============================================
# Networking Module
# ============================================
module "networking" {
  source = "../../modules/networking"
  
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  name_prefix         = local.name_prefix
  name_suffix         = local.name_suffix
  
  vnet_address_space      = var.vnet_address_space
  app_subnet_address      = var.app_subnet_address
  db_subnet_address       = var.db_subnet_address
  
  tags = local.common_tags
}

# ============================================
# Database Module (PostgreSQL Flexible Server)
# ============================================
module "database" {
  source = "../../modules/database"
  
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  name_prefix         = local.name_prefix
  name_suffix         = local.name_suffix
  
  # Database configuration
  database_sku            = var.database_sku
  database_storage_mb     = var.database_storage_mb
  database_version        = var.database_version
  database_name           = var.database_name
  
  # Admin credentials - lagres i Key Vault
  admin_username = var.database_admin_username
  admin_password = var.database_admin_password
  
  # Networking
  delegated_subnet_id     = module.networking.db_subnet_id
  private_dns_zone_id     = module.networking.db_private_dns_zone_id
  
  # Backup og HA
  backup_retention_days   = var.database_backup_retention_days
  geo_redundant_backup    = var.database_geo_redundant_backup
  
  # Key Vault for storing connection string
  key_vault_id = data.azurerm_key_vault.main.id
  
  tags = local.common_tags
  
  depends_on = [module.networking]
}

# ============================================
# App Service Module
# ============================================
module "app_service" {
  source = "../../modules/app-service"
  
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  name_prefix         = local.name_prefix
  name_suffix         = local.name_suffix
  
  # App Service Plan configuration
  app_service_sku = var.app_service_sku
  
  # Web App configuration
  app_runtime_stack    = var.app_runtime_stack
  app_runtime_version  = var.app_runtime_version
  
  # Environment variables for app
  app_settings = merge(
    var.app_settings,
    {
      "ENVIRONMENT"                   = var.environment
      "DATABASE_CONNECTION_STRING"    = "@Microsoft.KeyVault(SecretUri=${module.database.connection_string_secret_uri})"
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.monitoring.app_insights_connection_string
    }
  )
  
  # Networking
  subnet_id = module.networking.app_subnet_id
  
  # Key Vault access for Managed Identity
  key_vault_id = data.azurerm_key_vault.main.id
  
  # Health check
  health_check_path = var.health_check_path
  
  tags = local.common_tags
  
  depends_on = [
    module.networking,
    module.database,
    module.monitoring
  ]
}

# ============================================
# Monitoring Module (Application Insights)
# ============================================
module "monitoring" {
  source = "../../modules/monitoring"
  
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  name_prefix         = local.name_prefix
  name_suffix         = local.name_suffix
  
  # Log Analytics Workspace configuration
  retention_in_days = var.log_retention_days
  
  tags = local.common_tags
}

# ============================================
# Key Vault Secrets
# ============================================

# Lagre database admin password i Key Vault
resource "azurerm_key_vault_secret" "db_admin_password" {
  name         = "db-admin-password"
  value        = var.database_admin_password
  key_vault_id = data.azurerm_key_vault.main.id
  
  tags = local.common_tags
}

# Grant App Service access to Key Vault
resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = data.azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.app_service.principal_id
  
  secret_permissions = [
    "Get",
    "List"
  ]
}

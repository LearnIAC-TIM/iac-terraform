# Variables for Dev Environment

# ============================================
# Azure Configuration
# ============================================

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Navn på eksisterende Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region hvor ressurser skal deployes"
  type        = string
  default     = "norwayeast"
  
  validation {
    condition     = contains(["norwayeast", "norwaywest", "westeurope", "northeurope"], var.location)
    error_message = "Location må være en av: norwayeast, norwaywest, westeurope, northeurope."
  }
}

# ============================================
# Existing Resources
# ============================================

variable "key_vault_name" {
  description = "Navn på eksisterende Key Vault"
  type        = string
}

# ============================================
# Project Configuration
# ============================================

variable "project_name" {
  description = "Prosjektnavn brukt som prefix for alle ressurser"
  type        = string
  
  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 12
    error_message = "Project name må være mellom 3 og 12 tegn."
  }
}

variable "environment" {
  description = "Miljønavn (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment må være en av: dev, staging, prod."
  }
}

variable "tags" {
  description = "Tilleggs-tags for alle ressurser"
  type        = map(string)
  default     = {}
}

# ============================================
# Networking Configuration
# ============================================

variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_subnet_address" {
  description = "Address prefix for App Service subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "db_subnet_address" {
  description = "Address prefix for Database subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

# ============================================
# App Service Configuration
# ============================================

variable "app_service_sku" {
  description = "SKU for App Service Plan (B1, B2, S1, S2, P1v2, P2v2)"
  type        = string
  default     = "B1"
  
  validation {
    condition     = contains(["B1", "B2", "S1", "S2", "P1v2", "P2v2", "P3v2"], var.app_service_sku)
    error_message = "App Service SKU må være en gyldig SKU."
  }
}

variable "app_runtime_stack" {
  description = "Runtime stack for web app (node, python, dotnet, java)"
  type        = string
  default     = "node"
  
  validation {
    condition     = contains(["node", "python", "dotnet", "java", "php"], var.app_runtime_stack)
    error_message = "Runtime stack må være en av: node, python, dotnet, java, php."
  }
}

variable "app_runtime_version" {
  description = "Runtime version (eks: '18-lts' for Node, '3.11' for Python)"
  type        = string
  default     = "18-lts"
}

variable "app_settings" {
  description = "Tilleggs environment variables for web app"
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
  default     = "/"
}

# ============================================
# Database Configuration
# ============================================

variable "database_sku" {
  description = "SKU for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"
  
  validation {
    condition     = can(regex("^(B|GP|MO)_Standard_", var.database_sku))
    error_message = "Database SKU må være en gyldig PostgreSQL Flexible Server SKU."
  }
}

variable "database_storage_mb" {
  description = "Storage size i MB for database (minimum 32768 MB = 32 GB)"
  type        = number
  default     = 32768
  
  validation {
    condition     = var.database_storage_mb >= 32768
    error_message = "Database storage må være minimum 32768 MB (32 GB)."
  }
}

variable "database_version" {
  description = "PostgreSQL versjon"
  type        = string
  default     = "14"
  
  validation {
    condition     = contains(["11", "12", "13", "14", "15"], var.database_version)
    error_message = "Database version må være 11, 12, 13, 14 eller 15."
  }
}

variable "database_name" {
  description = "Navn på database som skal opprettes"
  type        = string
  default     = "appdb"
}

variable "database_admin_username" {
  description = "Admin brukernavn for database"
  type        = string
  default     = "dbadmin"
  
  validation {
    condition     = length(var.database_admin_username) >= 3
    error_message = "Admin username må være minimum 3 tegn."
  }
}

variable "database_admin_password" {
  description = "Admin passord for database (lagres i Key Vault)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.database_admin_password) >= 8
    error_message = "Admin password må være minimum 8 tegn."
  }
}

variable "database_backup_retention_days" {
  description = "Antall dager å beholde backups"
  type        = number
  default     = 7
  
  validation {
    condition     = var.database_backup_retention_days >= 7 && var.database_backup_retention_days <= 35
    error_message = "Backup retention må være mellom 7 og 35 dager."
  }
}

variable "database_geo_redundant_backup" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = false
}

# ============================================
# Monitoring Configuration
# ============================================

variable "log_retention_days" {
  description = "Antall dager å beholde logs i Log Analytics"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.log_retention_days)
    error_message = "Log retention må være en gyldig verdi."
  }
}

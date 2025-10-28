# App Service Module Variables

variable "resource_group_name" {
  description = "Resource Group navn"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for resource naming"
  type        = string
}

variable "app_service_sku" {
  description = "SKU for App Service Plan"
  type        = string
}

variable "app_runtime_stack" {
  description = "Runtime stack (node, python, dotnet, java, php)"
  type        = string
}

variable "app_runtime_version" {
  description = "Runtime version"
  type        = string
}

variable "app_settings" {
  description = "App settings (environment variables)"
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/"
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID for Managed Identity access"
  type        = string
}

variable "tags" {
  description = "Tags for alle ressurser"
  type        = map(string)
  default     = {}
}

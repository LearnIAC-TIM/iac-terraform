# Database Module Variables

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

variable "database_sku" {
  description = "SKU for PostgreSQL Flexible Server"
  type        = string
}

variable "database_storage_mb" {
  description = "Storage size i MB"
  type        = number
}

variable "database_version" {
  description = "PostgreSQL versjon"
  type        = string
}

variable "database_name" {
  description = "Navn på database som skal opprettes"
  type        = string
}

variable "admin_username" {
  description = "Admin brukernavn"
  type        = string
}

variable "admin_password" {
  description = "Admin passord"
  type        = string
  sensitive   = true
}

variable "backup_retention_days" {
  description = "Antall dager å beholde backups"
  type        = number
}

variable "geo_redundant_backup" {
  description = "Enable geo-redundant backup"
  type        = bool
}

variable "delegated_subnet_id" {
  description = "Subnet ID for database (delegated)"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID for PostgreSQL"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID for storing connection strings"
  type        = string
}

variable "tags" {
  description = "Tags for alle ressurser"
  type        = map(string)
  default     = {}
}

# Networking Module Variables

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

variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = list(string)
}

variable "app_subnet_address" {
  description = "Address prefix for App Service subnet"
  type        = list(string)
}

variable "db_subnet_address" {
  description = "Address prefix for Database subnet"
  type        = list(string)
}

variable "tags" {
  description = "Tags for alle ressurser"
  type        = map(string)
  default     = {}
}

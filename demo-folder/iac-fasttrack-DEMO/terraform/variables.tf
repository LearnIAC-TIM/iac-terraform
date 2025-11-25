variable "location" {
  type        = string
  description = "Azure region for the resources."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique name of the Storage Account."
}

variable "storage_account_tier" {
  type        = string
  default     = "Standard"
  description = "The performance tier of the Storage Account."
}

variable "storage_account_replication_type" {
  type        = string
  default     = "LRS"
  description = "The replication type of the Storage Account."
}

variable "container_name" {
  type        = string
  description = "Name of the blob container."
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

# Monitoring Module Variables

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

variable "retention_in_days" {
  description = "Retention period i dager for logs og metrics"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags for alle ressurser"
  type        = map(string)
  default     = {}
}

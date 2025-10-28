variable "prefix" {
  description = "Prefix for alle ressurser"
  type        = string
  default     = "student"
}

variable "resource_group_name" {
  description = "Navn på resource group"
  type        = string
  default     = "rg-webapp-lab"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "norwayeast"
}

variable "environment" {
  description = "Miljø (dev/test/prod)"
  type        = string
  default     = "lab"
}

variable "required_tags" {
  description = "Påkrevde tags for compliance"
  type        = map(string)
  default = {
    Environment = "Lab"
    Project     = "WebAppSlots"
    ManagedBy   = "Terraform"
    CostCenter  = "Education"
  }
}

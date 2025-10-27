variable "resource_group_name" {
  description = "Navn på Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "norwayeast"
}

variable "app_name" {
  description = "Navn på Web App (må være globalt unikt)"
  type        = string
}

variable "sku_name" {
  description = "App Service Plan SKU"
  type        = string
  default     = "B1"
}

variable "environment" {
  description = "Miljø"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags for ressurser"
  type        = map(string)
  default = {
    Project = "WebAppLab"
    Course  = "DevOps"
  }
}

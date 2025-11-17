variable "resource_group_name" {
  description = "Navn på Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region hvor ressursene skal opprettes"
  type        = string
  default     = "norwayeast"
}

variable "storage_account_name" {
  description = "Navn på Storage Account (må være globalt unikt, kun små bokstaver og tall)"
  type        = string
}

variable "container_name" {
  description = "Navn på container for Terraform state filer"
  type        = string
  default     = "tfstate"
}

variable "key_vault_name" {
  description = "Navn på Key Vault (må være globalt unikt)"
  type        = string
}

variable "service_principal_object_id" {
  description = "Object ID for Service Principal i EntraID"
  type        = string
}

variable "user_object_id" {
  description = "Object ID for bruker i EntraID"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources."
  type        = map(string)
  default = {
    purpose   = "tf-backend"
    lifecycle = "platform"
    cleanup   = "exclude"
  }
}
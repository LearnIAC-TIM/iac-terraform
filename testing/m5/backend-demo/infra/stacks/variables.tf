variable "rg_name" {
  type        = string
  description = "Navn på Resource Group opprettet i miljøet."
}

variable "location"     { 
  type = string 
}

variable "environment"  { 
  type = string 
}

variable "name_prefix"  { 
  type = string
  default = "tim" 
  }

variable "vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "tags" {
  type = map(string)
  default = {} 
}

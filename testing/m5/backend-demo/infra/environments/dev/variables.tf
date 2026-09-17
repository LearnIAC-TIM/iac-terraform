variable "environment" { 
  type = string
  default = "dev"
}
variable "location" { 
  type = string
  default = "norwayeast"
}

variable "name_prefix" {
  type    = string
  default = "demo"
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
  type    = map(string)
  default = {}
}

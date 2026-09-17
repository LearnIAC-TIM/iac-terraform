module "network" {
  source         = "../modules/network"
  rg_name        = var.rg_name
  location       = var.location
  environment    = var.environment
  name_prefix    = var.name_prefix
  vnet_cidr      = var.vnet_cidr
  subnet_cidr    = var.subnet_cidr
  tags           = var.tags
}
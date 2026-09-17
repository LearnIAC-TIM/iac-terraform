terraform {
  required_version = ">= 1.6"
  backend "local" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  rg_name = "rg-${var.environment}-${var.name_prefix}"
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

module "stack" {
  source             = "../../stacks"
  rg_name            = azurerm_resource_group.rg.name
  location           = var.location
  environment        = var.environment
  name_prefix        = var.name_prefix
  vnet_cidr          = var.vnet_cidr
  subnet_cidr        = var.subnet_cidr
  tags               = var.tags
}

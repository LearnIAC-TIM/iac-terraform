terraform {
  required_version = ">= 1.12.0"

  backend "azurerm" {
    resource_group_name   = "rg-tfstate-tim"     # << endre
    storage_account_name  = "sttfstatetimdemo123"    # << endre (må være globalt unikt)
    container_name        = "tfstate"             # << endre hvis annet
    key                   = "project/vnet/vnet-project.tfstate"     # navnet på statefila
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "a3adf20e-4966-4afb-b717-4de1baae6db1"
  use_cli = true   # bruker az login (Microsoft Entra ID)
}


# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# VNet
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.address_space
}

terraform {
  required_version = ">= 1.16.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.4"
    }
  }

  # Figur 01: blokka er kommentert ut, og state havner i terraform.tfstate her.
  # Figur 02: fjern kommentaren og kjør
  # terraform init -migrate-state -backend-config=../backend.hcl -backend-config="key=dev/infra.tfstate"
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  # Ingen subscription_id her. Lokalt: az login. I workflowen: ARM_SUBSCRIPTION_ID.
}

resource "azurerm_resource_group" "demo" {
  name     = var.rg_name
  location = var.location

  tags = {
    miljo = "dev"
    endre = "ja" # Endre denne verdien for å ha noe å pushe (figur 03)
    # husk å skriv inn tags for å ta vare på Resource Group
    # keep : true
    # Hvis ikke slettes den av nattlig opprydding
  }
}

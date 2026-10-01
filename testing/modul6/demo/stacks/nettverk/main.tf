# =============================================================================
#  stacks/nettverk/main.tf  –  ÉN definisjon, flere instanser
# -----------------------------------------------------------------------------
#  Dette er environments/dev/nettverk/main.tf fra Oppgave 4, flyttet hit.
#  Innholdet er nesten uendret, og det er selve poenget: koden var aldri
#  problemet. Det var de tre nesten like mappene rundt den.
#
#  Miljønavnet forekommer ikke i noe filnavn eller mappenavn under stacks/
#  (K6). Det kommer inn som en verdi, sammen med resten av parameterne.
# =============================================================================

provider "azurerm" {
  features {}

  # subscription_id er TATT UT siden Oppgave 4.
  #
  # Provideren leter etter ARM_SUBSCRIPTION_ID i miljøet når argumentet ikke
  # er satt. Dermed er det jobben som bestemmer hvilket abonnement koden
  # ruller ut i, ikke koden. Abonnementet er en egenskap ved instansen.

  # Fra azurerm 5.0 defaulter resource_provider_registrations til "none".
  # Denne stacken oppretter nettverksressurser, så Microsoft.Network må stå
  # her – ellers kan apply feile i et abonnement der RP-en ikke er registrert.
  resource_providers_to_register = ["Microsoft.Network"]
}

locals {
  base_name = lower(format("%s-%s-%s", var.project, var.environment, var.shortname))

  tags = {
    environment = var.environment
    owner       = var.shortname
    project     = var.project
    stack       = "nettverk"
    managedby   = "terraform"

    # Ingen keep-tag. Denne ressursgruppa SKAL kunne ryddes bort – både av
    # destroy-workflowen og av den nattlige jobben. Det er bare
    # backend-stacken og Key Vault-et som skal overleve natta.
  }
}

resource "azurerm_resource_group" "rg" {
  name     = format("rg-nett-%s", local.base_name)
  location = var.location
  tags     = local.tags
}

# Modulen er UENDRET fra Oppgave 3 og 4, og ligger fortsatt i modules/network/.
# Stien er en fil-sti på runneren akkurat som på din egen maskin: checkout
# legger hele repoet der, så ../../modules/network peker på det samme begge
# steder.
module "network" {
  source = "../../modules/network"

  rg_name       = azurerm_resource_group.rg.name
  location      = var.location
  base_name     = local.base_name
  address_space = var.address_space
  subnets       = var.subnets
  tags          = local.tags
}

# Test dev, test prod kjeden

resource "azurerm_resource_group" "rg-demo-kjeden" {
  name     = format("rg-testkjeden-%s", local.base_name)
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "rg-demo-kjeden2" {
  name     = format("rg-testkjeden2-%s", local.base_name)
  location = var.location
  tags     = local.tags
}
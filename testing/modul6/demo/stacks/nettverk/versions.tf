# =============================================================================
#  stacks/nettverk/versions.tf  –  VERSJONER OG DEN TOMME BACKEND-BLOKKA
# -----------------------------------------------------------------------------
#  K3 bor i denne fila, og den bor i det som IKKE står her.
# =============================================================================

terraform {
  required_version = ">= 1.16.0"

  # K3: blokka er TOM, og den må likevel stå der.
  #
  # Den velger backend-TYPEN. Sletter du den, faller Terraform tilbake til
  # local-backenden, state havner i mappa på runneren, og INGENTING FEILER –
  # helt til andre kjøring vil opprette alt på nytt.
  #
  # Verdiene kan ikke stå her av to grunner. Den tekniske: backend-blokka
  # godtar ikke variabler, fordi Terraform må vite hvor state ligger før den
  # kan lese noe som helst. Den viktigere: `key` er det eneste som skiller dev
  # fra test. Skriver du den inn, har du bestemt at denne mappa ER dev, og da
  # er du tilbake til én mappe per miljø.
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.4"
    }
  }
}

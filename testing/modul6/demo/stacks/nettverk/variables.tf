# =============================================================================
#  stacks/nettverk/variables.tf
# -----------------------------------------------------------------------------
#  Ingen av variablene har default. Det er et bevisst valg: mangler en verdi,
#  skal kjøringen stoppe med en tydelig feil i stedet for å rulle ut noe som
#  ligner på riktig miljø.
#
#  Med TF_INPUT: false i workflowen feiler Terraform umiddelbart i stedet for
#  å bli stående og vente på et svar ingen kan gi den.
# =============================================================================

variable "shortname" {
  type        = string
  description = "Ditt eget kortnavn. Går inn i alle ressursnavn."
}

variable "project" {
  type        = string
  description = "Prosjektnavn, del av navnegrunnlaget."
}

variable "environment" {
  type        = string
  description = "Miljønavn: dev eller test. Kommer fra parameterfila, ikke fra mappenavnet."

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment må være dev, test eller prod."
  }
}

variable "location" {
  type        = string
  description = "Azure-regionen ressursene opprettes i."
}

variable "address_space" {
  type        = string
  description = "Adresserommet dette miljøet disponerer, som CIDR."
}

variable "subnets" {
  type        = map(number)
  description = "navn => netnum. Nøkkelen er identiteten, netnum er adressen."
}

# =============================================================================
#  stacks/nettverk/outputs.tf
# -----------------------------------------------------------------------------
#  Outputs har fått en ny leser i modul 5. I Oppgave 4 var de et grensesnitt
#  mot app-stacken. Nå leses de også av WORKFLOWEN – verifiseringssteget
#  henter resource_group_name og vnet_name med `terraform output -raw`.
#
#  Det gjør dem til et API med to konsumenter. Døper du en av dem om, feiler
#  ikke stacken din; det er den ANDRE stacken og verifiseringssteget som
#  ryker.
# =============================================================================

output "subnet_ids" {
  value       = module.network.subnet_ids
  description = "Subnet-ID per subnettnavn. LESES AV APP-STACKEN – ikke fjern."
}

output "vnet_name" {
  value       = module.network.vnet_name
  description = "Navnet på det virtuelle nettverket. Leses av verifiseringssteget."
}

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Ressursgruppa stacken eier. Leses av verifiseringssteget."
}

output "subnet_prefixes" {
  value       = module.network.subnet_prefixes
  description = "Utregnet adresseprefiks per subnett. Til feilsøking."
}

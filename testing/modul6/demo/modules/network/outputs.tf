# =============================================================================
#  modules/network/outputs.tf  –  modulens kontrakt ut
# -----------------------------------------------------------------------------
#  En modul er en svart boks: den bestemmer selv hva den deler. Her deler vi
#  akkurat det den som bruker modulen trenger, og ikke noe mer.
# =============================================================================

output "subnet_ids" {
  # K6: dette er et MAP, ikke en liste.
  #
  # Uttrykket leses som en setning: for hver nøkkel k og ressurs s i
  # azurerm_subnet.subnet, lag en oppføring fra k til s.id. Krøllparentesene
  # gjør resultatet til et map; med hakeparenteser hadde vi fått en liste.
  #
  # Forskjellen er ikke kosmetisk. Den som bruker modulen kan nå skrive
  #     module.network.subnet_ids["app"]
  # i stedet for
  #     module.network.subnet_ids[0]
  # Den første sier hvilket subnet maskinen havner på. Den andre gjør det ikke,
  # og bytter til og med betydning hvis noen sorterer om på variabelen.
  value       = { for k, s in azurerm_subnet.subnet : k => s.id }
  description = "Subnet-ID per subnettnavn."
}

output "subnet_prefixes" {
  # Praktisk til dokumentasjon og feilsøking: her ser du hva cidrsubnet()
  # faktisk regnet ut, uten å måtte lete i portalen.
  value       = { for k, s in azurerm_subnet.subnet : k => s.address_prefixes[0] }
  description = "Utregnet adresseprefiks per subnettnavn."
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID-en til det virtuelle nettverket – trengs blant annet til peering."
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Navnet på det virtuelle nettverket."
}

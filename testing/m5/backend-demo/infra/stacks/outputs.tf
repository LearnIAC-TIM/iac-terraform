output "resource_group" {
  description = "Ressursgruppen som miljøet har opprettet."
  value       = var.rg_name
}

output "vnet_name" {
  description = "Navn på VNet."
  value       = module.network.vnet_name
}
output "resource_group" {
  description = "Navn på Resource Group."
  value       = module.network.rg_name
}

output "vnet_name" {
  description = "Navn på VNet."
  value       = module.network.vnet_name
}

output "vm_private_ip" {
  description = "Privat IP for VM."
  value       = module.compute.private_ip
}

output "vm_public_ip" {
  description = "Offentlig IP for VM (kan være null)."
  value       = module.compute.public_ip
}

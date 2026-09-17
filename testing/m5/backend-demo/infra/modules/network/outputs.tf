output "subnet_id" {
  description = "ID til subnettet."
  value       = azurerm_subnet.subnet.id
}

output "vnet_name" {
  description = "Navn på VNet."
  value       = azurerm_virtual_network.vnet.name
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.5"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-demo-backend-tim"
    storage_account_name = "sademobackendtim"
    container_name       = "tfstate"
    key                  = "compute.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "5513747a-818d-4f48-83b0-da2b2fd4cb97"
  features {
    
  }
}

# Reference the network state
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-demo-backend-tim"
    storage_account_name = "sademobackendtim"
    container_name       = "tfstate"
    key                 = "network.tfstate"
  }
}

resource "azurerm_resource_group" "vm" {
  name     = "vm-rg"
  location = "West Europe"
}

resource "azurerm_public_ip" "main" {
  name                = "vm-public-ip"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "vm-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.terraform_remote_state.network.outputs.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "simple-vm"
  resource_group_name             = azurerm_resource_group.vm.name
  location                        = azurerm_resource_group.vm.location
  size                           = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"  # In production, use variables and key vault
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
}

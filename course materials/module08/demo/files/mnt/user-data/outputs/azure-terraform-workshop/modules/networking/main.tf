# Networking Module
# Oppretter Virtual Network, Subnets, NSGs og Private DNS for database

# ============================================
# Virtual Network
# ============================================

resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  
  tags = var.tags
}

# ============================================
# Subnets
# ============================================

# Subnet for App Service
resource "azurerm_subnet" "app" {
  name                 = "${var.name_prefix}-app-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.app_subnet_address
  
  # Service endpoints for sikker kommunikasjon
  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Storage"
  ]
  
  # Delegation til App Service
  delegation {
    name = "app-service-delegation"
    
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

# Subnet for Database (PostgreSQL)
resource "azurerm_subnet" "db" {
  name                 = "${var.name_prefix}-db-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.db_subnet_address
  
  # Service endpoints
  service_endpoints = [
    "Microsoft.Storage"
  ]
  
  # Delegation til PostgreSQL Flexible Server
  delegation {
    name = "postgresql-delegation"
    
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# ============================================
# Network Security Groups
# ============================================

# NSG for App Service Subnet
resource "azurerm_network_security_group" "app" {
  name                = "${var.name_prefix}-app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Tillat inbound HTTPS
resource "azurerm_network_security_rule" "app_https_inbound" {
  name                        = "AllowHTTPSInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# Tillat inbound HTTP (for testing)
resource "azurerm_network_security_rule" "app_http_inbound" {
  name                        = "AllowHTTPInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# Tillat outbound til database subnet
resource "azurerm_network_security_rule" "app_db_outbound" {
  name                        = "AllowDatabaseOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "*"
  destination_address_prefixes = var.db_subnet_address
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# NSG for Database Subnet
resource "azurerm_network_security_group" "db" {
  name                = "${var.name_prefix}-db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Tillat inbound fra App Service subnet på PostgreSQL port
resource "azurerm_network_security_rule" "db_postgresql_inbound" {
  name                        = "AllowPostgreSQLFromApp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefixes     = var.app_subnet_address
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

# Nekt all annen inbound trafikk
resource "azurerm_network_security_rule" "db_deny_all_inbound" {
  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

# ============================================
# Private DNS Zone for PostgreSQL
# ============================================

resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.name_prefix}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.name_prefix}-postgres-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  
  tags = var.tags
}

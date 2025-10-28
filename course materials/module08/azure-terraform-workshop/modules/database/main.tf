# Database Module - PostgreSQL Flexible Server
# Oppretter PostgreSQL database med private networking og Key Vault integration

# ============================================
# PostgreSQL Flexible Server
# ============================================

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "${var.name_prefix}-psql-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # Admin credentials
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  
  # Version og SKU
  version = var.database_version
  sku_name = var.database_sku
  storage_mb = var.database_storage_mb
  
  # Backup configuration
  backup_retention_days = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup
  
  # Networking - Private access via VNet
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id
  
  # Security
  public_network_access_enabled = false
  
  # High availability (kan aktiveres senere for prod)
  # high_availability {
  #   mode = "ZoneRedundant"
  # }
  
  tags = var.tags
  
  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false  # Sett til true for produksjon
  }
  
  # DNS zone må eksistere før serveren opprettes
  depends_on = [var.private_dns_zone_id]
}

# ============================================
# PostgreSQL Database
# ============================================

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# ============================================
# PostgreSQL Configuration
# ============================================

# Azure extensions for PostgreSQL (optional)
resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "uuid-ossp,pgcrypto"
}

# Connection timeout
resource "azurerm_postgresql_flexible_server_configuration" "connection_timeout" {
  name      = "idle_in_transaction_session_timeout"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "300000"  # 5 minutter
}

# Max connections
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "100"
}

# ============================================
# Firewall Rules (kun for testing hvis nødvendig)
# ============================================

# KOMMENTAR: Siden vi bruker private networking, trenger vi normalt ikke firewall rules.
# Uncomment bare hvis du trenger direkte tilgang fra spesifikke IP-addresser for testing.

# resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
#   name             = "AllowAzureServices"
#   server_id        = azurerm_postgresql_flexible_server.main.id
#   start_ip_address = "0.0.0.0"
#   end_ip_address   = "0.0.0.0"
# }

# ============================================
# Connection String i Key Vault
# ============================================

# Konstruer connection string
locals {
  connection_string = "Server=${azurerm_postgresql_flexible_server.main.fqdn};Database=${azurerm_postgresql_flexible_server_database.main.name};Port=5432;User Id=${var.admin_username};Password=${var.admin_password};Ssl Mode=Require;"
  
  # Alternative format for Node.js/Python
  connection_string_uri = "postgresql://${var.admin_username}:${var.admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
}

# Lagre connection string i Key Vault
resource "azurerm_key_vault_secret" "connection_string" {
  name         = "postgresql-connection-string"
  value        = local.connection_string
  key_vault_id = var.key_vault_id
  
  tags = merge(
    var.tags,
    {
      Database = azurerm_postgresql_flexible_server.main.name
    }
  )
}

# Lagre URI-format connection string
resource "azurerm_key_vault_secret" "connection_string_uri" {
  name         = "postgresql-connection-string-uri"
  value        = local.connection_string_uri
  key_vault_id = var.key_vault_id
  
  tags = merge(
    var.tags,
    {
      Database = azurerm_postgresql_flexible_server.main.name
      Format   = "URI"
    }
  )
}

# Lagre database FQDN
resource "azurerm_key_vault_secret" "db_fqdn" {
  name         = "postgresql-server-fqdn"
  value        = azurerm_postgresql_flexible_server.main.fqdn
  key_vault_id = var.key_vault_id
  
  tags = var.tags
}

# Lagre admin username
resource "azurerm_key_vault_secret" "db_admin_username" {
  name         = "postgresql-admin-username"
  value        = var.admin_username
  key_vault_id = var.key_vault_id
  
  tags = var.tags
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.student_identifier}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "st${var.student_identifier}${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Sikkerhet
  public_network_access_enabled   = false
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

# Storage Container
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}
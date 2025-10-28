# Backend Configuration for Terraform State
# State lagres i studentens eksisterende Storage Account

terraform {
  backend "azurerm" {
    # Disse verdiene MÅ oppdateres med studentens egne verdier
    # Enten her eller via -backend-config flagg under terraform init
    
    resource_group_name  = "REPLACE_WITH_YOUR_RG_NAME"           # Eks: "student01-rg"
    storage_account_name = "REPLACE_WITH_YOUR_STORAGE_NAME"     # Eks: "student01storage"
    container_name       = "REPLACE_WITH_YOUR_CONTAINER_NAME"   # Eks: "tfstate"
    key                  = "dev-webapp.tfstate"                 # Navn på state-filen
    
    # Bruk OIDC authentication (federated credentials)
    use_oidc = true
  }
}

# Alternativ måte å konfigurere backend:
# Lag en fil backend-config.hcl med innholdet over og kjør:
# terraform init -backend-config=backend-config.hcl

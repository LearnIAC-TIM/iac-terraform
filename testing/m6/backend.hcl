# Ikke hemmelig — committes. Fyll inn fra: terraform -chdir=backend output -raw backend_hcl
resource_group_name  = "rg-demo-backend-tim84"
storage_account_name = "stdemotim84"
container_name       = "tfstate"
use_azuread_auth     = true

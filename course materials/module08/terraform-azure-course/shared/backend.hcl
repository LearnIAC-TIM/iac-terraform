# Template - kopier til backend.hcl og fyll inn dine verdier
# IKKE commit backend.hcl til Git!

resource_group_name  = "rg-tfstate-jicj1b"
storage_account_name = "sttfstatejicj1b"
container_name       = "tfstate"
use_azuread_auth     = true

# Autentisering via Service Principal (federated credentials)
# use_oidc             = true

# =============================================================================
#  shared/backend.hcl  –  ÉN adresse, brukt av alle stacks og av workflowene
# -----------------------------------------------------------------------------
#  Den eneste fila i repoet som har lov til å inneholde storage account-navnet:
#
#      grep -rn "storage_account_name" .
#      -> nøyaktig ett treff, og det er denne fila
#
#  Et storage account-navn er en ADRESSE, ikke et passord. Uten en
#  rolletildeling kommer ingen inn selv om de kjenner navnet.
# -----------------------------------------------------------------------------
#  Lokalt (fra stacks/nettverk):
#    terraform init -reconfigure \
#      -backend-config="../../shared/backend.hcl" \
#      -backend-config="key=env/dev/nettverk.tfstate"
#
#  I workflowene:
#      -backend-config="${{ github.workspace }}/shared/backend.hcl"
# =============================================================================

resource_group_name  = "rg-tfstate-tim"
storage_account_name = "sttfstatetim123"
container_name       = "tfstate"

# Påkrevd: kontoen har shared_access_key_enabled = false, så det finnes ingen
# nøkkel å slå opp. Uten denne linja feiler init.
use_azuread_auth = true

# `key` står med vilje IKKE her. Den er det eneste som skiller dev, test og
# prod, og settes per kjøring: env/<miljø>/nettverk.tfstate

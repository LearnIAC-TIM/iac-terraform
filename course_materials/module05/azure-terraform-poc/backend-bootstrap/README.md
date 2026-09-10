# Backend bootstrap (Terraform state i Azure Blob)

1) Logg inn:
   az login
   az account set --subscription "<ID/navn>"

2) Init/Apply:
   terraform init
   terraform apply -auto-approve

3) Kopiér output 'backend_hcl_template' inn i ../shared/backend.hcl

4) I nye prosjekter:
   terraform init \
     -backend-config="../../shared/backend.hcl" \
     -backend-config="key=projects/vnet-sample/terraform.tfstate"

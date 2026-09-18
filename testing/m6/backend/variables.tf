variable "kortnavn" {
  description = "Kort, unikt navn med små bokstaver og tall, f.eks. tim42. Brukes i storage account- og Key Vault-navnet."
  type        = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "pipeline_principal_id" {
  description = "OBJECT-ID til service principal-en, ikke client-ID. az ad sp show --id <client-id> --query id -o tsv"
  type        = string
}

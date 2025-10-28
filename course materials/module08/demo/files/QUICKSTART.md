# Quick Start Guide 🚀

Dette er en rask guide for å komme i gang med Azure Terraform Workshop!

## 📋 Forutsetninger

Før du starter, sørg for at du har:

- ✅ Azure CLI installert og konfigurert
- ✅ Terraform >= 1.5.0 installert
- ✅ Git installert
- ✅ Tilgang til Azure subscription
- ✅ Eksisterende ressurser i Azure:
  - Resource Group
  - Storage Account med container
  - Key Vault

## 🎯 Rask oppstart (2 metoder)

### Metode 1: Automatisk setup med script (Anbefalt)

```bash
# 1. Klon/naviger til prosjektet
cd azure-terraform-workshop

# 2. Kjør setup-scriptet
chmod +x scripts/setup.sh
./scripts/setup.sh

# 3. Følg instruksjonene og skriv inn dine verdier
# Scriptet vil:
# - Verifisere at alle verktøy er installert
# - Sjekke Azure-tilkobling
# - Opprette terraform.tfvars med dine verdier
# - Oppdatere backend.tf
# - Kjøre terraform init

# 4. Deploy infrastrukturen
cd environments/dev
terraform plan
terraform apply
```

### Metode 2: Manuell setup

```bash
# 1. Naviger til dev environment
cd environments/dev

# 2. Kopier example-filen
cp terraform.tfvars.example terraform.tfvars

# 3. Rediger terraform.tfvars med dine verdier
nano terraform.tfvars  # eller bruk din favoritt editor

# 4. Oppdater backend.tf med dine backend-verdier
nano backend.tf

# 5. Initialize Terraform
terraform init

# 6. Plan deployment
terraform plan -out=tfplan

# 7. Apply changes
terraform apply tfplan
```

## ⏱️ Forventet tid

- **Setup**: 5-10 minutter
- **Terraform init**: 1-2 minutter
- **Terraform apply**: 15-20 minutter (første gang)

## 📝 Hva blir opprettet?

Terraform vil opprette følgende ressurser i din Resource Group:

1. **Networking**
   - Virtual Network (VNet)
   - 2 Subnets (App og Database)
   - Network Security Groups
   - Private DNS Zone for PostgreSQL

2. **App Service**
   - App Service Plan (Linux)
   - Web App med Managed Identity
   - VNet Integration

3. **Database**
   - PostgreSQL Flexible Server
   - Database
   - Private networking
   - Connection strings i Key Vault

4. **Monitoring**
   - Application Insights
   - Log Analytics Workspace
   - Alert Rules

## 🔍 Verifiser deployment

Etter vellykket deployment:

```bash
# 1. Se alle outputs
terraform output

# 2. Test web app URL
curl https://$(terraform output -raw app_service_hostname)

# 3. Sjekk i Azure Portal
az webapp browse --name $(terraform output -raw app_service_name) \
  --resource-group <din-rg-navn>

# 4. Koble til database (test connectivity)
az postgres flexible-server connect \
  --name $(terraform output -raw database_server_name) \
  --admin-user dbadmin
```

## 🎓 Nyttige kommandoer

```bash
# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output app_service_url

# Refresh state
terraform refresh

# Destroy specific resource
terraform destroy -target=module.app_service

# Full destroy
terraform destroy
```

## 🐛 Troubleshooting

### Problem: "Backend initialization required"
**Løsning:**
```bash
terraform init -reconfigure
```

### Problem: "Error creating PostgreSQL Server: already exists"
**Løsning:** Serveren eksisterer allerede. Enten:
1. Import den: `terraform import module.database.azurerm_postgresql_flexible_server.main /subscriptions/.../...`
2. Eller endre `name_suffix` i outputs

### Problem: "Insufficient permissions"
**Løsning:** Sjekk at du har "Contributor" rolle på Resource Group

### Problem: "Cannot create VNet delegation"
**Løsning:** Slett eksisterende subnets med samme navn først

### Problem: Deployment tar veldig lang tid
**Svar:** Det er normalt! Database provisioning kan ta 10-15 minutter.

## 📚 Neste steg

Etter vellykket deployment:

1. ✅ **Deploy en sample app** til App Service
2. ✅ **Sett opp CI/CD** med GitHub Actions
3. ✅ **Implementer testing** med Terratest
4. ✅ **Utvid infrastrukturen** med flere features
5. ✅ **Opprett staging/prod** environments

## 🔐 Sikkerhet - Viktig!

- ❌ **ALDRI** commit `terraform.tfvars` til Git
- ❌ **ALDRI** commit `tfstate` filer til Git
- ✅ Bruk sterke passord for database
- ✅ Roter secrets regelmessig
- ✅ Begrens tilgang til Key Vault og Storage Account
- ✅ Bruk Managed Identity der mulig

## 📖 Ressurser

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure App Service Docs](https://learn.microsoft.com/en-us/azure/app-service/)
- [PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 💬 Hjelp

Hvis du står fast:
1. Les feilmeldingen nøye
2. Sjekk Azure Portal for ressurs-status
3. Sjekk Terraform state: `terraform show`
4. Se logs: `terraform show` eller Azure Portal
5. Spør kursledelsen

---

**Lykke til! 🎉**

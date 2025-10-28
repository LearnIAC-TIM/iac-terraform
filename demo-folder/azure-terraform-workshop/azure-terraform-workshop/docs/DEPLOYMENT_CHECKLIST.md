# Deployment Checklist ✅

Bruk denne sjekklisten for å verifisere at alt er riktig konfigurert før deployment.

## Pre-Deployment Checklist

### Azure Prerequisites
- [ ] Azure CLI installert og oppdatert (`az --version`)
- [ ] Innlogget i riktig Azure account (`az account show`)
- [ ] Riktig subscription valgt (`az account set --subscription <id>`)
- [ ] Contributor eller Owner rolle på Resource Group

### Existing Azure Resources
- [ ] Resource Group eksisterer
- [ ] Storage Account eksisterer med container for terraform state
- [ ] Key Vault eksisterer
- [ ] Service Principal har tilgang til alle ressurser (hvis du bruker OIDC)

### Local Setup
- [ ] Terraform >= 1.5.0 installert (`terraform version`)
- [ ] Git installert og konfigurert
- [ ] Repository klonet
- [ ] På riktig branch

### Configuration Files
- [ ] `terraform.tfvars` opprettet fra example-fil
- [ ] Alle required variabler i `terraform.tfvars` fylt ut:
  - [ ] `subscription_id`
  - [ ] `resource_group_name`
  - [ ] `location`
  - [ ] `key_vault_name`
  - [ ] `project_name`
  - [ ] `database_admin_password` (sterkt passord!)
- [ ] `backend.tf` oppdatert med riktige backend-verdier:
  - [ ] `resource_group_name`
  - [ ] `storage_account_name`
  - [ ] `container_name`

### Security
- [ ] `.gitignore` på plass
- [ ] `terraform.tfvars` er i `.gitignore`
- [ ] Ikke committet sensitive filer til Git
- [ ] Sterkt database passord valgt (min 8 tegn)

## Deployment Steps

### Step 1: Initialize
```bash
cd environments/dev
terraform init
```
- [ ] Init kjørte uten feil
- [ ] Backend konfigurert korrekt
- [ ] Providers lastet ned

### Step 2: Validate
```bash
terraform fmt -recursive
terraform validate
```
- [ ] Alle filer formatert riktig
- [ ] Validering passerte

### Step 3: Plan
```bash
terraform plan -out=tfplan
```
- [ ] Plan kjørte uten feil
- [ ] Forventet antall ressurser vises (ca 25-30 ressurser)
- [ ] Ingen uventede endringer eller slettinger
- [ ] Review plan output nøye

**Forventet output:**
```
Plan: XX to add, 0 to change, 0 to destroy.
```

### Step 4: Apply
```bash
terraform apply tfplan
```
- [ ] Apply startet
- [ ] Ingen feilmeldinger
- [ ] Alle ressurser opprettet (kan ta 15-20 min)

**Dette tar tid - vær tålmodig! ⏱️**
Spesielt database provisioning kan ta 10-15 minutter.

## Post-Deployment Verification

### Step 5: Verify Outputs
```bash
terraform output
```
- [ ] Alle outputs vises korrekt
- [ ] `app_service_url` er tilgjengelig
- [ ] `database_server_name` er tilgjengelig

### Step 6: Test Resources in Azure Portal

#### Networking
- [ ] Virtual Network eksisterer
- [ ] App subnet opprettet med delegasjon
- [ ] Database subnet opprettet med delegasjon
- [ ] NSGs tilknyttet subnets
- [ ] Private DNS zone opprettet

#### App Service
- [ ] App Service Plan opprettet
- [ ] Web App opprettet
- [ ] Managed Identity aktivert
- [ ] VNet Integration konfigurert
- [ ] Health check path satt

#### Database
- [ ] PostgreSQL Flexible Server opprettet
- [ ] Database opprettet
- [ ] Private access via VNet
- [ ] Public access disabled

#### Monitoring
- [ ] Application Insights opprettet
- [ ] Log Analytics Workspace opprettet
- [ ] Alert rules opprettet

#### Key Vault
- [ ] Connection strings lagret
- [ ] App Service har lesetilgang (Access Policy)

### Step 7: Test Connectivity

#### Test App Service
```bash
# Hent URL
APP_URL=$(terraform output -raw app_service_url)

# Test health endpoint
curl $APP_URL
```
- [ ] Får HTTP 503 (forventet - ingen app deployet ennå)
- [ ] Eller HTTP 200 hvis default page vises

#### Test Database Connectivity (fra Azure Cloud Shell)
```bash
# Hent database info
DB_SERVER=$(terraform output -raw database_server_name)
DB_NAME=$(terraform output -raw database_name)

# Test connection fra Cloud Shell (må være i samme VNet eller ha network access)
az postgres flexible-server connect \
  --name $DB_SERVER \
  --admin-user dbadmin \
  --database-name $DB_NAME
```
- [ ] Kan koble til database
- [ ] Kan liste databaser
- [ ] Kan kjøre queries

### Step 8: Verify Key Vault Secrets
```bash
# List secrets
az keyvault secret list --vault-name <key-vault-name> -o table

# Test å hente connection string (for å verifisere tilgang)
az keyvault secret show \
  --vault-name <key-vault-name> \
  --name postgresql-connection-string \
  --query value -o tsv
```
- [ ] Connection string secret eksisterer
- [ ] URI format secret eksisterer
- [ ] FQDN secret eksisterer
- [ ] Admin username secret eksisterer

### Step 9: Check Application Insights
```bash
# Åpne i portal
az monitor app-insights component show \
  --app <app-insights-name> \
  --resource-group <rg-name> \
  --query applicationId
```
- [ ] Application Insights konfigurert
- [ ] Koblet til Web App
- [ ] Kan se telemetri (kommer etter app er deployet)

## Deploy Sample Application (Optional)

### Manual Deployment
```bash
cd ../../sample-app

# Install dependencies
npm install

# Create deployment zip
zip -r app.zip . -x "node_modules/*" -x ".git/*"

# Deploy
az webapp deploy \
  --resource-group <rg-name> \
  --name <app-service-name> \
  --src-path app.zip \
  --type zip
```

### Test Application
```bash
# Wait for deployment to complete
sleep 60

# Test health endpoint
curl $APP_URL/

# Test database health
curl $APP_URL/health/db

# Test API
curl $APP_URL/api/items
```

## Common Issues Checklist

### If terraform init fails:
- [ ] Sjekk backend configuration
- [ ] Verifiser Storage Account access
- [ ] Sjekk at container eksisterer
- [ ] Verifiser Azure CLI login

### If terraform plan/apply fails:
- [ ] Sjekk at alle required variabler er satt
- [ ] Verifiser Azure permissions
- [ ] Sjekk quota limits i subscription
- [ ] Verifiser at resource names er unique

### If resources fail to create:
- [ ] Sjekk Azure resource quotas
- [ ] Verifiser SKU availability i region
- [ ] Sjekk for naming conflicts
- [ ] Se på detailed error messages

### If networking fails:
- [ ] Sjekk subnet address ranges (ikke overlappende)
- [ ] Verifiser NSG rules
- [ ] Sjekk service delegation
- [ ] Verifiser private DNS configuration

### If database connection fails:
- [ ] Verifiser VNet integration på App Service
- [ ] Sjekk NSG rules tillater port 5432
- [ ] Verifiser private DNS resolving
- [ ] Test connection string fra Key Vault

## Resource Monitoring

### Check Resource Status
```bash
# List all resources in Resource Group
az resource list \
  --resource-group <rg-name> \
  --output table

# Check App Service status
az webapp show \
  --name <app-name> \
  --resource-group <rg-name> \
  --query state

# Check Database status
az postgres flexible-server show \
  --name <db-name> \
  --resource-group <rg-name> \
  --query state
```

### Check Logs
```bash
# App Service logs
az webapp log tail \
  --name <app-name> \
  --resource-group <rg-name>

# Download logs
az webapp log download \
  --name <app-name> \
  --resource-group <rg-name> \
  --log-file logs.zip
```

## Cost Monitoring

### Estimate Monthly Cost
- App Service Plan B1: ~400 NOK/mnd
- PostgreSQL B1ms: ~150 NOK/mnd
- Virtual Network: ~50 NOK/mnd
- Application Insights: ~100 NOK/mnd (avhenger av data)
- **Total**: ~700 NOK/mnd

### Check Current Costs
```bash
# Check cost for Resource Group (krever Cost Management Reader role)
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31
```

## Cleanup Checklist (når du er ferdig)

### Before Destroy
- [ ] Eksporter viktige data
- [ ] Backup database hvis nødvendig
- [ ] Ta screenshots av setup
- [ ] Dokumenter learnings

### Destroy Resources
```bash
cd environments/dev

# Destroy all Terraform-managed resources
terraform destroy
```
- [ ] Bekreftet destroy kommando
- [ ] Alle ressurser slettet (bortsett fra RG, Storage, Key Vault)
- [ ] Verifisert i Azure Portal

### Manual Cleanup (hvis nødvendig)
- [ ] Slett gamle state files fra Storage Account
- [ ] Fjern gamle secrets fra Key Vault
- [ ] Rydd opp i Resource Group

## Success Criteria ✨

Din deployment er vellykket hvis:
- ✅ Alle Terraform ressurser opprettet uten feil
- ✅ App Service er tilgjengelig (selv om den viser 503)
- ✅ Database er tilgjengelig via private network
- ✅ VNet integration fungerer
- ✅ Key Vault secrets er tilgjengelige for App Service
- ✅ Application Insights samler telemetri
- ✅ Ingen sikkerhetswarnin ger i Azure Security Center
- ✅ Total deployment tid under 30 minutter

## Congratulations! 🎉

Hvis du har kommet hit med alle checkboxer merket, har du vellykket deployment!

### Neste steg:
1. Deploy sample application
2. Implementer CI/CD med GitHub Actions
3. Legg til testing med Terratest
4. Utvid med flere features
5. Opprett prod environment

**Happy Infrastructure Coding! 🚀**

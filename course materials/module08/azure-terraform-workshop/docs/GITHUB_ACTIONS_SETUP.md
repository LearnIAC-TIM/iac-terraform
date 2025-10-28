# GitHub Actions Setup Guide

Denne guiden viser hvordan du setter opp GitHub Actions for automatisk deployment av infrastruktur og applikasjon med OIDC (Federated Credentials).

## 🎯 Oversikt

Vi skal sette opp to workflows:
1. **Terraform CI/CD** - Deploy infrastruktur automatisk
2. **Deploy Application** - Deploy Node.js app til App Service

## 📋 Forutsetninger

- ✅ Azure Subscription
- ✅ GitHub repository
- ✅ Azure CLI installert
- ✅ Contributor eller Owner rolle i Azure

## 🔐 Steg 1: Opprett App Registration med Federated Credentials

### 1.1 Opprett App Registration

```bash
# Sett variabler
APP_NAME="github-actions-terraform"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Opprett App Registration
az ad app create --display-name $APP_NAME

# Få App ID
APP_ID=$(az ad app list --display-name $APP_NAME --query "[0].appId" -o tsv)

echo "App ID: $APP_ID"
```

### 1.2 Opprett Service Principal

```bash
# Opprett Service Principal
az ad sp create --id $APP_ID

# Få Object ID for Service Principal
SP_OBJECT_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)

echo "Service Principal Object ID: $SP_OBJECT_ID"
```

### 1.3 Tilordne rolle til Resource Group

```bash
# Sett Resource Group navn
RG_NAME="din-resource-group-navn"

# Tilordne Contributor rolle
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME

echo "✓ Contributor rolle tildelt til Resource Group"
```

### 1.4 Opprett Federated Credentials for GitHub

Du må opprette federated credentials for både main branch og pull requests.

#### For main branch (production deployments):

```bash
# Sett GitHub verdier
GITHUB_ORG="din-github-org"  # eller ditt brukernavn
GITHUB_REPO="repo-navn"

# Opprett federated credential for main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
    "description": "GitHub Actions for main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

echo "✓ Federated credential opprettet for main branch"
```

#### For pull requests:

```bash
# Opprett federated credential for PRs
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
    "description": "GitHub Actions for pull requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'

echo "✓ Federated credential opprettet for pull requests"
```

## 🔑 Steg 2: Konfigurer GitHub Secrets

Gå til GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Opprett følgende secrets:

### Azure Authentication Secrets
```
AZURE_CLIENT_ID         = <din App ID fra steg 1>
AZURE_TENANT_ID         = <din Tenant ID>
AZURE_SUBSCRIPTION_ID   = <din Subscription ID>
```

### Backend Configuration Secrets
```
BACKEND_RESOURCE_GROUP     = <Resource Group hvor Storage Account er>
BACKEND_STORAGE_ACCOUNT    = <Storage Account navn>
BACKEND_CONTAINER_NAME     = <Container navn for terraform state>
```

### Project Configuration Secrets
```
RESOURCE_GROUP_NAME   = <Resource Group for infrastruktur>
KEY_VAULT_NAME       = <Key Vault navn>
PROJECT_NAME         = <Ditt prosjektnavn>
DB_ADMIN_PASSWORD    = <Database admin passord>
```

### Application Deployment Secrets
```
AZURE_WEBAPP_NAME    = <App Service navn - får du fra Terraform output>
```

### Kommandoer for å hente verdier:

```bash
# Azure verdier
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"

# Backend verdier
echo "BACKEND_RESOURCE_GROUP: <din-rg>"
echo "BACKEND_STORAGE_ACCOUNT: <din-storage>"
echo "BACKEND_CONTAINER_NAME: <din-container>"

# Project verdier
echo "RESOURCE_GROUP_NAME: <din-rg>"
echo "KEY_VAULT_NAME: <ditt-keyvault>"
echo "PROJECT_NAME: <ditt-project>"
```

## 🚀 Steg 3: Test Workflows

### Test Terraform Workflow

1. **Opprett en Pull Request:**
```bash
git checkout -b test-terraform
# Gjør en liten endring i Terraform
git add .
git commit -m "Test: Update Terraform config"
git push origin test-terraform
```

2. **Opprett PR i GitHub**
   - Workflows kjører automatisk
   - Terraform plan vises som kommentar på PR

3. **Merge til main:**
   - Terraform apply kjøres automatisk
   - Infrastruktur deployes

### Test Application Workflow

1. **Push endringer i sample-app:**
```bash
# Gjør endringer i sample-app/
git add .
git commit -m "Update application"
git push origin main
```

2. **Workflow kjører automatisk**
   - Bygger applikasjon
   - Deployer til App Service
   - Kjører health checks

## 🛠️ Steg 4: Verifiser Setup

### Verifiser Azure OIDC

```bash
# Sjekk federated credentials
az ad app federated-credential list --id $APP_ID

# Sjekk rolle tilordninger
az role assignment list --assignee $APP_ID --all
```

### Verifiser GitHub Secrets

```bash
# List secrets (kan ikke se verdier)
gh secret list
```

### Verifiser Workflows

1. Gå til GitHub → Actions tab
2. Sjekk at workflows kjører
3. Se på logs for detaljer

## 📊 Workflow Oversikt

### Terraform Workflow

```
┌─────────────────┐
│   Push/PR       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Validate     │ ← Format check, validate
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Security Scan   │ ← Checkov
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Plan (PR)     │ ← Terraform plan
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Apply (main)   │ ← Terraform apply
└─────────────────┘
```

### Application Workflow

```
┌─────────────────┐
│   Push to main  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Build       │ ← npm ci, create package
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Deploy      │ ← Azure Web App Deploy
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│      Test       │ ← Health checks
└─────────────────┘
```

## 🔧 Troubleshooting

### Problem: "Failed to authenticate with Azure"

**Løsning:**
1. Verifiser at alle secrets er riktig satt
2. Sjekk at federated credentials er opprettet for riktig repo
3. Sjekk at Service Principal har riktig rolle

```bash
# Verifiser credentials
az ad app federated-credential list --id $APP_ID

# Verifiser rolle
az role assignment list --assignee $APP_ID
```

### Problem: "Backend initialization failed"

**Løsning:**
1. Sjekk at backend secrets er riktige
2. Verifiser at Storage Account og Container eksisterer
3. Sjekk at Service Principal har tilgang til Storage Account

```bash
# Grant Storage Blob Data Contributor role
az role assignment create \
  --assignee $APP_ID \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME
```

### Problem: "Terraform plan shows unexpected changes"

**Løsning:**
1. Kjør `terraform refresh` lokalt
2. Sjekk at state file er oppdatert
3. Verifiser at alle secrets er korrekte

### Problem: "App deployment succeeds but app doesn't work"

**Løsning:**
1. Sjekk App Service logs:
```bash
az webapp log tail --name $WEBAPP_NAME --resource-group $RG_NAME
```

2. Verifiser environment variables er satt:
```bash
az webapp config appsettings list --name $WEBAPP_NAME --resource-group $RG_NAME
```

3. Test database connectivity manuelt

## 📝 Best Practices

### Security
- ✅ Bruk OIDC (federated credentials) i stedet for Service Principal secrets
- ✅ Begrens Service Principal til minimum nødvendige rettigheter
- ✅ Bruk GitHub Environments for å kreve approval før production deploy
- ✅ Roter secrets regelmessig
- ✅ Bruk Key Vault for sensitive data

### Workflow Design
- ✅ Separer validate, plan og apply i egne jobs
- ✅ Bruk artifacts for å dele data mellom jobs
- ✅ Implementer health checks etter deployment
- ✅ Bruk caching for å øke hastighet
- ✅ Legg til deployment summaries

### Terraform
- ✅ Alltid kjør terraform fmt før commit
- ✅ Bruk terraform validate i CI
- ✅ Kjør security scanning (Checkov) i CI
- ✅ Store terraform state i Azure Storage
- ✅ Bruk workspaces eller separate backends for miljøer

## 🔄 Continuous Improvement

### Neste steg:

1. **Legg til test-miljø:**
   - Opprett staging environment
   - Implementer promote-strategi

2. **Forbedre testing:**
   - Legg til Terratest
   - Implementer integration tests
   - Legg til smoke tests

3. **Monitoring:**
   - Send notifications til Slack/Teams
   - Opprett dashboards
   - Sett opp alerts

4. **Advanced features:**
   - Blue-Green deployments
   - Canary releases
   - Automated rollback

## 📚 Ressurser

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure OIDC with GitHub Actions](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure App Service CI/CD](https://learn.microsoft.com/en-us/azure/app-service/deploy-github-actions)

---

**Lykke til med CI/CD setup! 🎉**

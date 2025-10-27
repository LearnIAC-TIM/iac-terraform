#!/bin/bash
set -e

# Farger for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Azure Web App Slots Lab - Setup Script                  ║${NC}"
echo -e "${BLUE}║   Praktisk øvelse i deployment slots og CI/CD             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Opprett hovedmapper
echo -e "${GREEN}📁 Oppretter mappestruktur...${NC}"
mkdir -p lab-webapp-slots/{terraform,app,scripts,tests,.github/workflows,docs}

cd lab-webapp-slots

# ============================================================================
# TERRAFORM KONFIGURASJON
# ============================================================================

echo -e "${GREEN}📝 Genererer Terraform-konfigurasjon...${NC}"

cat > terraform/main.tf << 'EOF'
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.location

  tags = var.required_tags
}

# App Service Plan (Linux)
resource "azurerm_service_plan" "lab" {
  name                = "${var.prefix}-asp"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier for kostnadseffektivitet

  tags = var.required_tags
}

# Web App
resource "azurerm_linux_web_app" "lab" {
  name                = "${var.prefix}-webapp-${var.environment}"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  service_plan_id     = azurerm_service_plan.lab.id

  # Sikkerhetskonfigurasjon
  https_only = true

  site_config {
    minimum_tls_version = "1.2"
    
    application_stack {
      python_version = "3.11"
    }

    # Health check
    health_check_path = "/health"
  }

  app_settings = {
    "ENVIRONMENT"      = "production"
    "FEATURE_TOGGLE_X" = "false"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  # FTP deaktivert for sikkerhet
  ftp_publish_basic_authentication_enabled = false
  
  tags = var.required_tags
}

# Staging Slot
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.lab.id

  https_only = true

  site_config {
    minimum_tls_version = "1.2"
    
    application_stack {
      python_version = "3.11"
    }

    health_check_path = "/health"
  }

  app_settings = {
    "ENVIRONMENT"      = "staging"
    "FEATURE_TOGGLE_X" = "true"  # Feature toggle aktivert i staging
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  ftp_publish_basic_authentication_enabled = false

  tags = merge(var.required_tags, {
    Slot = "staging"
  })
}
EOF

cat > terraform/variables.tf << 'EOF'
variable "prefix" {
  description = "Prefix for alle ressurser"
  type        = string
  default     = "student"
}

variable "resource_group_name" {
  description = "Navn på resource group"
  type        = string
  default     = "rg-webapp-lab"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "norwayeast"
}

variable "environment" {
  description = "Miljø (dev/test/prod)"
  type        = string
  default     = "lab"
}

variable "required_tags" {
  description = "Påkrevde tags for compliance"
  type        = map(string)
  default = {
    Environment = "Lab"
    Project     = "WebAppSlots"
    ManagedBy   = "Terraform"
    CostCenter  = "Education"
  }
}
EOF

cat > terraform/outputs.tf << 'EOF'
output "webapp_name" {
  description = "Navn på Web App"
  value       = azurerm_linux_web_app.lab.name
}

output "webapp_url" {
  description = "URL til production slot"
  value       = "https://${azurerm_linux_web_app.lab.default_hostname}"
}

output "staging_url" {
  description = "URL til staging slot"
  value       = "https://${azurerm_linux_web_app.lab.name}-staging.azurewebsites.net"
}

output "resource_group_name" {
  description = "Resource group navn"
  value       = azurerm_resource_group.lab.name
}
EOF

# ============================================================================
# WEB APPLIKASJON (Python Flask)
# ============================================================================

echo -e "${GREEN}🐍 Genererer Flask-applikasjon...${NC}"

cat > app/app.py << 'EOF'
from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

# Hent miljøvariabler
ENVIRONMENT = os.getenv('ENVIRONMENT', 'unknown')
FEATURE_TOGGLE_X = os.getenv('FEATURE_TOGGLE_X', 'false').lower() == 'true'
VERSION = os.getenv('APP_VERSION', '1.0.0')

@app.route('/')
def home():
    """Hovedside med miljøinformasjon"""
    return jsonify({
        'message': 'Azure Web App Slots Lab',
        'environment': ENVIRONMENT,
        'version': VERSION,
        'hostname': socket.gethostname(),
        'feature_x_enabled': FEATURE_TOGGLE_X
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'environment': ENVIRONMENT,
        'checks': {
            'app': 'ok',
            'feature_toggle': FEATURE_TOGGLE_X
        }
    }), 200

@app.route('/feature-x')
def feature_x():
    """Feature toggle demo"""
    if FEATURE_TOGGLE_X:
        return jsonify({
            'feature': 'X',
            'enabled': True,
            'message': 'Dette er den nye funksjonen!',
            'environment': ENVIRONMENT
        })
    else:
        return jsonify({
            'feature': 'X',
            'enabled': False,
            'message': 'Feature X er ikke tilgjengelig ennå.',
            'environment': ENVIRONMENT
        })

@app.route('/api/version')
def version():
    """Versjonsinformasjon"""
    return jsonify({
        'version': VERSION,
        'environment': ENVIRONMENT,
        'deployment_slot': 'staging' if 'staging' in ENVIRONMENT.lower() else 'production'
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)
EOF

cat > app/requirements.txt << 'EOF'
Flask==3.0.0
gunicorn==21.2.0
Werkzeug==3.0.1
EOF

cat > app/startup.sh << 'EOF'
#!/bin/bash
echo "Starting application..."
gunicorn --bind=0.0.0.0:8000 --workers=2 --timeout=600 app:app
EOF

chmod +x app/startup.sh

# ============================================================================
# TEST SCRIPTS
# ============================================================================

echo -e "${GREEN}🧪 Genererer test-scripts...${NC}"

cat > scripts/test-offline.sh << 'EOF'
#!/bin/bash
# OFFLINE TESTING: Syntaks og linting

set -e

echo "🔍 OFFLINE TESTING - Syntaks og Sikkerhet"
echo "========================================"

# Terraform validering
echo "→ Validerer Terraform konfigurasjon..."
cd terraform
terraform fmt -check
terraform validate
cd ..

# Python syntax check
echo "→ Sjekker Python syntaks..."
python3 -m py_compile app/app.py

# Sjekk for vanlige sikkerhetsproblemer i kode
echo "→ Sjekker for hardkodet secrets..."
if grep -r "password\|secret\|key" app/*.py | grep -v "FEATURE_TOGGLE"; then
    echo "❌ ADVARSEL: Potensielle hardkodede secrets funnet!"
    exit 1
fi

echo "✅ Alle offline tester bestått!"
EOF

cat > scripts/test-policy.sh << 'EOF'
#!/bin/bash
# CONNECTED STATIC ANALYSIS: Policy og compliance

set -e

echo "🔐 POLICY TESTING - Compliance og Sikkerhet"
echo "=========================================="

cd terraform

# Terraform plan
echo "→ Kjører Terraform plan..."
terraform plan -out=tfplan > /dev/null 2>&1

# Konverter plan til JSON for analyse
terraform show -json tfplan > tfplan.json

# Sjekk påkrevde tags
echo "→ Verifiserer påkrevde tags..."
if ! grep -q '"Environment"' tfplan.json || ! grep -q '"ManagedBy"' tfplan.json; then
    echo "❌ FEIL: Påkrevde tags mangler!"
    exit 1
fi

# Sjekk HTTPS-only
echo "→ Verifiserer HTTPS-only policy..."
if grep -q '"https_only.*false' tfplan.json; then
    echo "❌ FEIL: HTTPS-only er ikke aktivert!"
    exit 1
fi

# Sjekk FTP deaktivert
echo "→ Verifiserer FTP er deaktivert..."
if grep -q '"ftp_publish_basic_authentication_enabled.*true' tfplan.json; then
    echo "❌ FEIL: FTP basic auth er aktivert (skal være deaktivert)!"
    exit 1
fi

# Sjekk minimum TLS version
echo "→ Verifiserer TLS 1.2 minimum..."
if grep -q '"minimum_tls_version":"1\.[01]"' tfplan.json; then
    echo "❌ FEIL: TLS versjon er for lav!"
    exit 1
fi

rm tfplan tfplan.json

echo "✅ Alle policy tester bestått!"
cd ..
EOF

cat > scripts/test-verify.sh << 'EOF'
#!/bin/bash
# ONLINE VERIFICATION: Sjekk at ressurser er korrekt konfigurert

set -e

WEBAPP_NAME=$1
RG_NAME=$2

if [ -z "$WEBAPP_NAME" ] || [ -z "$RG_NAME" ]; then
    echo "Usage: $0 <webapp-name> <resource-group-name>"
    exit 1
fi

echo "🔎 VERIFICATION TESTING - Ressurskonfigurasjon"
echo "============================================="

# Sjekk at web app eksisterer
echo "→ Verifiserer Web App eksisterer..."
if ! az webapp show --name "$WEBAPP_NAME" --resource-group "$RG_NAME" > /dev/null 2>&1; then
    echo "❌ FEIL: Web App $WEBAPP_NAME ble ikke funnet!"
    exit 1
fi

# Sjekk staging slot
echo "→ Verifiserer staging slot..."
if ! az webapp deployment slot list --name "$WEBAPP_NAME" --resource-group "$RG_NAME" | grep -q "staging"; then
    echo "❌ FEIL: Staging slot ble ikke funnet!"
    exit 1
fi

# Sjekk HTTPS-only er aktivert
echo "→ Verifiserer HTTPS-only konfigurasjon..."
HTTPS_ONLY=$(az webapp show --name "$WEBAPP_NAME" --resource-group "$RG_NAME" --query httpsOnly -o tsv)
if [ "$HTTPS_ONLY" != "true" ]; then
    echo "❌ FEIL: HTTPS-only er ikke aktivert!"
    exit 1
fi

# Sjekk app settings forskjeller
echo "→ Verifiserer app settings forskjeller..."
PROD_ENV=$(az webapp config appsettings list --name "$WEBAPP_NAME" --resource-group "$RG_NAME" --query "[?name=='ENVIRONMENT'].value" -o tsv)
STAGING_ENV=$(az webapp config appsettings list --name "$WEBAPP_NAME" --resource-group "$RG_NAME" --slot staging --query "[?name=='ENVIRONMENT'].value" -o tsv)

if [ "$PROD_ENV" == "$STAGING_ENV" ]; then
    echo "⚠️  ADVARSEL: ENVIRONMENT variabel er lik i begge slots!"
fi

echo "✅ Alle verification tester bestått!"
EOF

cat > scripts/test-health.sh << 'EOF'
#!/bin/bash
# HEALTH CHECK: Test at applikasjonen svarer korrekt

set -e

URL=$1
EXPECTED_ENV=${2:-production}

if [ -z "$URL" ]; then
    echo "Usage: $0 <url> [expected-environment]"
    exit 1
fi

echo "🏥 HEALTH CHECK - $URL"
echo "========================================"

# Vent på at appen er klar
echo "→ Venter på at applikasjon starter..."
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" "$URL/health" | grep -q "200"; then
        break
    fi
    echo "  Forsøk $i/30..."
    sleep 2
done

# Health endpoint
echo "→ Tester /health endpoint..."
RESPONSE=$(curl -s "$URL/health")
STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null || echo "error")

if [ "$STATUS" != "healthy" ]; then
    echo "❌ FEIL: Health check feilet!"
    echo "$RESPONSE"
    exit 1
fi

# Sjekk miljø
echo "→ Verifiserer miljø..."
ENV=$(echo "$RESPONSE" | jq -r '.environment' 2>/dev/null || echo "unknown")
echo "  Miljø: $ENV (forventet: $EXPECTED_ENV)"

# Test hovedside
echo "→ Tester hovedside..."
HOME_RESPONSE=$(curl -s "$URL/")
MESSAGE=$(echo "$HOME_RESPONSE" | jq -r '.message' 2>/dev/null || echo "")

if [ -z "$MESSAGE" ]; then
    echo "❌ FEIL: Kunne ikke hente response fra hovedside!"
    exit 1
fi

# Test feature toggle
echo "→ Tester feature toggle..."
FEATURE_RESPONSE=$(curl -s "$URL/feature-x")
FEATURE_ENABLED=$(echo "$FEATURE_RESPONSE" | jq -r '.enabled' 2>/dev/null || echo "unknown")
echo "  Feature X enabled: $FEATURE_ENABLED"

echo "✅ Alle health checks bestått!"
echo ""
echo "📊 Response summary:"
echo "$HOME_RESPONSE" | jq '.'
EOF

cat > scripts/swap-slots.sh << 'EOF'
#!/bin/bash
# SLOT SWAP: Bytt staging og production

set -e

WEBAPP_NAME=$1
RG_NAME=$2

if [ -z "$WEBAPP_NAME" ] || [ -z "$RG_NAME" ]; then
    echo "Usage: $0 <webapp-name> <resource-group-name>"
    exit 1
fi

echo "🔄 SLOT SWAP - Bytter staging til production"
echo "==========================================="

# Pre-swap verification
echo "→ Pre-swap: Tester staging slot..."
STAGING_URL="https://${WEBAPP_NAME}-staging.azurewebsites.net"
bash scripts/test-health.sh "$STAGING_URL" "staging"

# Utfør swap
echo "→ Utfører slot swap..."
az webapp deployment slot swap \
    --name "$WEBAPP_NAME" \
    --resource-group "$RG_NAME" \
    --slot staging \
    --target-slot production

echo "→ Venter på at swap fullføres..."
sleep 10

# Post-swap verification
echo "→ Post-swap: Tester production slot..."
PROD_URL="https://${WEBAPP_NAME}.azurewebsites.net"
bash scripts/test-health.sh "$PROD_URL" "production"

echo "✅ Slot swap fullført og verifisert!"
EOF

# Gjør scripts kjørbare
chmod +x scripts/*.sh

# ============================================================================
# CI/CD WORKFLOWS
# ============================================================================

echo -e "${GREEN}⚙️  Genererer GitHub Actions workflows...${NC}"

cat > .github/workflows/pr-validation.yml << 'EOF'
name: PR Validation (Ephemeral)

on:
  pull_request:
    branches: [main]

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  offline-tests:
    name: 🔍 Offline Testing
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Run Offline Tests
        run: bash scripts/test-offline.sh

  policy-tests:
    name: 🔐 Policy & Compliance
    runs-on: ubuntu-latest
    needs: offline-tests
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Terraform Init
        run: |
          cd terraform
          terraform init
      
      - name: Run Policy Tests
        run: bash scripts/test-policy.sh

  preview-deploy:
    name: 🚀 Preview Deploy (Ephemeral)
    runs-on: ubuntu-latest
    needs: [offline-tests, policy-tests]
    environment:
      name: pr-preview
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      
      - name: Deploy Preview Environment
        run: |
          cd terraform
          terraform init
          terraform apply -auto-approve \
            -var="prefix=pr-${{ github.event.pull_request.number }}" \
            -var="resource_group_name=rg-webapp-pr-${{ github.event.pull_request.number }}"
      
      - name: Get Outputs
        id: tf-outputs
        run: |
          cd terraform
          echo "webapp_name=$(terraform output -raw webapp_name)" >> $GITHUB_OUTPUT
          echo "webapp_url=$(terraform output -raw webapp_url)" >> $GITHUB_OUTPUT
      
      - name: Verification Tests
        run: |
          bash scripts/test-verify.sh \
            ${{ steps.tf-outputs.outputs.webapp_name }} \
            rg-webapp-pr-${{ github.event.pull_request.number }}
      
      - name: Deploy Application
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ steps.tf-outputs.outputs.webapp_name }}
          package: ./app
      
      - name: Health Check
        run: |
          bash scripts/test-health.sh ${{ steps.tf-outputs.outputs.webapp_url }}
      
      - name: Cleanup (on failure)
        if: failure()
        run: |
          cd terraform
          terraform destroy -auto-approve \
            -var="prefix=pr-${{ github.event.pull_request.number }}" \
            -var="resource_group_name=rg-webapp-pr-${{ github.event.pull_request.number }}"

  cleanup-preview:
    name: 🧹 Cleanup Preview
    runs-on: ubuntu-latest
    if: github.event.pull_request.merged == true
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      
      - name: Destroy Preview Environment
        run: |
          cd terraform
          terraform init
          terraform destroy -auto-approve \
            -var="prefix=pr-${{ github.event.pull_request.number }}" \
            -var="resource_group_name=rg-webapp-pr-${{ github.event.pull_request.number }}"
EOF

cat > .github/workflows/main-deploy.yml << 'EOF'
name: Main Deploy (Persistent)

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 2 * * 1'  # Ukentlig rebuild (mandag 02:00)
  workflow_dispatch:  # Manuell trigger

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  test-and-build:
    name: 🧪 Test & Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Offline Tests
        run: bash scripts/test-offline.sh
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      
      - name: Policy Tests
        run: |
          cd terraform
          terraform init
          cd ..
          bash scripts/test-policy.sh

  deploy-infrastructure:
    name: 🏗️  Deploy Infrastructure
    runs-on: ubuntu-latest
    needs: test-and-build
    environment: production
    outputs:
      webapp_name: ${{ steps.tf-outputs.outputs.webapp_name }}
      resource_group: ${{ steps.tf-outputs.outputs.resource_group }}
      staging_url: ${{ steps.tf-outputs.outputs.staging_url }}
      prod_url: ${{ steps.tf-outputs.outputs.prod_url }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      
      - name: Terraform Apply
        run: |
          cd terraform
          terraform init
          terraform apply -auto-approve
      
      - name: Get Outputs
        id: tf-outputs
        run: |
          cd terraform
          echo "webapp_name=$(terraform output -raw webapp_name)" >> $GITHUB_OUTPUT
          echo "resource_group=$(terraform output -raw resource_group_name)" >> $GITHUB_OUTPUT
          echo "staging_url=$(terraform output -raw staging_url)" >> $GITHUB_OUTPUT
          echo "prod_url=$(terraform output -raw webapp_url)" >> $GITHUB_OUTPUT
      
      - name: Verify Infrastructure
        run: |
          bash scripts/test-verify.sh \
            ${{ steps.tf-outputs.outputs.webapp_name }} \
            ${{ steps.tf-outputs.outputs.resource_group }}

  deploy-to-staging:
    name: 🚀 Deploy to Staging
    runs-on: ubuntu-latest
    needs: deploy-infrastructure
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to Staging Slot
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ needs.deploy-infrastructure.outputs.webapp_name }}
          slot-name: staging
          package: ./app
      
      - name: Staging Health Check
        run: |
          bash scripts/test-health.sh \
            ${{ needs.deploy-infrastructure.outputs.staging_url }} \
            staging

  swap-to-production:
    name: ♻️  Swap to Production
    runs-on: ubuntu-latest
    needs: [deploy-infrastructure, deploy-to-staging]
    environment: production-swap
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Slot Swap
        run: |
          bash scripts/swap-slots.sh \
            ${{ needs.deploy-infrastructure.outputs.webapp_name }} \
            ${{ needs.deploy-infrastructure.outputs.resource_group }}
      
      - name: Production Health Check
        run: |
          bash scripts/test-health.sh \
            ${{ needs.deploy-infrastructure.outputs.prod_url }} \
            production
EOF

# ============================================================================
# DOKUMENTASJON
# ============================================================================

echo -e "${GREEN}📚 Genererer dokumentasjon...${NC}"

cat > README.md << 'EOF'
# 🚀 Azure Web App Deployment Slots Lab

Praktisk øvelse i moderne deployment-mønstre med Azure App Service slots, Infrastructure as Code, og CI/CD.

## 📋 Læringsmål

Etter gjennomført lab skal studentene kunne:
- ✅ Sette opp Web App med staging/production slots ved hjelp av Terraform
- ✅ Implementere sikker slot swap-strategi (blue-green deployment)
- ✅ Bruke feature toggles for gradvis utrulling
- ✅ Implementere multi-layer testing (offline → policy → verification → outcomes)
- ✅ Forstå forskjellen mellom ephemeral (PR) og persistent (main) miljøer
- ✅ Orkestere test-pipeline i CI/CD

## 🏗️ Arkitektur

```
┌─────────────────────────────────────────┐
│     Azure App Service Plan (Linux)      │
│  ┌───────────────────────────────────┐  │
│  │     Web App                       │  │
│  │  ┌──────────┐     ┌────────────┐ │  │
│  │  │Production│ ←──→ │  Staging   │ │  │
│  │  │  Slot    │ SWAP │   Slot     │ │  │
│  │  └──────────┘     └────────────┘ │  │
│  │                                   │  │
│  │  Feature Toggle: OFF   Toggle: ON│  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## 🚦 Test-nivåer

### 1. **Offline Testing** (scripts/test-offline.sh)
- Syntaks-validering (Terraform, Python)
- Linting
- Sikkerhetssjekk (hardkodede secrets)
- ✅ **Når**: Ved hver kodeendring, lokalt og i CI

### 2. **Connected Static Analysis** (scripts/test-policy.sh)
- Policy compliance (påkrevde tags)
- HTTPS-only enforcement
- FTP deaktivering
- TLS minimum version
- ✅ **Når**: I PR-validering, før deployment

### 3. **Online Verification** (scripts/test-verify.sh)
- Sjekk at ressurser eksisterer
- Verifiser konfigurasjon
- Sammenlign slots
- ✅ **Når**: Etter infrastructure deployment

### 4. **Online Outcomes** (scripts/test-health.sh)
- Health checks (HTTP 200)
- Feature toggle testing
- Response validation
- ✅ **Når**: Før og etter slot swap

## 🎯 Oppgaver

### Del 1: Lokal Utvikling
1. **Setup miljø**
   ```bash
   # Installer dependencies
   pip install -r app/requirements.txt
   
   # Kjør appen lokalt
   cd app
   export ENVIRONMENT=local
   export FEATURE_TOGGLE_X=true
   python app.py
   ```

2. **Test lokalt**
   ```bash
   curl http://localhost:8000/
   curl http://localhost:8000/health
   curl http://localhost:8000/feature-x
   ```

### Del 2: Infrastructure Deployment
1. **Login til Azure**
   ```bash
   az login
   ```

2. **Deploy med Terraform**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Verifiser deployment**
   ```bash
   cd ..
   WEBAPP_NAME=$(cd terraform && terraform output -raw webapp_name)
   RG_NAME=$(cd terraform && terraform output -raw resource_group_name)
   
   bash scripts/test-verify.sh $WEBAPP_NAME $RG_NAME
   ```

### Del 3: Application Deployment
1. **Deploy til staging**
   ```bash
   az webapp deployment source config-zip \
     --resource-group $RG_NAME \
     --name $WEBAPP_NAME \
     --slot staging \
     --src app.zip  # (create zip first: cd app && zip -r ../app.zip .)
   ```

2. **Test staging**
   ```bash
   STAGING_URL="https://${WEBAPP_NAME}-staging.azurewebsites.net"
   bash scripts/test-health.sh $STAGING_URL staging
   ```

### Del 4: Slot Swap
1. **Utfør swap**
   ```bash
   bash scripts/swap-slots.sh $WEBAPP_NAME $RG_NAME
   ```

2. **Verifiser production**
   ```bash
   PROD_URL="https://${WEBAPP_NAME}.azurewebsites.net"
   bash scripts/test-health.sh $PROD_URL production
   ```

### Del 5: CI/CD Pipeline
1. **Sett opp GitHub repository**
   ```bash
   git init
   git add .
   git commit -m "Initial lab setup"
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Konfigurer GitHub Secrets**
   - `AZURE_CREDENTIALS`: Service Principal JSON
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`

3. **Test PR workflow**
   ```bash
   git checkout -b feature/test-change
   # Gjør en endring i app/app.py
   git commit -am "Test change"
   git push origin feature/test-change
   # Opprett PR i GitHub
   ```

## 🎓 Diskusjonspunkter

1. **Blue-Green vs Canary Deployment**
   - Hva er forskjellen?
   - Når bruker man hvilken strategi?

2. **Feature Toggles**
   - Fordeler og ulemper?
   - Hvordan unngå "technical debt"?

3. **Ephemeral Environments**
   - Hvorfor er PR-baserte miljøer nyttige?
   - Kostnad vs nytte?

4. **Test Pyramid**
   - Hvorfor flere offline tester enn online?
   - Balanse mellom hastighet og grundighet?

## 🧹 Cleanup

```bash
cd terraform
terraform destroy
```

## 📚 Ressurser

- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Deployment Slots Best Practices](https://learn.microsoft.com/en-us/azure/app-service/deploy-best-practices)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## ❓ Troubleshooting

**Problem**: Slot swap feiler
- ✅ Sjekk at begge slots er healthy
- ✅ Verifiser at app settings er korrekt konfigurert

**Problem**: Health check timeout
- ✅ Øk timeout i test-health.sh
- ✅ Sjekk app logs: `az webapp log tail`

**Problem**: Terraform state conflicts
- ✅ Bruk remote backend (Azure Storage)
- ✅ Eller bruk unik prefix per student

---

**🎉 Lykke til med labben!**
EOF

cat > docs/LAB-GUIDE.md << 'EOF'
# 📖 Detaljert Lab-guide

## Scenario

Du er DevOps-ingeniør i et team som utvikler en web-applikasjon. Teamet ønsker å:
1. Redusere risiko ved deployments
2. Teste nye features i produksjonslignende miljø
3. Kunne rulle tilbake raskt ved problemer
4. Automatisere testing og deployment

## Gjennomføring (4 timer)

### Time 1: Grunnleggende Forståelse (60 min)

#### 1.1 Introduksjon til Deployment Slots (20 min)
- Hva er deployment slots?
- Blue-green deployment forklart
- Slot swap vs rolling deployment

**Praktisk demo**: Kjør lokal app med ulike environment variabler

```bash
# Terminal 1: Production mode
export ENVIRONMENT=production FEATURE_TOGGLE_X=false
python app/app.py

# Terminal 2: Test forskjellen
curl http://localhost:8000/feature-x
```

#### 1.2 Infrastructure as Code (20 min)
- Terraform basics
- Azure provider konfigurasjon
- Resource dependencies

**Oppgave**: Analyser `terraform/main.tf`
- Identifiser alle ressurser
- Finn sikkerhetskonfigurasjoner (https_only, tls_version, ftp)
- Diskuter: Hvorfor er tags viktige?

#### 1.3 Test Strategi (20 min)
- Test pyramid
- Shift-left testing
- Cost of bugs

**Diskusjon**:
- Hva er kostnaden ved en bug i production vs staging vs development?
- Hvordan balanserer vi test-dekningsgrad mot utviklingshastighet?

### Time 2: Hands-on Infrastructure (60 min)

#### 2.1 Deploy Infrastructure (30 min)

```bash
# Login
az login

# Sett subscription (om nødvendig)
az account set --subscription "Your Subscription"

# Deploy
cd terraform
terraform init
terraform plan  # Les outputen nøye!
terraform apply

# Noter ned outputs
terraform output
```

**Oppgaver**:
1. Åpne Azure Portal og verifiser at ressursene er opprettet
2. Sjekk tags på ressursene
3. Naviger til Web App → Configuration → Deployment slots

#### 2.2 Kjør Offline og Policy Tests (15 min)

```bash
# Offline
bash scripts/test-offline.sh

# Policy
bash scripts/test-policy.sh
```

**Refleksjon**:
- Hvilke feil ville disse testene fanget opp?
- Når i utviklingsprosessen kjøres de?

#### 2.3 Kjør Verification Tests (15 min)

```bash
WEBAPP_NAME=$(cd terraform && terraform output -raw webapp_name)
RG_NAME=$(cd terraform && terraform output -raw resource_group_name)

bash scripts/test-verify.sh $WEBAPP_NAME $RG_NAME
```

**Analyse**:
- Sjekk scriptet: Hva verifiseres?
- Hvordan ville du utvidet testene?

### Time 3: Application Deployment (60 min)

#### 3.1 Manuell Deploy til Staging (30 min)

```bash
# Pakk applikasjonen
cd app
zip -r ../app.zip . -x "*.pyc" -x "__pycache__/*"
cd ..

# Deploy til staging slot
az webapp deployment source config-zip \
  --resource-group $RG_NAME \
  --name $WEBAPP_NAME \
  --slot staging \
  --src app.zip

# Vent på at deployment fullføres
sleep 30
```

**Test staging**:
```bash
STAGING_URL="https://${WEBAPP_NAME}-staging.azurewebsites.net"

# Health check
bash scripts/test-health.sh $STAGING_URL staging

# Manuell testing
curl $STAGING_URL
curl $STAGING_URL/feature-x
curl $STAGING_URL/health
```

#### 3.2 Sammenlign Staging og Production (15 min)

```bash
PROD_URL="https://${WEBAPP_NAME}.azurewebsites.net"

# Production (skal være tom/default nå)
curl $PROD_URL

# Staging (skal ha din app)
curl $STAGING_URL
```

**Diskuter**:
- Hva ser du av forskjeller?
- Hvordan kan du teste at feature toggle fungerer?

#### 3.3 Slot Swap (15 min)

```bash
# Kjør swap-script (inkluderer pre/post checks)
bash scripts/swap-slots.sh $WEBAPP_NAME $RG_NAME

# Verifiser
curl $PROD_URL
curl $PROD_URL/feature-x
```

**Eksperiment**:
1. Gjør en endring i app.py (f.eks. endre welcome message)
2. Deploy til staging
3. Test staging
4. Swap til production
5. Verifiser endringen i production

### Time 4: CI/CD Automation (60 min)

#### 4.1 GitHub Actions Setup (20 min)

```bash
# Init git repo
git init
git add .
git commit -m "Initial lab setup"

# Opprett GitHub repo og push
git remote add origin <your-repo-url>
git push -u origin main
```

**Konfigurer Secrets** (i GitHub Settings → Secrets):

Opprett Service Principal:
```bash
az ad sp create-for-rbac --name "github-webapp-lab" \
  --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

Legg til secrets:
- `AZURE_CREDENTIALS`: Hele JSON outputen fra kommandoen over
- `AZURE_CLIENT_ID`: `clientId` fra JSON
- `AZURE_CLIENT_SECRET`: `clientSecret` fra JSON
- `AZURE_SUBSCRIPTION_ID`: `subscriptionId` fra JSON
- `AZURE_TENANT_ID`: `tenantId` fra JSON

#### 4.2 Test PR Workflow (20 min)

```bash
# Opprett feature branch
git checkout -b feature/new-endpoint

# Legg til ny endpoint i app.py
cat >> app/app.py << 'ENDPOINT'

@app.route('/api/students')
def students():
    return jsonify({
        'students': ['Alice', 'Bob', 'Charlie'],
        'environment': ENVIRONMENT
    })
ENDPOINT

# Commit og push
git add app/app.py
git commit -m "Add students endpoint"
git push origin feature/new-endpoint
```

**I GitHub**:
1. Opprett Pull Request
2. Observer workflow kjøring
3. Sjekk at alle tests passerer
4. Noter preview URL (i logs)
5. Test preview miljøet

#### 4.3 Merge og Production Deploy (20 min)

```bash
# Merge PR i GitHub UI

# Observér main workflow
# - Kjører alle tests
# - Deployer til staging
# - Swapper til production
```

**Verifiser**:
1. Sjekk at production URL har den nye endpointen
2. Test: `curl $PROD_URL/api/students`
3. Sjekk at preview miljøet ble ryddet opp

## 🎯 Ekstra Utfordringer

### Utfordring 1: Custom Health Checks
Utvid `/health` endpoint til å sjekke:
- Database tilkobling (mock)
- External API (mock)
- Disk space

### Utfordring 2: Gradual Rollout
Modifiser swap-script til å:
1. Route 10% trafikk til ny versjon
2. Vent 5 min
3. Sjekk error rate
4. Full swap eller rollback

### Utfordring 3: Monitoring
Legg til Application Insights:
- Custom metrics
- Exception tracking
- Performance monitoring

### Utfordring 4: Multi-stage Pipeline
Utvid workflow med:
- Dev environment (automatisk deploy)
- Test environment (deploy etter godkjenning)
- Prod environment (deploy etter godkjenning + smoke tests)

## 📊 Evalueringskriterier

### Grunnleggende (bestått)
- ✅ Infrastruktur deployet korrekt
- ✅ Applikasjon kjører i begge slots
- ✅ Slot swap utført vellykket
- ✅ Alle test-scripts kjører uten feil

### Avansert (høy karakter)
- ✅ CI/CD pipeline fullt fungerende
- ✅ Forstår trade-offs i deployment-strategier
- ✅ Implementert ekstra utfordringer
- ✅ God dokumentasjon av endringer

## 🤔 Refleksjonsspørsmål

1. **Sikkerhet**
   - Hvilke sikkerhetstiltak er implementert?
   - Hva mangler? (Secrets management, network isolation, etc.)

2. **Skalerbarhet**
   - Hvordan ville du håndtert 100x mer trafikk?
   - Database i samme setup?

3. **Kostnader**
   - Hva koster dette setuppet per måned?
   - Hvordan optimalisere?

4. **Feilhåndtering**
   - Hva skjer hvis swap feiler?
   - Hvordan rulle tilbake?

5. **Team Workflow**
   - Hvordan ville flere utviklere jobbe sammen?
   - Branch strategi?

---

**Lykke til! 🚀**
EOF

# ============================================================================
# TESTING UTILITIES
# ============================================================================

cat > tests/test-local-app.sh << 'EOF'
#!/bin/bash
# Test Flask app lokalt før deployment

set -e

echo "🧪 Testing Flask app locally..."

# Start appen i bakgrunnen
cd app
export ENVIRONMENT=test
export FEATURE_TOGGLE_X=true
python app.py &
APP_PID=$!
cd ..

# Vent på at appen starter
sleep 3

# Test endpoints
echo "→ Testing / endpoint..."
curl -s http://localhost:8000/ | jq .

echo "→ Testing /health endpoint..."
curl -s http://localhost:8000/health | jq .

echo "→ Testing /feature-x endpoint..."
curl -s http://localhost:8000/feature-x | jq .

# Stopp appen
kill $APP_PID

echo "✅ Local tests passed!"
EOF

chmod +x tests/test-local-app.sh

# ============================================================================
# GITIGNORE
# ============================================================================

cat > .gitignore << 'EOF'
# Terraform
terraform/.terraform/
terraform/.terraform.lock.hcl
terraform/terraform.tfstate
terraform/terraform.tfstate.backup
terraform/*.tfplan
terraform/*.json

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
ENV/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Secrets
*.pem
*.key
secrets.txt

# Build artifacts
*.zip
dist/
build/
EOF

# ============================================================================
# SCRIPTS FOR STUDENTS
# ============================================================================

cat > quick-start.sh << 'EOF'
#!/bin/bash

echo "🚀 Azure Web App Slots Lab - Quick Start"
echo "========================================"
echo ""
echo "Dette scriptet guider deg gjennom setup."
echo ""

read -p "Har du Azure CLI installert? (y/n): " has_az
if [ "$has_az" != "y" ]; then
    echo "❌ Installer Azure CLI først: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

read -p "Har du Terraform installert? (y/n): " has_tf
if [ "$has_tf" != "y" ]; then
    echo "❌ Installer Terraform først: https://www.terraform.io/downloads"
    exit 1
fi

read -p "Er du logget inn i Azure? (y/n): " is_logged
if [ "$is_logged" != "y" ]; then
    echo "→ Logger inn i Azure..."
    az login
fi

echo ""
echo "✅ Prerequisites OK!"
echo ""
echo "📚 Neste steg:"
echo "1. Les README.md for oversikt"
echo "2. Les docs/LAB-GUIDE.md for detaljert guide"
echo "3. Start med 'cd terraform && terraform init'"
echo ""
echo "Lykke til! 🎉"
EOF

chmod +x quick-start.sh

# ============================================================================
# FERDIG!
# ============================================================================

echo ""
echo -e "${GREEN}✅ Lab-oppsett fullført!${NC}"
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     🎉 FERDIG! 🎉                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📁 Struktur opprettet:${NC}"
echo "   lab-webapp-slots/"
echo "   ├── terraform/          (Infrastructure as Code)"
echo "   ├── app/                (Flask web app)"
echo "   ├── scripts/            (Test og deploy scripts)"
echo "   ├── .github/workflows/  (CI/CD pipelines)"
echo "   ├── docs/               (Detaljert guide)"
echo "   └── tests/              (Lokale tester)"
echo ""
echo -e "${YELLOW}📖 Neste steg:${NC}"
echo "   cd lab-webapp-slots"
echo "   ./quick-start.sh"
echo "   cat README.md"
echo ""
echo -e "${GREEN}Lykke til med labben! 🚀${NC}"

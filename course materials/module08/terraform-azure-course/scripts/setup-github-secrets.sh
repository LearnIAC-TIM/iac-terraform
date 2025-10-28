#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔐 GitHub Secrets Setup Helper${NC}"
echo ""
echo "Dette scriptet hjelper deg med å sette opp GitHub secrets for Terraform CI/CD."
echo ""

# Les backend.hcl
if [ ! -f "shared/backend.hcl" ]; then
    echo -e "${RED}❌ shared/backend.hcl ikke funnet!${NC}"
    echo -e "${YELLOW}Opprett shared/backend.hcl først ved å kopiere shared/backend.hcl.example${NC}"
    exit 1
fi

# Parse verdier fra backend.hcl
echo -e "${BLUE}📋 Leser backend.hcl...${NC}"
RG_NAME=$(grep 'resource_group_name' shared/backend.hcl | cut -d'"' -f2)
SA_NAME=$(grep 'storage_account_name' shared/backend.hcl | cut -d'"' -f2)
CONTAINER_NAME=$(grep 'container_name' shared/backend.hcl | cut -d'"' -f2)

echo ""
echo -e "${GREEN}✅ Verdier funnet i backend.hcl:${NC}"
echo "  Resource Group: $RG_NAME"
echo "  Storage Account: $SA_NAME"
echo "  Container: $CONTAINER_NAME"
echo ""

# Hent Azure subscription info
echo -e "${BLUE}📋 Henter Azure subscription info...${NC}"

if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI ikke funnet!${NC}"
    echo -e "${YELLOW}Installer Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli${NC}"
    exit 1
fi

# Sjekk om bruker er logget inn
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  Ikke innlogget i Azure CLI${NC}"
    echo "Kjør: az login"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo ""
echo -e "${GREEN}✅ Azure info:${NC}"
echo "  Subscription ID: $SUBSCRIPTION_ID"
echo "  Tenant ID: $TENANT_ID"
echo ""

# Hent Client ID
echo -e "${YELLOW}Du trenger CLIENT_ID fra din App Registration${NC}"
echo ""
echo "For å finne CLIENT_ID:"
echo "  1. Gå til Azure Portal: https://portal.azure.com"
echo "  2. Søk etter 'App registrations'"
echo "  3. Finn din app registration"
echo "  4. Kopier 'Application (client) ID' fra Overview"
echo ""
read -p "Skriv inn CLIENT_ID: " CLIENT_ID

if [ -z "$CLIENT_ID" ]; then
    echo -e "${RED}❌ CLIENT_ID kan ikke være tom${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📝 GitHub Secrets Commands${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Kopier og kjør følgende kommandoer i terminalen:"
echo "(Erstatt <owner>/<repo> med ditt GitHub repository)"
echo ""

cat <<EOF
${GREEN}# Azure credentials${NC}
gh secret set AZURE_CLIENT_ID --body="$CLIENT_ID" --repo <owner>/<repo>
gh secret set AZURE_SUBSCRIPTION_ID --body="$SUBSCRIPTION_ID" --repo <owner>/<repo>
gh secret set AZURE_TENANT_ID --body="$TENANT_ID" --repo <owner>/<repo>

${GREEN}# Terraform backend config${NC}
gh secret set TF_STATE_RG --body="$RG_NAME" --repo <owner>/<repo>
gh secret set TF_STATE_SA --body="$SA_NAME" --repo <owner>/<repo>
gh secret set TF_STATE_CONTAINER --body="$CONTAINER_NAME" --repo <owner>/<repo>
EOF

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Alternativt: Legg til secrets manuelt via GitHub web UI:${NC}"
echo "  1. Gå til ditt GitHub repository"
echo "  2. Settings → Secrets and variables → Actions"
echo "  3. Click 'New repository secret'"
echo "  4. Legg til følgende secrets:"
echo ""
echo -e "${GREEN}Navn: AZURE_CLIENT_ID${NC}"
echo "Verdi: $CLIENT_ID"
echo ""
echo -e "${GREEN}Navn: AZURE_SUBSCRIPTION_ID${NC}"
echo "Verdi: $SUBSCRIPTION_ID"
echo ""
echo -e "${GREEN}Navn: AZURE_TENANT_ID${NC}"
echo "Verdi: $TENANT_ID"
echo ""
echo -e "${GREEN}Navn: TF_STATE_RG${NC}"
echo "Verdi: $RG_NAME"
echo ""
echo -e "${GREEN}Navn: TF_STATE_SA${NC}"
echo "Verdi: $SA_NAME"
echo ""
echo -e "${GREEN}Navn: TF_STATE_CONTAINER${NC}"
echo "Verdi: $CONTAINER_NAME"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ Setup helper completed!${NC}"
echo ""
echo -e "${YELLOW}Neste steg:${NC}"
echo "  1. Kjør kommandoene over for å sette secrets"
echo "  2. Verifiser at alle secrets er satt i GitHub"
echo "  3. Push koden til GitHub for å teste workflows"
echo ""

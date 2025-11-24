#!/bin/bash
# fix-azure-permissions.sh
# Script for å automatisk sjekke og fikse Azure RBAC rettigheter for Terraform

set -e

# Farger
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║   Azure RBAC Permissions Checker & Fixer                  ║
║   For Terraform med GitHub Actions                        ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Sjekk at Azure CLI er installert
if ! command -v az &> /dev/null; then
    echo -e "${RED}ERROR: Azure CLI er ikke installert${NC}"
    echo "Installer: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Sjekk at vi er logget inn
if ! az account show &> /dev/null; then
    echo -e "${RED}ERROR: Ikke logget inn i Azure CLI${NC}"
    echo "Kjør: az login"
    exit 1
fi

# Parametre
MODE="${1:-check}"  # check, fix, eller test
SP_OBJECT_ID="${2}"
BACKEND_STORAGE="${3:-fastrackdemotim3425}"
BACKEND_RG="${4:-rg-terraform-backend-fasttrack}"

# Hvis object ID ikke oppgitt, prøv å hente fra feilmelding eller spør
if [ -z "$SP_OBJECT_ID" ]; then
    echo -e "${YELLOW}Service Principal Object ID ikke oppgitt${NC}"
    echo ""
    echo "Finn Object ID fra:"
    echo "1. Feilmeldingen i GitHub Actions"
    echo "2. Azure Portal → Azure Active Directory → App registrations → din app"
    echo "3. Kjør: az ad sp list --display-name 'sp-github-iac-*' --query '[].{name:displayName, objectId:id}' -o table"
    echo ""
    read -p "Enter Service Principal Object ID: " SP_OBJECT_ID
    
    if [ -z "$SP_OBJECT_ID" ]; then
        echo -e "${RED}ERROR: Object ID er påkrevd${NC}"
        exit 1
    fi
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo "Modus: $MODE"
echo "Service Principal Object ID: $SP_OBJECT_ID"
echo "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "Backend Storage: $BACKEND_STORAGE"
echo "Backend RG: $BACKEND_RG"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Hent SP info
echo "Henter Service Principal informasjon..."
SP_INFO=$(az ad sp show --id "$SP_OBJECT_ID" 2>/dev/null || echo "")

if [ -z "$SP_INFO" ]; then
    echo -e "${RED}ERROR: Fant ikke Service Principal med Object ID: $SP_OBJECT_ID${NC}"
    echo "Sjekk at Object ID er korrekt"
    exit 1
fi

SP_NAME=$(echo "$SP_INFO" | jq -r '.displayName // .appDisplayName // "Unknown"')
SP_APP_ID=$(echo "$SP_INFO" | jq -r '.appId // "Unknown"')

echo -e "${GREEN}✓${NC} Fant Service Principal: $SP_NAME (App ID: $SP_APP_ID)"
echo ""

# Function: Sjekk om role eksisterer
check_role() {
    local scope=$1
    local role=$2
    
    az role assignment list \
        --scope "$scope" \
        --assignee "$SP_OBJECT_ID" \
        --query "[?roleDefinitionName=='$role'].roleDefinitionName" \
        -o tsv 2>/dev/null
}

# Function: Legg til role
add_role() {
    local scope=$1
    local role=$2
    local description=$3
    
    echo -n "  Adding $role to $description... "
    
    if az role assignment create \
        --assignee "$SP_OBJECT_ID" \
        --role "$role" \
        --scope "$scope" \
        --output none 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# Function: Test access
test_access() {
    local test_name=$1
    local command=$2
    
    echo -n "  Testing $test_name... "
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# ============================================
# 1. CHECK TERRAFORM BACKEND STORAGE
# ============================================
echo -e "${BLUE}[1/4] Checking Terraform Backend Storage${NC}"

BACKEND_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$BACKEND_RG/providers/Microsoft.Storage/storageAccounts/$BACKEND_STORAGE"

# Sjekk om storage account eksisterer
if ! az storage account show --name "$BACKEND_STORAGE" --resource-group "$BACKEND_RG" &>/dev/null; then
    echo -e "${RED}✗${NC} Storage Account $BACKEND_STORAGE ikke funnet i $BACKEND_RG"
    echo "  Opprett den først med:"
    echo "    az storage account create --name $BACKEND_STORAGE --resource-group $BACKEND_RG --location northeurope --sku Standard_LRS"
    exit 1
fi

echo -e "${GREEN}✓${NC} Storage Account eksisterer"

# Sjekk rettigheter
BACKEND_ROLE=$(check_role "$BACKEND_SCOPE" "Storage Blob Data Contributor")
BACKEND_ROLE_ALT=$(check_role "$BACKEND_SCOPE" "Contributor")

if [ -n "$BACKEND_ROLE" ]; then
    echo -e "${GREEN}✓${NC} Storage Blob Data Contributor assigned"
    BACKEND_OK=true
elif [ -n "$BACKEND_ROLE_ALT" ]; then
    echo -e "${GREEN}✓${NC} Contributor assigned (alternativ rolle)"
    BACKEND_OK=true
else
    echo -e "${RED}✗${NC} Ingen passende rolle funnet på backend storage"
    BACKEND_OK=false
    
    if [ "$MODE" == "fix" ]; then
        echo "  Fikser rettigheter..."
        add_role "$BACKEND_SCOPE" "Storage Blob Data Contributor" "Backend Storage"
        BACKEND_OK=true
    fi
fi

echo ""

# ============================================
# 2. CHECK DEPLOYMENT RESOURCE GROUPS
# ============================================
echo -e "${BLUE}[2/4] Checking Deployment Resource Groups${NC}"

DEPLOY_RGS=("rg-storage-dev" "rg-storage-test" "rg-storage-prod")
DEPLOY_OK=true

for RG in "${DEPLOY_RGS[@]}"; do
    echo -n "Checking $RG... "
    
    # Sjekk om RG eksisterer
    if ! az group show --name "$RG" &>/dev/null; then
        echo -e "${YELLOW}⚠${NC} Resource Group eksisterer ikke (OK hvis ikke opprettet enda)"
        continue
    fi
    
    RG_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG"
    RG_ROLE=$(check_role "$RG_SCOPE" "Contributor")
    
    if [ -n "$RG_ROLE" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC} Missing Contributor role"
        DEPLOY_OK=false
        
        if [ "$MODE" == "fix" ]; then
            add_role "$RG_SCOPE" "Contributor" "$RG"
        fi
    fi
done

echo ""

# ============================================
# 3. TEST ACTUAL ACCESS
# ============================================
echo -e "${BLUE}[3/4] Testing Actual Access${NC}"

if [ "$MODE" == "test" ] || [ "$MODE" == "fix" ]; then
    # Test backend storage keys
    test_access "Storage Account Keys" \
        "az storage account keys list --account-name $BACKEND_STORAGE --resource-group $BACKEND_RG -o none"
    
    # Test blob access
    test_access "Blob Access (RBAC)" \
        "az storage blob list --container-name tfstate --account-name $BACKEND_STORAGE --auth-mode login -o none"
    
    # Test resource groups
    for RG in "${DEPLOY_RGS[@]}"; do
        if az group show --name "$RG" &>/dev/null; then
            test_access "Access to $RG" \
                "az group show --name $RG -o none"
        fi
    done
fi

echo ""

# ============================================
# 4. SUMMARY & RECOMMENDATIONS
# ============================================
echo -e "${BLUE}[4/4] Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"

if [ "$BACKEND_OK" == true ] && [ "$DEPLOY_OK" == true ]; then
    echo -e "${GREEN}✓ All permissions configured correctly!${NC}"
    echo ""
    echo "Service Principal kan nå:"
    echo "  ✓ Lese og skrive Terraform state til backend storage"
    echo "  ✓ Deploye ressurser til deployment resource groups"
    echo ""
    echo "Neste steg:"
    echo "  1. Kjør GitHub Actions workflow på nytt"
    echo "  2. Verifiser at Terraform init fungerer"
    echo "  3. Sjekk at deployment til dev/test/prod fungerer"
else
    echo -e "${YELLOW}⚠ Some permissions are missing${NC}"
    echo ""
    
    if [ "$MODE" == "check" ]; then
        echo "Kjør med 'fix' mode for å automatisk legge til manglende rettigheter:"
        echo "  $0 fix $SP_OBJECT_ID"
    fi
    
    echo ""
    echo "Eller legg til manuelt:"
    echo ""
    
    if [ "$BACKEND_OK" != true ]; then
        echo "# Backend Storage rettigheter"
        echo "az role assignment create \\"
        echo "  --assignee $SP_OBJECT_ID \\"
        echo "  --role 'Storage Blob Data Contributor' \\"
        echo "  --scope '$BACKEND_SCOPE'"
        echo ""
    fi
    
    if [ "$DEPLOY_OK" != true ]; then
        echo "# Deployment Resource Group rettigheter"
        for RG in "${DEPLOY_RGS[@]}"; do
            if az group show --name "$RG" &>/dev/null; then
                RG_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG"
                RG_ROLE=$(check_role "$RG_SCOPE" "Contributor")
                if [ -z "$RG_ROLE" ]; then
                    echo "az role assignment create \\"
                    echo "  --assignee $SP_OBJECT_ID \\"
                    echo "  --role 'Contributor' \\"
                    echo "  --resource-group '$RG'"
                    echo ""
                fi
            fi
        done
    fi
fi

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Best practices reminder
if [ "$MODE" == "fix" ]; then
    echo -e "${YELLOW}Viktig:${NC} Role assignments kan ta 5-10 minutter å propagere"
    echo "Vent litt før du prøver GitHub Actions workflow på nytt"
fi

echo ""
echo "For mer informasjon, se: azure-permissions-check-guide.md"
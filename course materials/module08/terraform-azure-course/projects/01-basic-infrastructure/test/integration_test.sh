#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🧪 Running integration tests...${NC}"
echo ""

# Sjekk at vi er i riktig mappe
if [ ! -f "main.tf" ]; then
    echo -e "${RED}❌ main.tf ikke funnet. Kjør fra prosjekt-mappen.${NC}"
    exit 1
fi

# Sjekk at Terraform er initialisert
if [ ! -d ".terraform" ]; then
    echo -e "${RED}❌ Terraform ikke initialisert. Kjør 'terraform init' først.${NC}"
    exit 1
fi

# Hent outputs fra Terraform
echo -e "${BLUE}📋 Henter Terraform outputs...${NC}"
RG_NAME=$(terraform output -raw resource_group_name 2>/dev/null)
STORAGE_NAME=$(terraform output -raw storage_account_name 2>/dev/null)

if [ -z "$RG_NAME" ] || [ -z "$STORAGE_NAME" ]; then
    echo -e "${RED}❌ Kunne ikke hente outputs. Er infrastrukturen deployed?${NC}"
    exit 1
fi

echo -e "${BLUE}Testing Resource Group: ${RG_NAME}${NC}"
echo -e "${BLUE}Testing Storage Account: ${STORAGE_NAME}${NC}"
echo ""

# Test 1: Resource Group eksisterer
echo -e "${BLUE}Test 1: Sjekker om Resource Group eksisterer...${NC}"
if az group show --name "$RG_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Resource Group exists${NC}"
else
    echo -e "${RED}❌ Resource Group not found${NC}"
    exit 1
fi

# Test 2: Storage Account eksisterer
echo -e "${BLUE}Test 2: Sjekker om Storage Account eksisterer...${NC}"
if az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Storage Account exists${NC}"
else
    echo -e "${RED}❌ Storage Account not found${NC}"
    exit 1
fi

# Test 3: HTTPS er påkrevd
echo -e "${BLUE}Test 3: Sjekker HTTPS-only innstilling...${NC}"
HTTPS_ONLY=$(az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" --query "enableHttpsTrafficOnly" -o tsv)
if [ "$HTTPS_ONLY" == "true" ]; then
    echo -e "${GREEN}✅ HTTPS traffic only is enabled${NC}"
else
    echo -e "${RED}❌ HTTPS traffic only is NOT enabled${NC}"
    exit 1
fi

# Test 4: TLS version
echo -e "${BLUE}Test 4: Sjekker minimum TLS versjon...${NC}"
TLS_VERSION=$(az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" --query "minimumTlsVersion" -o tsv)
if [ "$TLS_VERSION" == "TLS1_2" ]; then
    echo -e "${GREEN}✅ Minimum TLS version is 1.2${NC}"
else
    echo -e "${RED}❌ TLS version is not 1.2 (found: $TLS_VERSION)${NC}"
    exit 1
fi

# Test 5: Public access er disabled
echo -e "${BLUE}Test 5: Sjekker public access innstilling...${NC}"
PUBLIC_ACCESS=$(az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" --query "allowBlobPublicAccess" -o tsv)
if [ "$PUBLIC_ACCESS" == "false" ]; then
    echo -e "${GREEN}✅ Public blob access is disabled${NC}"
else
    echo -e "${YELLOW}⚠️  Public blob access is enabled (should be false)${NC}"
fi

# Test 6: Tags
echo -e "${BLUE}Test 6: Sjekker påkrevde tags...${NC}"
TAGS=$(az group show --name "$RG_NAME" --query "tags" -o json)
if echo "$TAGS" | grep -q "ManagedBy"; then
    echo -e "${GREEN}✅ Required tags are present${NC}"
else
    echo -e "${RED}❌ Required tags are missing${NC}"
    exit 1
fi

# Test 7: Storage Container eksisterer
echo -e "${BLUE}Test 7: Sjekker storage container...${NC}"
if az storage container show --name "data" --account-name "$STORAGE_NAME" --auth-mode login > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Storage container 'data' exists${NC}"
else
    echo -e "${RED}❌ Storage container 'data' not found${NC}"
    exit 1
fi

# Test 8: Location er i Norge
echo -e "${BLUE}Test 8: Sjekker location...${NC}"
LOCATION=$(az group show --name "$RG_NAME" --query "location" -o tsv)
if [[ "$LOCATION" == "norwayeast" ]] || [[ "$LOCATION" == "norwaywest" ]]; then
    echo -e "${GREEN}✅ Location is in Norway ($LOCATION)${NC}"
else
    echo -e "${YELLOW}⚠️  Location is not in Norway (found: $LOCATION)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 All integration tests passed!${NC}"
echo ""
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "  Resource Group: ${GREEN}${RG_NAME}${NC}"
echo -e "  Storage Account: ${GREEN}${STORAGE_NAME}${NC}"
echo -e "  Location: ${GREEN}${LOCATION}${NC}"
echo -e "  HTTPS Only: ${GREEN}Enabled${NC}"
echo -e "  TLS Version: ${GREEN}1.2${NC}"

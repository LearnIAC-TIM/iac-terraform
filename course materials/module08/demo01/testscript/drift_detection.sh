#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Running drift detection...${NC}"
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

echo -e "${BLUE}Kjører terraform plan for å sjekke drift...${NC}"
echo ""

# Kjør terraform plan og sjekk exit code
# Exit codes:
# 0 = Succeeded with empty diff (no changes)
# 1 = Error
# 2 = Succeeded with non-empty diff (changes present)
terraform plan -detailed-exitcode -out=drift.tfplan

EXIT_CODE=$?

echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ No drift detected${NC}"
    echo -e "${GREEN}Infrastructure matches Terraform code perfectly!${NC}"
    rm -f drift.tfplan
    exit 0
elif [ $EXIT_CODE -eq 2 ]; then
    echo -e "${YELLOW}⚠️  DRIFT DETECTED!${NC}"
    echo ""
    echo -e "${RED}Manual changes have been detected in your infrastructure.${NC}"
    echo -e "${YELLOW}The plan above shows what has changed outside of Terraform.${NC}"
    echo ""
    echo -e "${BLUE}Possible causes:${NC}"
    echo "  • Manual changes via Azure Portal"
    echo "  • Changes via Azure CLI"
    echo "  • Changes by other users/processes"
    echo "  • Azure policy modifications"
    echo ""
    echo -e "${BLUE}Recommended actions:${NC}"
    echo "  1. Review the changes shown above"
    echo "  2. Decide if you want to:"
    echo "     a) Apply Terraform config to fix drift:"
    echo "        ${GREEN}terraform apply drift.tfplan${NC}"
    echo "     b) Update Terraform code to match current state:"
    echo "        ${YELLOW}Update your .tf files and commit${NC}"
    echo "     c) Investigate who made the manual changes"
    echo ""
    rm -f drift.tfplan
    exit 1
else
    echo -e "${RED}❌ Error running terraform plan${NC}"
    echo ""
    echo "Check the error message above for details."
    echo "Common issues:"
    echo "  • Authentication problems"
    echo "  • Network connectivity issues"
    echo "  • State file locking"
    echo ""
    rm -f drift.tfplan
    exit 1
fi

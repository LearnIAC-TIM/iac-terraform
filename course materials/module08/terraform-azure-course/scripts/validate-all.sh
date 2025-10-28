#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔍 Validerer alle Terraform-prosjekter...${NC}"
echo ""

FAILED=0
SUCCEEDED=0
TOTAL=0

for project_dir in projects/*/; do
    if [ ! -d "$project_dir" ]; then
        continue
    fi
    
    PROJECT_NAME=$(basename "$project_dir")
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📁 Validerer: ${PROJECT_NAME}${NC}"
    echo ""
    
    TOTAL=$((TOTAL + 1))
    cd "$project_dir"
    
    # Format check
    echo -n "  Checking format... "
    if terraform fmt -check -recursive > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        echo -e "  ${YELLOW}Run 'terraform fmt' to fix formatting${NC}"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        echo ""
        continue
    fi
    
    # Init (uten backend for rask validering)
    echo -n "  Initializing... "
    if terraform init -backend=false > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        echo ""
        continue
    fi
    
    # Validate
    echo -n "  Validating syntax... "
    if terraform validate > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        echo ""
        echo -e "${YELLOW}Validation errors:${NC}"
        terraform validate
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        echo ""
        continue
    fi
    
    echo -e "  ${GREEN}✨ All checks passed!${NC}"
    SUCCEEDED=$((SUCCEEDED + 1))
    
    cd - > /dev/null
    echo ""
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Resultat:${NC}"
echo ""
echo -e "  Total prosjekter: ${BLUE}${TOTAL}${NC}"
echo -e "  ${GREEN}✅ Succeeded: ${SUCCEEDED}${NC}"
echo -e "  ${RED}❌ Failed: ${FAILED}${NC}"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Some projects failed validation. Please fix the errors above.${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 All projects validated successfully!${NC}"
    exit 0
fi

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

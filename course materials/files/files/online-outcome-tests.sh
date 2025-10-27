#!/bin/bash
set -e

[ -z "$APP_NAME" ] || [ -z "$RESOURCE_GROUP" ] && echo "❌ Sett APP_NAME og RESOURCE_GROUP" && exit 1

STAGING_URL="https://${APP_NAME}-staging.azurewebsites.net"
PROD_URL="https://${APP_NAME}.azurewebsites.net"

echo "🚀 Kjører online outcome tester..."

echo "1️⃣  Health check staging..."
STAGING_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "${STAGING_URL}/health")
[ "$STAGING_HEALTH" = "200" ] && echo "   ✅ Staging healthy" || exit 1

echo "2️⃣  Verifiserer feature toggle..."
STAGING_FEATURE=$(curl -s "${STAGING_URL}/api/info" | grep -o '"featureToggle":[^,}]*')
echo "   📝 Staging feature: $STAGING_FEATURE"

echo "3️⃣  Health check production..."
PROD_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "${PROD_URL}/health")
[ "$PROD_HEALTH" = "200" ] && echo "   ✅ Production healthy" || echo "   ⚠️  Production ikke tilgjengelig"

echo ""
echo "✅ Online outcome tester fullført!"

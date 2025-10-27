#!/bin/bash
set -e

[ -z "$RESOURCE_GROUP" ] || [ -z "$APP_NAME" ] && echo "❌ Sett RESOURCE_GROUP og APP_NAME" && exit 1

echo "🔍 Kjører online verification..."

echo "1️⃣  Sjekker Resource Group..."
az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1 && echo "   ✅ RG eksisterer" || exit 1

echo "2️⃣  Sjekker Web App..."
az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" > /dev/null 2>&1 && echo "   ✅ Web App eksisterer" || exit 1

echo "3️⃣  Sjekker Staging Slot..."
az webapp deployment slot show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --slot staging > /dev/null 2>&1 && echo "   ✅ Staging slot eksisterer" || exit 1

echo "4️⃣  Verifiserer HTTPS-only..."
HTTPS=$(az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query httpsOnly -o tsv)
[ "$HTTPS" = "true" ] && echo "   ✅ HTTPS-only aktivert" || exit 1

echo ""
echo "✅ Online verification fullført!"

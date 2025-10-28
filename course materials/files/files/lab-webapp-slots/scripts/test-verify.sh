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

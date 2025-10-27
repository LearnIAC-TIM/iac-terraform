#!/bin/bash
set -e

[ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] && echo "Bruk: ./deploy-app.sh <app-name> <rg> <slot>" && exit 1

APP_NAME=$1
RG=$2
SLOT=$3

echo "📦 Deployer til $SLOT..."
cd app
npm install
zip -q -r app.zip . -x "node_modules/*"

if [ "$SLOT" = "production" ]; then
  az webapp deployment source config-zip --resource-group "$RG" --name "$APP_NAME" --src app.zip
else
  az webapp deployment source config-zip --resource-group "$RG" --name "$APP_NAME" --slot "$SLOT" --src app.zip
fi

rm app.zip
echo "✅ Deployet til $SLOT!"
[ "$SLOT" = "production" ] && echo "🌐 https://${APP_NAME}.azurewebsites.net" || echo "🌐 https://${APP_NAME}-${SLOT}.azurewebsites.net"

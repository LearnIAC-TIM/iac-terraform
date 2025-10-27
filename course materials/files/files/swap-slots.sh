#!/bin/bash
set -e

[ -z "$1" ] || [ -z "$2" ] && echo "Bruk: ./swap-slots.sh <app-name> <rg>" && exit 1

APP=$1
RG=$2
STAGING="https://${APP}-staging.azurewebsites.net"

echo "🔄 Forbereder swap..."
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "${STAGING}/health")
[ "$HEALTH" != "200" ] && echo "❌ Staging ikke healthy!" && exit 1
echo "   ✅ Staging healthy"

echo ""
read -p "Fortsette med swap? (y/n) " -r
[[ ! $REPLY =~ ^[Yy]$ ]] && echo "❌ Avbrutt" && exit 1

az webapp deployment slot swap --name "$APP" --resource-group "$RG" --slot staging
echo ""
echo "⏳ Venter..."
sleep 10

PROD_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "https://${APP}.azurewebsites.net/health")
[ "$PROD_HEALTH" = "200" ] && echo "✅ Swap vellykket!" || echo "❌ Swap feilet!"

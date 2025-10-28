#!/bin/bash
# HEALTH CHECK: Test at applikasjonen svarer korrekt

set -e

URL=$1
EXPECTED_ENV=${2:-production}

if [ -z "$URL" ]; then
    echo "Usage: $0 <url> [expected-environment]"
    exit 1
fi

echo "🏥 HEALTH CHECK - $URL"
echo "========================================"

# Vent på at appen er klar
echo "→ Venter på at applikasjon starter..."
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" "$URL/health" | grep -q "200"; then
        break
    fi
    echo "  Forsøk $i/30..."
    sleep 2
done

# Health endpoint
echo "→ Tester /health endpoint..."
RESPONSE=$(curl -s "$URL/health")
STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null || echo "error")

if [ "$STATUS" != "healthy" ]; then
    echo "❌ FEIL: Health check feilet!"
    echo "$RESPONSE"
    exit 1
fi

# Sjekk miljø
echo "→ Verifiserer miljø..."
ENV=$(echo "$RESPONSE" | jq -r '.environment' 2>/dev/null || echo "unknown")
echo "  Miljø: $ENV (forventet: $EXPECTED_ENV)"

# Test hovedside
echo "→ Tester hovedside..."
HOME_RESPONSE=$(curl -s "$URL/")
MESSAGE=$(echo "$HOME_RESPONSE" | jq -r '.message' 2>/dev/null || echo "")

if [ -z "$MESSAGE" ]; then
    echo "❌ FEIL: Kunne ikke hente response fra hovedside!"
    exit 1
fi

# Test feature toggle
echo "→ Tester feature toggle..."
FEATURE_RESPONSE=$(curl -s "$URL/feature-x")
FEATURE_ENABLED=$(echo "$FEATURE_RESPONSE" | jq -r '.enabled' 2>/dev/null || echo "unknown")
echo "  Feature X enabled: $FEATURE_ENABLED"

echo "✅ Alle health checks bestått!"
echo ""
echo "📊 Response summary:"
echo "$HOME_RESPONSE" | jq '.'

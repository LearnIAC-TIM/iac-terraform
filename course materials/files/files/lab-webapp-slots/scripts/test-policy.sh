#!/bin/bash
# CONNECTED STATIC ANALYSIS: Policy og compliance

set -e

echo "🔐 POLICY TESTING - Compliance og Sikkerhet"
echo "=========================================="

cd terraform

# Terraform plan
echo "→ Kjører Terraform plan..."
terraform plan -out=tfplan > /dev/null 2>&1

# Konverter plan til JSON for analyse
terraform show -json tfplan > tfplan.json

# Sjekk påkrevde tags
echo "→ Verifiserer påkrevde tags..."
if ! grep -q '"Environment"' tfplan.json || ! grep -q '"ManagedBy"' tfplan.json; then
    echo "❌ FEIL: Påkrevde tags mangler!"
    exit 1
fi

# Sjekk HTTPS-only
echo "→ Verifiserer HTTPS-only policy..."
if grep -q '"https_only.*false' tfplan.json; then
    echo "❌ FEIL: HTTPS-only er ikke aktivert!"
    exit 1
fi

# Sjekk FTP deaktivert
echo "→ Verifiserer FTP er deaktivert..."
if grep -q '"ftp_publish_basic_authentication_enabled.*true' tfplan.json; then
    echo "❌ FEIL: FTP basic auth er aktivert (skal være deaktivert)!"
    exit 1
fi

# Sjekk minimum TLS version
echo "→ Verifiserer TLS 1.2 minimum..."
if grep -q '"minimum_tls_version":"1\.[01]"' tfplan.json; then
    echo "❌ FEIL: TLS versjon er for lav!"
    exit 1
fi

rm tfplan tfplan.json

echo "✅ Alle policy tester bestått!"
cd ..

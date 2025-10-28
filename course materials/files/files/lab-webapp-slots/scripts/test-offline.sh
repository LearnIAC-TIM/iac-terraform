#!/bin/bash
# OFFLINE TESTING: Syntaks og linting

set -e

echo "🔍 OFFLINE TESTING - Syntaks og Sikkerhet"
echo "========================================"

# Terraform validering
echo "→ Validerer Terraform konfigurasjon..."
cd terraform
terraform fmt -check
terraform validate
cd ..

# Python syntax check
echo "→ Sjekker Python syntaks..."
python3 -m py_compile app/app.py

# Sjekk for vanlige sikkerhetsproblemer i kode
echo "→ Sjekker for hardkodet secrets..."
if grep -r "password\|secret\|key" app/*.py | grep -v "FEATURE_TOGGLE"; then
    echo "❌ ADVARSEL: Potensielle hardkodede secrets funnet!"
    exit 1
fi

echo "✅ Alle offline tester bestått!"

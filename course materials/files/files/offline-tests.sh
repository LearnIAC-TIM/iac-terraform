#!/bin/bash
set -e
echo "🔍 Kjører offline tester..."

echo "1️⃣  Validerer Terraform syntaks..."
cd terraform
terraform init -backend=false > /dev/null 2>&1
terraform validate && echo "   ✅ Terraform syntaks OK" || exit 1
cd ..

echo "2️⃣  Sjekker HTTPS-krav..."
grep -q 'https_only *= *true' terraform/main.tf && echo "   ✅ HTTPS påkrevd" || exit 1

echo "3️⃣  Sjekker TLS-versjon..."
grep -q 'minimum_tls_version *= *"1.2"' terraform/main.tf && echo "   ✅ TLS 1.2 satt" || exit 1

echo "4️⃣  Sjekker tags..."
grep -q 'tags *= *var.tags' terraform/main.tf && echo "   ✅ Tags definert" || exit 1

echo ""
echo "✅ Alle offline tester BESTÅTT!"

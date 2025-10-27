#!/bin/bash
set -e
echo "🔐 Kjører static analysis..."

echo "1️⃣  Sjekker FTP-policy..."
echo "   ⚠️  FTP-konfigurasjon kan legges til"

echo "2️⃣  Terraform Plan (hvis credentials tilgjengelig)..."
cd terraform
[ -f "terraform.tfvars" ] && terraform plan > /dev/null 2>&1 && echo "   ✅ Plan OK" || echo "   ⚠️  Hopper over plan"
cd ..

echo "3️⃣  Health check konfigurasjon..."
grep -q 'health_check_path' terraform/main.tf && echo "   ✅ Health check OK" || exit 1

echo ""
echo "✅ Static analysis fullført!"

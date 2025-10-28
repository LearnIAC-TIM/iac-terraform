#!/bin/bash

echo "🚀 Azure Web App Slots Lab - Quick Start"
echo "========================================"
echo ""
echo "Dette scriptet guider deg gjennom setup."
echo ""

read -p "Har du Azure CLI installert? (y/n): " has_az
if [ "$has_az" != "y" ]; then
    echo "❌ Installer Azure CLI først: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

read -p "Har du Terraform installert? (y/n): " has_tf
if [ "$has_tf" != "y" ]; then
    echo "❌ Installer Terraform først: https://www.terraform.io/downloads"
    exit 1
fi

read -p "Er du logget inn i Azure? (y/n): " is_logged
if [ "$is_logged" != "y" ]; then
    echo "→ Logger inn i Azure..."
    az login
fi

echo ""
echo "✅ Prerequisites OK!"
echo ""
echo "📚 Neste steg:"
echo "1. Les README.md for oversikt"
echo "2. Les docs/LAB-GUIDE.md for detaljert guide"
echo "3. Start med 'cd terraform && terraform init'"
echo ""
echo "Lykke til! 🎉"

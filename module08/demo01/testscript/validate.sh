#!/bin/bash
set -e

echo "🔍 Running Terraform validation..."
echo ""

# 1. Terraform Format
echo "📝 Checking Terraform formatting..."
terraform fmt -check -recursive || {
    echo "❌ Run 'terraform fmt -recursive' to fix formatting"
}

# 2. Terraform Validate
echo ""
echo "✅ Running terraform validate..."
terraform validate

# 3. TFLint
echo ""
echo "🔎 Running TFLint..."
tflint --init
tflint

# 4. Checkov
echo ""
echo "🛡️  Running Checkov..."
checkov -d . --compact

echo ""
echo "✅ Validation complete!"
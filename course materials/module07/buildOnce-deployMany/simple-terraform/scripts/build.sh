#!/bin/bash
set -e

echo "📦 Building Terraform Artifact..."
echo ""

# Generate version from git or timestamp
if git rev-parse --git-dir > /dev/null 2>&1; then
  VERSION=$(git rev-parse --short HEAD)
else
  VERSION=$(date +%Y%m%d-%H%M%S)
fi

echo "Version: $VERSION"
echo ""

# Validate Terraform
echo "1️⃣ Validating Terraform..."
cd terraform
terraform fmt -recursive || (echo "⚠️  Run 'terraform fmt -recursive' to fix formatting" && exit 1)
terraform init -backend=false
terraform validate
cd ..

echo "✅ Validation complete!"
echo ""

# Create artifact
echo "2️⃣ Creating artifact..."
ARTIFACT_NAME="terraform-${VERSION}.tar.gz"

tar -czf $ARTIFACT_NAME \
  terraform/ \
  environments/ \
  backend-configs/

echo "✅ Artifact created: $ARTIFACT_NAME"
echo ""

# Show artifact info
echo "📊 Artifact Information:"
ls -lh $ARTIFACT_NAME
echo ""
echo "🎯 Next steps:"
echo "  - Deploy to dev:  ./scripts/deploy.sh dev $ARTIFACT_NAME"
echo "  - Deploy to test: ./scripts/deploy.sh test $ARTIFACT_NAME"

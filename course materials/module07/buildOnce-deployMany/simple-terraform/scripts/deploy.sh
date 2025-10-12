#!/bin/bash
set -e

ENVIRONMENT=$1
ARTIFACT=$2

if [ -z "$ENVIRONMENT" ]; then
  echo "❌ Error: Environment required"
  echo "Usage: ./scripts/deploy.sh <environment> <artifact>"
  exit 1
fi

if [ -z "$ARTIFACT" ]; then
  echo "❌ Error: Artifact required"
  exit 1
fi

if [ ! -f "$ARTIFACT" ]; then
  echo "❌ Error: Artifact not found: $ARTIFACT"
  exit 1
fi

echo "🚀 Deploying to $ENVIRONMENT environment..."
echo ""

# Get subscription ID from Azure CLI
echo "🔍 Getting Azure subscription ID..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

if [ -z "$SUBSCRIPTION_ID" ]; then
  echo "❌ Error: Could not get subscription ID. Please run 'az login' first."
  exit 1
fi

echo "✅ Using subscription: $SUBSCRIPTION_ID"
echo ""

# Export as environment variable for Terraform
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID

# Create workspace
WORKSPACE="workspace-${ENVIRONMENT}"
rm -rf $WORKSPACE
mkdir -p $WORKSPACE

# Extract artifact
echo "1️⃣ Extracting artifact..."
tar -xzf $ARTIFACT -C $WORKSPACE
echo "✅ Artifact extracted"
echo ""

cd $WORKSPACE/terraform

# Initialize with backend
echo "2️⃣ Initializing Terraform..."
terraform init -backend-config=../backend-configs/backend-${ENVIRONMENT}.tfvars
echo ""

# Plan
echo "3️⃣ Planning deployment..."
terraform plan -var-file=../environments/${ENVIRONMENT}.tfvars -out=tfplan
echo ""

# Apply
echo "4️⃣ Applying changes..."
terraform apply -auto-approve tfplan
echo ""

# Show outputs
echo "✅ Deployment complete!"
echo ""
echo "📤 Outputs:"
terraform output

cd ../..

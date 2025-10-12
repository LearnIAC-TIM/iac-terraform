
#!/bin/bash
set -e

echo "🧹 Cleanup Script for Terraform Demo"
echo ""

# Function to destroy environment
destroy_environment() {
    local ENV=$1
    local WORKSPACE="workspace-${ENV}"
    
    echo "───────────────────────────────────────"
    echo "Cleaning up: $ENV environment"
    echo "───────────────────────────────────────"
    echo ""
    
    if [ ! -d "$WORKSPACE" ]; then
        echo "⚠️  Workspace not found: $WORKSPACE"
        echo "   Skipping terraform destroy (use Azure cleanup if needed)"
        echo ""
        return
    fi
    
    # Get subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null)
    if [ -z "$SUBSCRIPTION_ID" ]; then
        echo "❌ Error: Not logged in to Azure"
        echo "   Please run: az login"
        return 1
    fi
    
    export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
    
    cd "$WORKSPACE/terraform"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        echo "🔧 Initializing Terraform..."
        terraform init -backend-config=../backend-configs/backend-${ENV}.tfvars
        echo ""
    fi
    
    # Show what will be destroyed
    echo "📋 Planning destruction..."
    terraform plan -destroy -var-file=../environments/${ENV}.tfvars
    echo ""
    
    # Confirm
    read -p "❓ Destroy $ENV environment? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "⏭️  Skipped $ENV"
        cd ../..
        echo ""
        return
    fi
    
    # Destroy
    echo ""
    echo "💥 Destroying infrastructure..."
    terraform destroy -var-file=../environments/${ENV}.tfvars -auto-approve
    
    cd ../..
    echo ""
    echo "✅ $ENV environment destroyed"
    echo ""
}

# Main menu
echo "Select cleanup option:"
echo ""
echo "  1) Destroy DEV environment"
echo "  2) Destroy TEST environment"
echo "  3) Destroy PROD environment"
echo "  4) Destroy ALL environments"
echo "  5) Clean local files only (workspaces, artifacts)"
echo "  6) Force cleanup via Azure CLI (if terraform fails)"
echo "  7) Full cleanup (everything)"
echo "  0) Cancel"
echo ""
read -p "Enter choice [0-7]: " choice

case $choice in
    1)
        destroy_environment "dev"
        ;;
    2)
        destroy_environment "test"
        ;;
    3)
        destroy_environment "prod"
        ;;
    4)
        destroy_environment "dev"
        destroy_environment "test"
        destroy_environment "prod"
        ;;
    5)
        echo "🧹 Cleaning local files..."
        echo ""
        
        # Remove workspaces
        if ls -d workspace-* 2>/dev/null; then
            echo "  Removing workspaces..."
            rm -rf workspace-*
            echo "  ✅ Workspaces removed"
        fi
        
        # Remove artifacts
        if ls terraform-*.tar.gz 2>/dev/null; then
            echo "  Removing artifacts..."
            rm -f terraform-*.tar.gz
            echo "  ✅ Artifacts removed"
        fi
        
        echo ""
        echo "✅ Local cleanup complete"
        echo ""
        ;;
    6)
        echo "💥 Force cleanup via Azure CLI"
        echo ""
        echo "⚠️  WARNING: This will delete resource groups directly!"
        echo "   Use this only if terraform destroy fails."
        echo ""
        read -p "Continue? (yes/no): " confirm
        
        if [ "$confirm" == "yes" ]; then
            echo ""
            echo "Available resource groups:"
            az group list --query "[?starts_with(name, 'rg-demo-')].{Name:name, Location:location}" -o table
            echo ""
            read -p "Enter resource group name to delete (or 'all' for all demo groups): " rg_name
            
            if [ "$rg_name" == "all" ]; then
                echo ""
                echo "🔥 Deleting all demo resource groups..."
                for rg in $(az group list --query "[?starts_with(name, 'rg-demo-')].name" -o tsv); do
                    echo "  Deleting: $rg"
                    az group delete --name "$rg" --yes --no-wait
                done
                echo ""
                echo "✅ Deletion initiated (running in background)"
                echo "   Check status: az group list -o table"
            elif [ ! -z "$rg_name" ]; then
                echo ""
                echo "🔥 Deleting: $rg_name"
                az group delete --name "$rg_name" --yes --no-wait
                echo ""
                echo "✅ Deletion initiated"
            fi
        fi
        echo ""
        ;;
    7)
        echo "🔥 FULL CLEANUP - Everything will be removed!"
        echo ""
        read -p "Are you sure? (yes/no): " confirm
        
        if [ "$confirm" == "yes" ]; then
            # Destroy all environments
            destroy_environment "dev"
            destroy_environment "test"
            destroy_environment "prod"
            
            # Clean local files
            echo "🧹 Cleaning local files..."
            rm -rf workspace-*
            rm -f terraform-*.tar.gz
            
            echo ""
            echo "✅ Full cleanup complete!"
        fi
        echo ""
        ;;
    0)
        echo "Cancelled"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo "───────────────────────────────────────"
echo "Cleanup script finished"
echo "───────────────────────────────────────"

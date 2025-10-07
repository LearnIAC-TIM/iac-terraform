#!/usr/bin/env pwsh
# Cleanup script for Windows (PowerShell)

$ErrorActionPreference = "Stop"

function Destroy-Environment {
    param(
        [string]$Environment
    )
    
    $WORKSPACE = "workspace-$Environment"
    
    Write-Host ""
    Write-Host "───────────────────────────────────────" -ForegroundColor Cyan
    Write-Host "Cleaning up: $Environment environment" -ForegroundColor Yellow
    Write-Host "───────────────────────────────────────" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $WORKSPACE)) {
        Write-Host "⚠️  Workspace not found: $WORKSPACE" -ForegroundColor Yellow
        Write-Host "   Skipping terraform destroy (use Azure cleanup if needed)" -ForegroundColor Gray
        Write-Host ""
        return
    }
    
    # Get subscription ID
    $SUBSCRIPTION_ID = az account show --query id -o tsv 2>$null
    if ([string]::IsNullOrEmpty($SUBSCRIPTION_ID)) {
        Write-Host "❌ Error: Not logged in to Azure" -ForegroundColor Red
        Write-Host "   Please run: az login" -ForegroundColor Yellow
        return
    }
    
    $env:ARM_SUBSCRIPTION_ID = $SUBSCRIPTION_ID
    
    Push-Location "$WORKSPACE/terraform"
    
    try {
        # Initialize if needed
        if (-not (Test-Path ".terraform")) {
            Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
            terraform init -backend-config="../backend-configs/backend-$Environment.tfvars"
            Write-Host ""
        }
        
        # Show what will be destroyed
        Write-Host "📋 Planning destruction..." -ForegroundColor Yellow
        terraform plan -destroy -var-file="../environments/$Environment.tfvars"
        Write-Host ""
        
        # Confirm
        $confirm = Read-Host "❓ Destroy $Environment environment? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Host "⏭️  Skipped $Environment" -ForegroundColor Gray
            Pop-Location
            Write-Host ""
            return
        }
        
        # Destroy
        Write-Host ""
        Write-Host "💥 Destroying infrastructure..." -ForegroundColor Red
        terraform destroy -var-file="../environments/$Environment.tfvars" -auto-approve
        
        Write-Host ""
        Write-Host "✅ $Environment environment destroyed" -ForegroundColor Green
        Write-Host ""
        
    } finally {
        Pop-Location
    }
}

# Main menu
Write-Host ""
Write-Host "🧹 Cleanup Script for Terraform Demo" -ForegroundColor Green
Write-Host ""
Write-Host "Select cleanup option:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1) Destroy DEV environment"
Write-Host "  2) Destroy TEST environment"
Write-Host "  3) Destroy PROD environment"
Write-Host "  4) Destroy ALL environments"
Write-Host "  5) Clean local files only (workspaces, artifacts)"
Write-Host "  6) Force cleanup via Azure CLI (if terraform fails)"
Write-Host "  7) Full cleanup (everything)"
Write-Host "  0) Cancel"
Write-Host ""

$choice = Read-Host "Enter choice [0-7]"

switch ($choice) {
    "1" {
        Destroy-Environment -Environment "dev"
    }
    "2" {
        Destroy-Environment -Environment "test"
    }
    "3" {
        Destroy-Environment -Environment "prod"
    }
    "4" {
        Destroy-Environment -Environment "dev"
        Destroy-Environment -Environment "test"
        Destroy-Environment -Environment "prod"
    }
    "5" {
        Write-Host "🧹 Cleaning local files..." -ForegroundColor Yellow
        Write-Host ""
        
        # Remove workspaces
        $workspaces = Get-ChildItem -Directory -Filter "workspace-*" -ErrorAction SilentlyContinue
        if ($workspaces) {
            Write-Host "  Removing workspaces..." -ForegroundColor Gray
            Remove-Item -Recurse -Force workspace-*
            Write-Host "  ✅ Workspaces removed" -ForegroundColor Green
        }
        
        # Remove artifacts
        $artifacts = Get-ChildItem -File -Filter "terraform-*.tar.gz" -ErrorAction SilentlyContinue
        if ($artifacts) {
            Write-Host "  Removing artifacts..." -ForegroundColor Gray
            Remove-Item -Force terraform-*.tar.gz
            Write-Host "  ✅ Artifacts removed" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "✅ Local cleanup complete" -ForegroundColor Green
        Write-Host ""
    }
    "6" {
        Write-Host "💥 Force cleanup via Azure CLI" -ForegroundColor Red
        Write-Host ""
        Write-Host "⚠️  WARNING: This will delete resource groups directly!" -ForegroundColor Yellow
        Write-Host "   Use this only if terraform destroy fails." -ForegroundColor Gray
        Write-Host ""
        
        $confirm = Read-Host "Continue? (yes/no)"
        
        if ($confirm -eq "yes") {
            Write-Host ""
            Write-Host "Available resource groups:" -ForegroundColor Cyan
            az group list --query "[?starts_with(name, 'rg-demo-')].{Name:name, Location:location}" -o table
            Write-Host ""
            
            $rg_name = Read-Host "Enter resource group name to delete (or 'all' for all demo groups)"
            
            if ($rg_name -eq "all") {
                Write-Host ""
                Write-Host "🔥 Deleting all demo resource groups..." -ForegroundColor Red
                $groups = az group list --query "[?starts_with(name, 'rg-demo-')].name" -o tsv
                foreach ($rg in $groups) {
                    Write-Host "  Deleting: $rg" -ForegroundColor Gray
                    az group delete --name $rg --yes --no-wait
                }
                Write-Host ""
                Write-Host "✅ Deletion initiated (running in background)" -ForegroundColor Green
                Write-Host "   Check status: az group list -o table" -ForegroundColor Gray
            } elseif (-not [string]::IsNullOrEmpty($rg_name)) {
                Write-Host ""
                Write-Host "🔥 Deleting: $rg_name" -ForegroundColor Red
                az group delete --name $rg_name --yes --no-wait
                Write-Host ""
                Write-Host "✅ Deletion initiated" -ForegroundColor Green
            }
        }
        Write-Host ""
    }
    "7" {
        Write-Host "🔥 FULL CLEANUP - Everything will be removed!" -ForegroundColor Red
        Write-Host ""
        $confirm = Read-Host "Are you sure? (yes/no)"
        
        if ($confirm -eq "yes") {
            # Destroy all environments
            Destroy-Environment -Environment "dev"
            Destroy-Environment -Environment "test"
            Destroy-Environment -Environment "prod"
            
            # Clean local files
            Write-Host "🧹 Cleaning local files..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force workspace-* -ErrorAction SilentlyContinue
            Remove-Item -Force terraform-*.tar.gz -ErrorAction SilentlyContinue
            
            Write-Host ""
            Write-Host "✅ Full cleanup complete!" -ForegroundColor Green
        }
        Write-Host ""
    }
    "0" {
        Write-Host "Cancelled" -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit 1
    }
}

Write-Host "───────────────────────────────────────" -ForegroundColor Cyan
Write-Host "Cleanup script finished" -ForegroundColor Green
Write-Host "───────────────────────────────────────" -ForegroundColor Cyan
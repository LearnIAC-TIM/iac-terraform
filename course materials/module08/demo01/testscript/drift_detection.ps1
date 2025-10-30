#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# Farger for output
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Error { Write-Host "❌ $args" -ForegroundColor Red }
function Write-Info { Write-Host "$args" -ForegroundColor Cyan }
function Write-Warning { Write-Host "⚠️  $args" -ForegroundColor Yellow }

Write-Host "🔍 Running drift detection..." -ForegroundColor Blue
Write-Host ""

# Sjekk at vi er i riktig mappe
if (-not (Test-Path "main.tf")) {
    Write-Error "main.tf ikke funnet. Kjør fra prosjekt-mappen."
    exit 1
}

# Sjekk at Terraform er initialisert
if (-not (Test-Path ".terraform")) {
    Write-Error "Terraform ikke initialisert. Kjør 'terraform init' først."
    exit 1
}

Write-Host "Kjører terraform plan for å sjekke drift..." -ForegroundColor Blue
Write-Host ""

# Kjør terraform plan og sjekk exit code
# Exit codes:
# 0 = Succeeded with empty diff (no changes)
# 1 = Error
# 2 = Succeeded with non-empty diff (changes present)

# Kjør terraform plan uten å stoppe på feil
$ErrorActionPreference = "Continue"
& terraform plan -detailed-exitcode -out drift.tfplan
$EXIT_CODE = $LASTEXITCODE
$ErrorActionPreference = "Stop"

Write-Host ""

if ($EXIT_CODE -eq 0) {
    Write-Host "✅ No drift detected" -ForegroundColor Green
    Write-Host "Infrastructure matches Terraform code perfectly!" -ForegroundColor Green
    
    if (Test-Path "drift.tfplan") {
        Remove-Item "drift.tfplan" -Force
    }
    exit 0
}
elseif ($EXIT_CODE -eq 2) {
    Write-Host "⚠️  DRIFT DETECTED!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual changes have been detected in your infrastructure." -ForegroundColor Red
    Write-Host "The plan above shows what has changed outside of Terraform." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Possible causes:" -ForegroundColor Blue
    Write-Host "  • Manual changes via Azure Portal"
    Write-Host "  • Changes via Azure CLI"
    Write-Host "  • Changes by other users/processes"
    Write-Host "  • Azure policy modifications"
    Write-Host ""
    Write-Host "Recommended actions:" -ForegroundColor Blue
    Write-Host "  1. Review the changes shown above"
    Write-Host "  2. Decide if you want to:"
    Write-Host "     a) Apply Terraform config to fix drift:"
    Write-Host "        terraform apply drift.tfplan" -ForegroundColor Green
    Write-Host "     b) Update Terraform code to match current state:"
    Write-Host "        Update your .tf files and commit" -ForegroundColor Yellow
    Write-Host "     c) Investigate who made the manual changes"
    Write-Host ""
    
    if (Test-Path "drift.tfplan") {
        Remove-Item "drift.tfplan" -Force
    }
    exit 1
}
else {
    Write-Host "❌ Error running terraform plan" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the error message above for details."
    Write-Host "Common issues:"
    Write-Host "  • Authentication problems"
    Write-Host "  • Network connectivity issues"
    Write-Host "  • State file locking"
    Write-Host ""
    
    if (Test-Path "drift.tfplan") {
        Remove-Item "drift.tfplan" -Force
    }
    exit 1
}
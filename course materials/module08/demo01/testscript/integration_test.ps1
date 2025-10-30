#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# Farger for output
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Error { Write-Host "❌ $args" -ForegroundColor Red }
function Write-Info { Write-Host "📋 $args" -ForegroundColor Cyan }
function Write-Warning { Write-Host "⚠️  $args" -ForegroundColor Yellow }
function Write-Title { Write-Host "`n$args" -ForegroundColor Blue }

Write-Host "🧪 Running integration tests..." -ForegroundColor Blue
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

# Hent outputs fra Terraform
Write-Info "Henter Terraform outputs..."
try {
    $RG_NAME = terraform output -raw resource_group_name 2>$null
    $STORAGE_NAME = terraform output -raw storage_account_name 2>$null
    
    if ([string]::IsNullOrEmpty($RG_NAME) -or [string]::IsNullOrEmpty($STORAGE_NAME)) {
        throw "Kunne ikke hente outputs"
    }
} catch {
    Write-Error "Kunne ikke hente outputs. Er infrastrukturen deployed?"
    exit 1
}

Write-Host "Testing Resource Group: $RG_NAME" -ForegroundColor Blue
Write-Host "Testing Storage Account: $STORAGE_NAME" -ForegroundColor Blue
Write-Host ""

# Test 1: Resource Group eksisterer
Write-Title "Test 1: Sjekker om Resource Group eksisterer..."
try {
    az group show --name $RG_NAME --output none 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Resource Group exists"
    } else {
        throw "Resource Group not found"
    }
} catch {
    Write-Error "Resource Group not found"
    exit 1
}

# Test 2: Storage Account eksisterer
Write-Title "Test 2: Sjekker om Storage Account eksisterer..."
try {
    az storage account show --name $STORAGE_NAME --resource-group $RG_NAME --output none 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Storage Account exists"
    } else {
        throw "Storage Account not found"
    }
} catch {
    Write-Error "Storage Account not found"
    exit 1
}

# Test 3: HTTPS er påkrevd
Write-Title "Test 3: Sjekker HTTPS-only innstilling..."
$HTTPS_ONLY = az storage account show --name $STORAGE_NAME --resource-group $RG_NAME --query "enableHttpsTrafficOnly" -o tsv
if ($HTTPS_ONLY -eq "true") {
    Write-Success "HTTPS traffic only is enabled"
} else {
    Write-Error "HTTPS traffic only is NOT enabled"
    exit 1
}

# Test 4: TLS version
Write-Title "Test 4: Sjekker minimum TLS versjon..."
$TLS_VERSION = az storage account show --name $STORAGE_NAME --resource-group $RG_NAME --query "minimumTlsVersion" -o tsv
if ($TLS_VERSION -eq "TLS1_2") {
    Write-Success "Minimum TLS version is 1.2"
} else {
    Write-Error "TLS version is not 1.2 (found: $TLS_VERSION)"
    exit 1
}

# Test 5: Public access er disabled
Write-Title "Test 5: Sjekker public access innstilling..."
$PUBLIC_ACCESS = az storage account show --name $STORAGE_NAME --resource-group $RG_NAME --query "allowBlobPublicAccess" -o tsv
if ($PUBLIC_ACCESS -eq "false") {
    Write-Success "Public blob access is disabled"
} else {
    Write-Warning "Public blob access is enabled (should be false)"
}

# Test 6: Tags
Write-Title "Test 6: Sjekker påkrevde tags..."
$TAGS = az group show --name $RG_NAME --query "tags" -o json | ConvertFrom-Json
if ($TAGS.PSObject.Properties.Name -contains "ManagedBy") {
    Write-Success "Required tags are present"
} else {
    Write-Error "Required tags are missing"
    exit 1
}

# Test 7: Storage Container eksisterer
Write-Title "Test 7: Sjekker storage container..."
try {
    az storage container show --name "data" --account-name $STORAGE_NAME --auth-mode login --output none 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Storage container 'data' exists"
    } else {
        throw "Container not found"
    }
} catch {
    Write-Error "Storage container 'data' not found"
    exit 1
}

# Test 8: Location er i Norge
Write-Title "Test 8: Sjekker location..."
$LOCATION = az group show --name $RG_NAME --query "location" -o tsv
if ($LOCATION -in @("norwayeast", "norwaywest")) {
    Write-Success "Location is in Norway ($LOCATION)"
} else {
    Write-Warning "Location is not in Norway (found: $LOCATION)"
}

Write-Host ""
Write-Host "🎉 All integration tests passed!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Blue
Write-Host "  Resource Group: " -NoNewline
Write-Host $RG_NAME -ForegroundColor Green
Write-Host "  Storage Account: " -NoNewline
Write-Host $STORAGE_NAME -ForegroundColor Green
Write-Host "  Location: " -NoNewline
Write-Host $LOCATION -ForegroundColor Green
Write-Host "  HTTPS Only: " -NoNewline
Write-Host "Enabled" -ForegroundColor Green
Write-Host "  TLS Version: " -NoNewline
Write-Host "1.2" -ForegroundColor Green
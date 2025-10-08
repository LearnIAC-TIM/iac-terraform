# Terraform Deploy Script - PowerShell Veiledning

## Oversikt

Dette PowerShell-scriptet (`deploy.ps1`) automatiserer deployment av Terraform-infrastruktur til Azure fra Windows-miljøer. Scriptet bruker **avanserte PowerShell-features** som parameter validation, CmdletBinding, og robust error handling for en enterprise-kvalitet deployment-prosess.

## Nøkkelforskjeller fra Bash-versjonen

| Aspekt | Bash | PowerShell |
|--------|------|------------|
| **Parameter handling** | Posisjonelle args (`$1`, `$2`) | Named parameters med validation |
| **Input validation** | Manuelle if-sjekker | `[ValidateSet]`, `[ValidateScript]` |
| **Artefakt-støtte** | Kun `.tar.gz` | Både `.tar.gz` og `.zip` |
| **Error messages** | Enkle echo-meldinger | Fargede, strukturerte meldinger |
| **Path joining** | String concatenation | `Join-Path` (cross-platform) |
| **File checks** | `[ -f "$file" ]` | `Test-Path -PathType Leaf` |

## Forutsetninger

### Nødvendig Programvare
- **PowerShell 5.1+** eller **PowerShell Core 7+**
- **Terraform CLI** (versjon 1.0+)
- **Azure CLI** (`az`) installert og konfigurert
- **tar** (for .tar.gz artifacts) - valgfritt hvis kun .zip brukes

### Azure-tilganger
- Gyldig Azure-abonnement
- Contributor eller Owner rolle
- Tilgang til Terraform state storage

### Verifiser Setup

```powershell
# Sjekk PowerShell versjon
$PSVersionTable.PSVersion

# Sjekk Azure CLI
az --version

# Sjekk Terraform
terraform version

# Sjekk tar (valgfritt)
Get-Command tar -ErrorAction SilentlyContinue

# Login til Azure
az login
```

## Detaljert Gjennomgang

### 1. CmdletBinding og Parametere

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$Artifact
)
```

**Dette er kraftig PowerShell-funksjonalitet!**

#### CmdletBinding
```powershell
[CmdletBinding()]
```
- Gjør scriptet til en "advanced function"
- Muliggjør `-Verbose`, `-Debug`, `-ErrorAction` parametere
- Gir bedre error handling og logging

**Eksempel bruk:**
```powershell
.\deploy.ps1 -Environment dev -Artifact build.tar.gz -Verbose
.\deploy.ps1 -Environment dev -Artifact build.tar.gz -Debug
```

#### Parameter Attributes

**Mandatory:**
```powershell
[Parameter(Mandatory=$true, Position=0)]
```
- `Mandatory=$true` - Parameteren MÅ oppgis
- `Position=0` - Kan oppgis som første posisjonelt argument
- PowerShell vil prompte hvis parameteren mangler

**ValidateSet:**
```powershell
[ValidateSet("dev", "test", "prod")]
```
- Kun disse verdiene er tillatt
- Tab completion viser kun gyldige valg
- Automatisk error hvis ugyldig verdi

**Eksempel:**
```powershell
# Gyldig
.\deploy.ps1 -Environment dev -Artifact build.tar.gz

# Ugyldig - gir error før scriptet kjører
.\deploy.ps1 -Environment production -Artifact build.tar.gz
# Error: Cannot validate argument on parameter 'Environment'
```

**ValidateScript:**
```powershell
[ValidateScript({Test-Path $_ -PathType Leaf})]
```
- `$_` - Verdien som brukeren oppgir
- `Test-Path -PathType Leaf` - Sjekker at filen eksisterer
- Validering kjøres FØR scriptet starter

**Fordeler:**
- ✅ Feil oppdages umiddelbart
- ✅ Ingen behov for manuell validering i script-body
- ✅ Bedre feilmeldinger
- ✅ Selvdokumenterende

#### Syntaks-alternativer

```powershell
# Named parameters (anbefalt)
.\deploy.ps1 -Environment dev -Artifact terraform-abc123.tar.gz

# Posisjonelle parametere
.\deploy.ps1 dev terraform-abc123.tar.gz

# Med splatting (avansert)
$params = @{
    Environment = "dev"
    Artifact = "terraform-abc123.tar.gz"
}
.\deploy.ps1 @params
```

### 2. Azure Subscription Henting

```powershell
Write-Host "🔍 Getting Azure subscription ID..." -ForegroundColor Yellow

try {
    $subscriptionId = az account show --query id -o tsv 2>$null
    
    if ([string]::IsNullOrEmpty($subscriptionId) -or $LASTEXITCODE -ne 0) {
        Write-Host "❌ Error: Could not get subscription ID. Please run 'az login' first." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Using subscription: $subscriptionId" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "❌ Error: Azure CLI not available or not logged in." -ForegroundColor Red
    Write-Host "   Please install Azure CLI and run 'az login'" -ForegroundColor Gray
    exit 1
}

# Export as environment variable for Terraform
$env:ARM_SUBSCRIPTION_ID = $subscriptionId
```

**Forklaring:**

#### String Validation
```powershell
[string]::IsNullOrEmpty($subscriptionId)
```
- .NET String-klassen
- Sjekker om string er null ELLER tom
- Bedre enn bare `if (-not $subscriptionId)`

**Alternativer:**
```powershell
[string]::IsNullOrEmpty($str)      # Null eller ""
[string]::IsNullOrWhiteSpace($str) # Null, "" eller "   "
-not $str                          # PowerShell implicit check
```

#### Multiple Conditions
```powershell
if ([string]::IsNullOrEmpty($subscriptionId) -or $LASTEXITCODE -ne 0)
```
- `-or` - Logisk OR operator
- `-and` - Logisk AND operator
- `-ne` - Not Equal (!=)

**Operatorer i PowerShell:**
```powershell
-eq    # Equal (==)
-ne    # Not equal (!=)
-gt    # Greater than (>)
-lt    # Less than (<)
-ge    # Greater or equal (>=)
-le    # Less or equal (<=)
-like  # Wildcard match
-match # Regex match
-and   # Logical AND
-or    # Logical OR
-not   # Logical NOT
```

#### Environment Variable
```powershell
$env:ARM_SUBSCRIPTION_ID = $subscriptionId
```
- Setter environment variable for nåværende session
- Terraform leser `ARM_SUBSCRIPTION_ID`
- Tilsvarende `export` i Bash

**Permanente env vars:**
```powershell
# User-level (anbefalt)
[Environment]::SetEnvironmentVariable(
    "ARM_SUBSCRIPTION_ID", 
    $subscriptionId, 
    [EnvironmentVariableTarget]::User
)

# System-level (krever admin)
[Environment]::SetEnvironmentVariable(
    "ARM_SUBSCRIPTION_ID", 
    $subscriptionId, 
    [EnvironmentVariableTarget]::Machine
)
```

### 3. Workspace Management

```powershell
$workspace = "workspace-$Environment"

if (Test-Path $workspace) {
    Write-Host "🧹 Removing old workspace..." -ForegroundColor Gray
    Remove-Item -Path $workspace -Recurse -Force
}

New-Item -ItemType Directory -Path $workspace -Force | Out-Null
```

**Forklaring:**

#### Test-Path
```powershell
Test-Path $workspace
```
- Returnerer `$true` eller `$false`
- Sjekker om fil eller mappe eksisterer
- Mer robust enn Bash `[ -d "$dir" ]`

**Avansert bruk:**
```powershell
Test-Path $workspace -PathType Container  # Kun mapper
Test-Path $file -PathType Leaf           # Kun filer
Test-Path $path -NewerThan (Get-Date).AddDays(-7)  # Nyere enn 7 dager
```

#### Remove-Item
```powershell
Remove-Item -Path $workspace -Recurse -Force
```
- `-Recurse` - Slett alt innhold
- `-Force` - Ingen bekreftelse, slett readonly files
- Tilsvarende `rm -rf` i Bash

**Sikker sletting:**
```powershell
# Med bekreftelse
Remove-Item -Path $workspace -Recurse -Confirm

# Dry run (vis hva som ville blitt slettet)
Remove-Item -Path $workspace -Recurse -WhatIf
```

#### New-Item
```powershell
New-Item -ItemType Directory -Path $workspace -Force | Out-Null
```
- `-ItemType Directory` - Opprett mappe (ikke fil)
- `-Force` - Overskriver/ignorerer hvis eksisterer
- `| Out-Null` - Skjul output

**Andre ItemTypes:**
```powershell
New-Item -ItemType File -Path "file.txt"
New-Item -ItemType SymbolicLink -Path "link" -Target "original"
New-Item -ItemType HardLink -Path "hardlink" -Target "file.txt"
```

### 4. Artefakt-Ekstraksjon

```powershell
Write-Host "1️⃣ Extracting artifact..." -ForegroundColor Yellow

try {
    # Check file extension
    $extension = [System.IO.Path]::GetExtension($Artifact)
    
    if ($extension -eq ".gz" -or $Artifact -like "*.tar.gz") {
        # Check if tar is available
        $tarAvailable = Get-Command tar -ErrorAction SilentlyContinue
        
        if ($tarAvailable) {
            tar -xzf $Artifact -C $workspace
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to extract tar.gz artifact"
            }
        } else {
            Write-Host "❌ Error: Artifact is .tar.gz but tar command not available" -ForegroundColor Red
            Write-Host "   Please install Git for Windows or use Windows 10 1803+" -ForegroundColor Gray
            exit 1
        }
    } elseif ($extension -eq ".zip") {
        Expand-Archive -Path $Artifact -DestinationPath $workspace -Force
    } else {
        Write-Host "❌ Error: Unsupported artifact format: $extension" -ForegroundColor Red
        Write-Host "   Supported formats: .tar.gz, .zip" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "✅ Artifact extracted" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "❌ Error extracting artifact: $_" -ForegroundColor Red
    exit 1
}
```

**Forklaring:**

#### .NET Path Class
```powershell
$extension = [System.IO.Path]::GetExtension($Artifact)
```
- Bruker .NET's System.IO.Path klasse
- Pålitelig ekstraksjon av filextension
- Returnerer f.eks. `.zip`, `.gz`

**Andre Path-metoder:**
```powershell
[System.IO.Path]::GetExtension("file.tar.gz")     # .gz
[System.IO.Path]::GetFileName("C:\path\file.txt") # file.txt
[System.IO.Path]::GetFileNameWithoutExtension("file.txt") # file
[System.IO.Path]::GetDirectoryName("C:\path\file.txt")    # C:\path
[System.IO.Path]::Combine("C:\path", "file.txt")  # C:\path\file.txt
```

#### Wildcard Matching
```powershell
$Artifact -like "*.tar.gz"
```
- `-like` - Wildcard matching operator
- `*` - Match anything
- Case-insensitive by default

**Eksempler:**
```powershell
"hello.txt" -like "*.txt"        # True
"hello.txt" -like "h*"           # True
"HELLO.txt" -like "hello*"       # True (case-insensitive)
"hello.txt" -clike "HELLO*"      # False (case-sensitive)
```

#### Expand-Archive
```powershell
Expand-Archive -Path $Artifact -DestinationPath $workspace -Force
```
- Native PowerShell zip-ekstraksjon
- `-Force` - Overskriver eksisterende filer
- Fungerer kun med .zip (ikke .tar.gz)

**Avansert bruk:**
```powershell
# Ekstraher kun spesifikke filer
Expand-Archive -Path archive.zip -DestinationPath temp
Get-ChildItem temp -Filter "*.tf" | Copy-Item -Destination final

# Vis innhold uten å ekstraktere
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::OpenRead("archive.zip").Entries
```

### 5. Path Joining og Validering

```powershell
$terraformPath = Join-Path $workspace "terraform"

if (-not (Test-Path $terraformPath)) {
    Write-Host "❌ Error: terraform/ directory not found in artifact" -ForegroundColor Red
    exit 1
}

Push-Location $terraformPath
```

**Forklaring:**

#### Join-Path
```powershell
Join-Path $workspace "terraform"
```
- Kombinerer paths på riktig måte
- Håndterer \ og / automatisk
- Cross-platform (fungerer på Linux/Mac med PowerShell Core)

**Hvorfor bedre enn string concatenation:**
```powershell
# Dårlig (kan feile)
$path = $workspace + "\terraform"        # Feiler på Linux
$path = "$workspace\terraform"           # Feiler på Linux

# Bra (fungerer overalt)
$path = Join-Path $workspace "terraform" # Fungerer Windows/Linux/Mac
```

**Avansert:**
```powershell
# Multiple paths
Join-Path $workspace "terraform" "main.tf"

# Med variable
Join-Path $workspace "environments" "$Environment.tfvars"

# Array av paths
$paths = @("terraform", "environments", "backend-configs")
$paths | ForEach-Object { Join-Path $workspace $_ }
```

#### -not Operator
```powershell
if (-not (Test-Path $terraformPath))
```
- `-not` - Logical NOT
- Motsatt av test-resultatet
- Tilsvarende `!` i andre språk

**Alternativer:**
```powershell
-not (Test-Path $path)  # Explicit NOT
!(Test-Path $path)      # ! notation
Test-Path $path -eq $false  # Comparison
```

### 6. Terraform Operasjoner

```powershell
Push-Location $terraformPath

try {
    # Initialize with backend
    Write-Host "2️⃣ Initializing Terraform..." -ForegroundColor Yellow
    
    $backendConfig = Join-Path ".." "backend-configs" "backend-$Environment.tfvars"
    
    if (-not (Test-Path $backendConfig)) {
        Write-Host "❌ Error: Backend config not found: $backendConfig" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    terraform init -backend-config=$backendConfig
    
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed"
    }
    
    Write-Host ""
    
    # Plan
    Write-Host "3️⃣ Planning deployment..." -ForegroundColor Yellow
    
    $envVarsFile = Join-Path ".." "environments" "$Environment.tfvars"
    
    if (-not (Test-Path $envVarsFile)) {
        Write-Host "❌ Error: Environment variables file not found: $envVarsFile" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    terraform plan -var-file=$envVarsFile -out=tfplan
    
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed"
    }
    
    Write-Host ""
    
    # Apply
    Write-Host "4️⃣ Applying changes..." -ForegroundColor Yellow
    terraform apply -auto-approve tfplan
    
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed"
    }
    
    Write-Host ""
    
    # Show outputs
    Write-Host "✅ Deployment complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📤 Outputs:" -ForegroundColor Cyan
    terraform output
    
} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}
```

**Forklaring:**

#### Try-Catch-Finally
```powershell
try {
    # Main logic
} catch {
    # Error handling
} finally {
    # Always runs (cleanup)
}
```

**Finally-blokken:**
- Kjøres ALLTID (selv ved error eller exit)
- Perfekt for cleanup (Pop-Location)
- Garanterer at vi går tilbake til original directory

**Eksempel på viktigheten:**
```powershell
Push-Location terraform
# Hvis feil her, er vi fortsatt i terraform/
# Uten finally, forblir vi i feil directory

# Med finally:
try {
    Push-Location terraform
    # Work here
} finally {
    Pop-Location  # Garantert kjørt
}
```

#### Relative Paths
```powershell
$backendConfig = Join-Path ".." "backend-configs" "backend-$Environment.tfvars"
```
- `..` - Parent directory (fungerer i PowerShell)
- Join-Path håndterer relative paths
- Resultat: `..\backend-configs\backend-dev.tfvars`

#### LASTEXITCODE Checking
```powershell
terraform init -backend-config=$backendConfig

if ($LASTEXITCODE -ne 0) {
    throw "Terraform init failed"
}
```
- Terraform returnerer ikke PowerShell errors
- Må sjekke `$LASTEXITCODE` manuelt
- `throw` kaster exception som fanges av catch

## Bruk av Scriptet

### Grunnleggende Kjøring

```powershell
# Named parameters (anbefalt)
.\scripts\deploy.ps1 -Environment dev -Artifact terraform-abc123.tar.gz

# Posisjonelle parametere
.\scripts\deploy.ps1 dev terraform-abc123.tar.gz

# Med verbose output
.\scripts\deploy.ps1 -Environment dev -Artifact terraform-abc123.tar.gz -Verbose
```

### Komplett Workflow

```powershell
# 1. Login til Azure
az login

# 2. Velg subscription
az account set --subscription "My Subscription"

# 3. Bygg artefakt
.\build.ps1

# 4. Deploy
$artifact = Get-ChildItem terraform-*.tar.gz | Select-Object -First 1
.\scripts\deploy.ps1 -Environment dev -Artifact $artifact.Name
```

### Avansert Bruk

```powershell
# Med splatting
$deployParams = @{
    Environment = "dev"
    Artifact = "terraform-abc123.tar.gz"
    Verbose = $true
}
.\scripts\deploy.ps1 @deployParams

# Automatisk med nyeste artifact
$latest = Get-ChildItem terraform-*.tar.gz | Sort-Object LastWriteTime -Descending | Select-Object -First 1
.\scripts\deploy.ps1 -Environment dev -Artifact $latest.Name

# Med transcript logging
Start-Transcript -Path "deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
.\scripts\deploy.ps1 -Environment dev -Artifact terraform-abc123.tar.gz
Stop-Transcript
```

### Forventet Output

```
🚀 Deploying to dev environment...

🔍 Getting Azure subscription ID...
✅ Using subscription: 12345678-1234-1234-1234-123456789abc

1️⃣ Extracting artifact...
✅ Artifact extracted

2️⃣ Initializing Terraform...

Initializing the backend...
Successfully configured the backend "azurerm"!

Terraform has been successfully initialized!

3️⃣ Planning deployment...

Terraform will perform the following actions:

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + id       = (known after apply)
      + location = "norwayeast"
      + name     = "myapp-dev-rg"
    }

Plan: 5 to add, 0 to change, 0 to destroy.

4️⃣ Applying changes...
azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

✅ Deployment complete!

📤 Outputs:
resource_group_name = "myapp-dev-rg"
app_service_url = "https://myapp-dev.azurewebsites.net"

───────────────────────────────────────
Deployment to dev complete!
───────────────────────────────────────
```

## Feilsøking

### Problem: Validation Error på Environment

```
Cannot validate argument on parameter 'Environment'. The argument "production" 
does not belong to the set "dev,test,prod" specified by the ValidateSet attribute.
```

**Årsak:** Ugyldig miljønavn oppgitt

**Løsning:**
```powershell
# Bruk kun: dev, test, eller prod
.\scripts\deploy.ps1 -Environment prod -Artifact build.tar.gz

# Se gyldige valg med tab completion
.\scripts\deploy.ps1 -Environment <TAB>
```

### Problem: Validation Error på Artifact

```
Cannot validate argument on parameter 'Artifact'. The 
Test-Path $_ -PathType Leaf test did not pass.
```

**Årsak:** Artefakt-filen finnes ikke

**Løsning:**
```powershell
# Sjekk at filen eksisterer
Get-ChildItem terraform-*.tar.gz

# Bruk full path hvis i annen mappe
.\scripts\deploy.ps1 -Environment dev -Artifact C:\Artifacts\terraform-abc.tar.gz

# Eller bygg ny artefakt
.\build.ps1
```

### Problem: "Could not get subscription ID"

**Løsning:**
```powershell
# Login til Azure
az login

# Verifiser login
az account show

# List alle subscriptions
az account list -o table

# Velg riktig subscription
az account set --subscription "Subscription Name"

# Prøv deploy igjen
.\scripts\deploy.ps1 -Environment dev -Artifact build.tar.gz
```

### Problem: "tar command not available"

**Årsak:** Prøver å bruke .tar.gz på system uten tar

**Løsning 1 - Installer tar:**
```powershell
# Via Chocolatey
choco install git

# Via Scoop
scoop install git

# Git for Windows inkluderer tar
```

**Løsning 2 - Bruk .zip:**
```powershell
# Bygg med .zip (hvis tar ikke tilgjengelig, gjør build.ps1 dette automatisk)
.\build.ps1

# Deploy .zip artifact
.\scripts\deploy.ps1 -Environment dev -Artifact terraform-abc123.zip
```

### Problem: "Backend config not found"

**Løsning:**
```powershell
# Sjekk struktur i artefakt
$artifact = "terraform-abc123.tar.gz"
tar -tzf $artifact  # List contents

# Verifiser backend-config eksisterer
Test-Path .\backend-configs\backend-dev.tfvars

# Sjekk at filen er inkludert i build
Get-Content .\build.ps1 | Select-String "backend-configs"
```

### Problem: "Error acquiring state lock"

**Løsning:**
```powershell
# Vent noen minutter, prøv igjen

# Sjekk hvem som har låsen
az storage blob list `
    --account-name tfstateaccount `
    --container-name tfstate `
    --query "[?contains(name, '.lock')]"

# Force unlock (hvis nødvendig)
cd workspace-dev\terraform
terraform force-unlock <LOCK_ID>
```

### Problem: PowerShell Execution Policy

**Løsning:**
```powershell
# Sjekk policy
Get-ExecutionPolicy

# Endre for current user
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Eller kjør med bypass
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Environment dev -Artifact build.tar.gz
```

## Avanserte Features

### 1. WhatIf Support

Legg til WhatIf-støtte i scriptet:

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    # ... existing parameters ...
)

# I terraform apply section:
if ($PSCmdlet.ShouldProcess("$Environment environment", "Deploy infrastructure")) {
    terraform apply -auto-approve tfplan
}

# Bruk:
.\scripts\deploy.ps1 -Environment dev -Artifact build.tar.gz -WhatIf
```

### 2. Confirm Support

```powershell
# I apply section:
if ($PSCmdlet.ShouldProcess("$Environment environment", "Deploy infrastructure")) {
    if ($PSCmdlet.ShouldContinue("Apply changes to $Environment?", "Confirm Deployment")) {
        terraform apply -auto-approve tfplan
    }
}

# Bruk:
.\scripts\deploy.ps1 -Environment prod -Artifact build.tar.gz -Confirm
```

### 3. Progress Bars

```powershell
# Før hver fase
Write-Progress -Activity "Deployment" -Status "Extracting..." -PercentComplete 20
# Extract code...

Write-Progress -Activity "Deployment" -Status "Initializing..." -PercentComplete 40
# Init code...

Write-Progress -Activity "Deployment" -Status "Planning..." -PercentComplete 60
# Plan code...

Write-Progress -Activity "Deployment" -Status "Applying..." -PercentComplete 80
# Apply code...

Write-Progress -Activity "Deployment" -Completed
```

### 4. Return Object

```powershell
# På slutten av scriptet, returner deployment info
$deploymentInfo = [PSCustomObject]@{
    Environment = $Environment
    Artifact = $Artifact
    SubscriptionId = $subscriptionId
    Timestamp = Get-Date
    Success = $true
}

return $deploymentInfo

# Bruk i annet script:
$result = .\scripts\deploy.ps1 -Environment dev -Artifact build.tar.gz
Write-Host "Deployed at: $($result.Timestamp)"
```

### 5. Logging til Fil

```powershell
# Legg til i starten av scriptet
param(
    # ... existing parameters ...
    [string]$LogPath = "deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

# Start transcript
Start-Transcript -Path $LogPath

# ... rest of script ...

# På slutten
Stop-Transcript
```

### 6. Rollback on Failure

```powershell
try {
    # ... terraform apply ...
    
} catch {
    Write-Host "❌ Deployment failed, attempting rollback..." -ForegroundColor Red
    
    # Get previous state
    terraform state pull > previous-state.json
    
    # Attempt destroy of failed resources
    terraform destroy -auto-approve -target=<failed_resource>
    
    throw
}
```

## CI/CD Integration

### Azure DevOps

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'windows-latest'

variables:
  - group: azure-credentials

steps:
- task: AzureCLI@2
  displayName: 'Azure Login'
  inputs:
    azureSubscription: '$(azureServiceConnection)'
    scriptType: 'ps'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az account show

- task: PowerShell@2
  displayName: 'Build Artifact'
  inputs:
    filePath: 'build.ps1'
    
- task: PowerShell@2
  displayName: 'Deploy to Dev'
  inputs:
    filePath: 'scripts/deploy.ps1'
    arguments: '-Environment dev -Artifact $(Build.SourcesDirectory)\terraform-*.tar.gz'
```

### GitHub Actions

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        type: choice
        options:
          - dev
          - test
          - prod

jobs:
  deploy:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Build Artifact
      shell: pwsh
      run: .\build.ps1
    
    - name: Deploy
      shell: pwsh
      run: |
        $artifact = Get-ChildItem terraform-*.tar.gz | Select-Object -First 1
        .\scripts\deploy.ps1 -Environment ${{ github.event.inputs.environment || 'dev' }} -Artifact $artifact.Name
```

## Best Practices

### 1. Named Parameters

```powershell
# ✅ Bra - tydelig og selvdokumenterende
.\scripts\deploy.ps1 -Environment dev -Artifact terraform-abc.tar.gz

# ⚠️ Greit - men mindre tydelig
.\scripts\deploy.ps1 dev terraform-abc.tar.gz

# ❌ Dårlig - lett å blande rekkefølge
.\scripts\deploy.ps1 terraform-abc.tar.gz dev  # Feiler!
```

### 2. Error Handling

```powershell
# ✅ Bra - comprehensive error handling
try {
    terraform apply -auto-approve tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "Deployment error: $($_.Exception.Message)"
    # Cleanup code
    throw
} finally {
    Pop-Location
}
```

### 3. Input Validation

```powershell
# ✅ Bra - validation i parameter
[ValidateSet("dev", "test", "prod")]
[string]$Environment

# ❌ Unødvendig - allerede validert
if ($Environment -notin @("dev", "test", "prod")) {
    throw "Invalid environment"
}
```

### 4. Path Handling

```powershell
# ✅ Bra - cross-platform
$path = Join-Path $workspace "terraform"

# ❌ Dårlig - Windows-spesifikt
$path = "$workspace\terraform"
```

## Sammenligning: Bash vs PowerShell Deploy

| Feature | Bash | PowerShell |
|---------|------|------------|
| **Parameter validation** | Manual if-checks | Built-in attributes |
| **Tab completion** | None | Automatic for ValidateSet |
| **Error messages** | Generic | Detailed and colored |
| **Path joining** | String concat | Join-Path cmdlet |
| **Archive support** | tar only | tar + Compress-Archive |
| **Progress indication** | echo only | Write-Progress available |
| **Object return** | Not typical | Easy with PSCustomObject |
| **WhatIf/Confirm** | Manual | Built-in support |

## Oppsummering

Dette PowerShell deploy-scriptet tilbyr:

### ✅ Enterprise Features
- **Parameter validation** - Feil oppdages før kjøring
- **CmdletBinding** - Verbose, Debug, WhatIf support
- **Robust error handling** - Try-Catch-Finally
- **Cross-format support** - Både .tar.gz og .zip
- **Intelligent path handling** - Join-Path for portabilitet
- **Farget output** - Bedre brukeropplevelse

### 🎯 Best Practices
- Named parameters med validation
- Finally-blokk for cleanup
- Explicit LASTEXITCODE sjekk
- Test-Path før operasjoner
- Cross-platform path joining

### 🚀 Windows-optimalisert
- Native .zip support (Expand-Archive)
- Fallback for systemer uten tar
- PowerShell-native cmdlets
- .NET class integration
- Execution policy awareness

Med dette scriptet har Windows-utviklere et profesjonelt deployment-verktøy med alle fordelene fra moderne PowerShell! 🎉
# Terraform Cleanup Script - PowerShell Veiledning

## Oversikt

Dette PowerShell-scriptet (`cleanup.ps1`) er et kraftig og farlig verktøy for å rydde opp i Terraform-deployments og lokale filer. Scriptet bruker **PowerShell-funksjoner** (ikke bare inline kode) og tilbyr en interaktiv meny med 8 valg for omfattende cleanup-operasjoner.

⚠️ **KRITISK ADVARSEL:** Dette scriptet sletter infrastruktur og data permanent. Bruk med ekstrem forsiktighet!

## Nøkkelforskjeller fra Bash-versjonen

| Aspekt | Bash | PowerShell |
|--------|------|------------|
| **Funksjoner** | `function name() { }` | `function Verb-Noun { param() }` |
| **Parameters** | `$1`, `$2` | Named parameters med validation |
| **Read input** | `read -p` | `Read-Host` |
| **Switch** | `case ... esac` | `switch { }` |
| **Piping** | `for rg in $(...)` | `ForEach-Object` pipeline |
| **JSON parsing** | `jq` eller manual | `ConvertFrom-Json` built-in |
| **Filtering** | `grep`, `awk` | `Where-Object` |
| **Return** | `return` (exit function) | `return` (med verdi) |

## Forutsetninger

### Nødvendig Programvare
- **PowerShell 5.1+** eller **PowerShell Core 7+**
- **Terraform CLI**
- **Azure CLI** (`az`)
- **tar** (kun for .tar.gz artifacts)

### Tilganger og Rettigheter
- Azure login (`az login`)
- **Contributor** eller **Owner** rolle
- Rettigheter til å slette ressurser
- Tilgang til Terraform state storage

⚠️ **OBS:** Dette scriptet har makt til å slette all infrastruktur!

## Detaljert Gjennomgang

### 1. PowerShell Funksjoner

#### 1.1 Remove-TerraformEnvironment

```powershell
function Remove-TerraformEnvironment {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("dev", "test", "prod")]
        [string]$Environment
    )
    
    # Function body...
}
```

**Forklaring:**

**PowerShell Function Naming:**
- Følger `Verb-Noun` konvensjon
- `Remove-` - Standard verb for sletting
- Godkjente verbs: `Get-`, `Set-`, `New-`, `Remove-`, `Start-`, `Stop-`, etc.

**Sjekk gyldige verbs:**
```powershell
Get-Verb | Where-Object Verb -like "Remove"
```

**Parameter i Function:**
- `param()` blokk definerer parametere
- Same validation attributes som i script-parametere
- `[ValidateSet]` sikrer kun gyldige miljøer

**Kalle funksjonen:**
```powershell
# Med named parameter
Remove-TerraformEnvironment -Environment "dev"

# Posisjonelt (hvis Position definert)
Remove-TerraformEnvironment "dev"
```

#### 1.2 Clear-LocalFiles Function

```powershell
function Clear-LocalFiles {
    Write-Host "🧹 Cleaning local files..." -ForegroundColor Yellow
    Write-Host ""
    
    $cleaned = $false
    
    # Remove workspaces
    $workspaces = Get-ChildItem -Directory -Filter "workspace-*" -ErrorAction SilentlyContinue
    if ($workspaces) {
        Write-Host "  Removing workspaces..." -ForegroundColor Gray
        $workspaces | ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force
        }
        Write-Host "  ✅ Workspaces removed" -ForegroundColor Green
        $cleaned = $true
    }
    
    # Remove artifacts (both .tar.gz and .zip)
    $artifacts = Get-ChildItem -File -Filter "terraform-*.*" -ErrorAction SilentlyContinue | 
                 Where-Object { $_.Extension -in @(".gz", ".zip") -or $_.Name -like "*.tar.gz" }
    
    if ($artifacts) {
        Write-Host "  Removing artifacts..." -ForegroundColor Gray
        $artifacts | ForEach-Object {
            Remove-Item -Path $_.FullName -Force
        }
        Write-Host "  ✅ Artifacts removed" -ForegroundColor Green
        $cleaned = $true
    }
    
    if (-not $cleaned) {
        Write-Host "  No local files to clean" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "✅ Local cleanup complete" -ForegroundColor Green
    Write-Host ""
}
```

**Forklaring:**

**Get-ChildItem (ls/dir):**
```powershell
Get-ChildItem -Directory -Filter "workspace-*" -ErrorAction SilentlyContinue
```
- `-Directory` - Kun mapper (ikke filer)
- `-Filter` - Wildcard filter (raskere enn Where-Object)
- `-ErrorAction SilentlyContinue` - Skjul feil hvis ingen treff

**Alternativer:**
```powershell
# Kun filer
Get-ChildItem -File

# Recursive
Get-ChildItem -Recurse

# Med Where-Object filter
Get-ChildItem | Where-Object Name -like "*.txt"

# Flere filters
Get-ChildItem -File -Include "*.ps1","*.txt" -Exclude "test*"
```

**Pipeline med ForEach-Object:**
```powershell
$workspaces | ForEach-Object {
    Remove-Item -Path $_.FullName -Recurse -Force
}
```
- `$_` - Nåværende pipeline-objekt
- `.FullName` - Full sti til fil/mappe
- ForEach-Object kjører blokk for hvert objekt

**Alternativer:**
```powershell
# ForEach-Object (alias: foreach, %)
$items | ForEach-Object { Process-Item $_ }
$items | foreach { Process-Item $_ }
$items | % { Process-Item $_ }

# Foreach statement (ikke pipeline)
foreach ($item in $items) {
    Process-Item $item
}
```

**-in Operator:**
```powershell
$_.Extension -in @(".gz", ".zip")
```
- Sjekker om verdi finnes i array
- Returnerer `$true` eller `$false`
- Motsatt: `-notin`

**Eksempler:**
```powershell
"apple" -in @("apple", "banana")     # True
"grape" -in @("apple", "banana")     # False
5 -in @(1, 2, 3, 4, 5)              # True
"dev" -notin @("test", "prod")      # True
```

**Compound Where-Object:**
```powershell
Where-Object { $_.Extension -in @(".gz", ".zip") -or $_.Name -like "*.tar.gz" }
```
- Multiple conditions med `-or`
- Kan kombinere med `-and`
- Parenteser for gruppering hvis nødvendig

#### 1.3 Remove-AzureResourcesForce Function

```powershell
function Remove-AzureResourcesForce {
    Write-Host "💥 Force cleanup via Azure CLI" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  WARNING: This will delete resource groups directly!" -ForegroundColor Yellow
    Write-Host "   Use this only if terraform destroy fails." -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "Continue? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Host "Cancelled" -ForegroundColor Gray
        return
    }
    
    try {
        Write-Host ""
        Write-Host "Available resource groups:" -ForegroundColor Cyan
        
        $resourceGroups = az group list --query "[?starts_with(name, 'rg-demo-')]" | ConvertFrom-Json
        
        if ($resourceGroups.Count -eq 0) {
            Write-Host "No resource groups found with prefix 'rg-demo-'" -ForegroundColor Gray
            return
        }
        
        $resourceGroups | Format-Table -Property name, location -AutoSize
        
        Write-Host ""
        $rgName = Read-Host "Enter resource group name to delete (or 'all' for all demo groups)"
        
        if ($rgName -eq "all") {
            Write-Host ""
            Write-Host "🔥 Deleting all demo resource groups..." -ForegroundColor Red
            
            foreach ($rg in $resourceGroups) {
                Write-Host "  Deleting: $($rg.name)" -ForegroundColor Gray
                az group delete --name $rg.name --yes --no-wait | Out-Null
            }
            
            Write-Host ""
            Write-Host "✅ Deletion initiated (running in background)" -ForegroundColor Green
            Write-Host "   Check status: az group list -o table" -ForegroundColor Gray
            
        } elseif (-not [string]::IsNullOrWhiteSpace($rgName)) {
            Write-Host ""
            Write-Host "🔥 Deleting: $rgName" -ForegroundColor Red
            az group delete --name $rgName --yes --no-wait | Out-Null
            Write-Host ""
            Write-Host "✅ Deletion initiated" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}
```

**Forklaring:**

**ConvertFrom-Json:**
```powershell
$resourceGroups = az group list --query "[?starts_with(name, 'rg-demo-')]" | ConvertFrom-Json
```
- Konverterer JSON string til PowerShell objekter
- Gjør det enkelt å jobbe med Azure CLI output
- Motsatt: `ConvertTo-Json`

**Fordeler:**
```powershell
# Uten ConvertFrom-Json (vanskeligere)
$jsonString = az group list --query "..."
# Må parse string manuelt

# Med ConvertFrom-Json (enkelt)
$objects = az group list --query "..." | ConvertFrom-Json
$objects[0].name        # Direkte property-tilgang
$objects.Count          # Array-metoder tilgjengelig
```

**Array Count Property:**
```powershell
if ($resourceGroups.Count -eq 0)
```
- `.Count` - Antall elementer i array
- `.Length` - Samme som Count (alias)
- Fungerer på arrays og collections

**Eksempler:**
```powershell
$array = @(1, 2, 3, 4, 5)
$array.Count              # 5
$array.Length             # 5

$null.Count               # 0 (ikke feil)
@().Count                 # 0 (tom array)
```

**Format-Table:**
```powershell
$resourceGroups | Format-Table -Property name, location -AutoSize
```
- Formaterer output som tabell
- `-Property` - Hvilke properties som vises
- `-AutoSize` - Tilpasser kolonnebredde automatisk

**Format cmdlets:**
```powershell
# Format-Table (tabell)
Get-Process | Format-Table Name, CPU -AutoSize

# Format-List (vertikal liste)
Get-Process | Format-List *

# Format-Wide (kompakt)
Get-Process | Format-Wide Name

# Format-Custom (avansert)
Get-Process | Format-Custom
```

**IsNullOrWhiteSpace:**
```powershell
[string]::IsNullOrWhiteSpace($rgName)
```
- Sjekker null, empty, eller kun whitespace
- Strengere enn `IsNullOrEmpty`
- God for user input validering

**Sammenligning:**
```powershell
$str = "   "

[string]::IsNullOrEmpty($str)       # False (inneholder spaces)
[string]::IsNullOrWhiteSpace($str)  # True (kun whitespace)
```

**Foreach Statement:**
```powershell
foreach ($rg in $resourceGroups) {
    Write-Host "  Deleting: $($rg.name)" -ForegroundColor Gray
    az group delete --name $rg.name --yes --no-wait | Out-Null
}
```
- Standard foreach loop (ikke pipeline)
- Enklere syntaks for sequentielle operasjoner
- Kan bruke `break` og `continue`

**Vs ForEach-Object:**
```powershell
# Foreach statement
foreach ($item in $items) {
    Process $item
}

# ForEach-Object pipeline
$items | ForEach-Object {
    Process $_
}
```

### 2. Switch Statement

```powershell
$choice = Read-Host "Enter choice [0-7]"

switch ($choice) {
    "1" {
        Remove-TerraformEnvironment -Environment "dev"
    }
    "2" {
        Remove-TerraformEnvironment -Environment "test"
    }
    "3" {
        Remove-TerraformEnvironment -Environment "prod"
    }
    "4" {
        Remove-TerraformEnvironment -Environment "dev"
        Remove-TerraformEnvironment -Environment "test"
        Remove-TerraformEnvironment -Environment "prod"
    }
    "5" {
        Clear-LocalFiles
    }
    "6" {
        Remove-AzureResourcesForce
    }
    "7" {
        Write-Host "🔥 FULL CLEANUP - Everything will be removed!" -ForegroundColor Red
        Write-Host ""
        $confirm = Read-Host "Are you sure? (yes/no)"
        
        if ($confirm -eq "yes") {
            Remove-TerraformEnvironment -Environment "dev"
            Remove-TerraformEnvironment -Environment "test"
            Remove-TerraformEnvironment -Environment "prod"
            Clear-LocalFiles
            
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
```

**Forklaring:**

**Switch vs If-ElseIf:**
```powershell
# Switch (penere for mange conditions)
switch ($value) {
    "a" { "Option A" }
    "b" { "Option B" }
    default { "Unknown" }
}

# If-ElseIf (samme funksjonalitet)
if ($value -eq "a") {
    "Option A"
} elseif ($value -eq "b") {
    "Option B"
} else {
    "Unknown"
}
```

**Switch Features:**
```powershell
# Pattern matching
switch -Wildcard ($filename) {
    "*.txt" { "Text file" }
    "*.ps1" { "PowerShell script" }
}

# Regex matching
switch -Regex ($text) {
    "^\d+$" { "Number" }
    "^[A-Za-z]+$" { "Letters only" }
}

# Multiple matches (no break)
switch ($number) {
    {$_ -gt 0} { "Positive" }
    {$_ -lt 10} { "Less than 10" }
    {$_ -eq 5} { "Exactly 5" }
}

# Case-sensitive
switch -CaseSensitive ($text) {
    "hello" { "lowercase" }
    "HELLO" { "uppercase" }
}
```

**Default Case:**
```powershell
default {
    Write-Host "Invalid choice" -ForegroundColor Red
    exit 1
}
```
- Kjører hvis ingen andre cases matcher
- Tilsvarende `*` i Bash case
- Valgfritt (men anbefalt for validation)

### 3. Read-Host

```powershell
$confirm = Read-Host "❓ Destroy $Environment environment? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "⏭️  Skipped $Environment" -ForegroundColor Gray
    return
}
```

**Forklaring:**

**Read-Host:**
- Leser input fra brukeren
- Returnerer string
- Blokkerer til bruker trykker Enter

**Advanced usage:**
```powershell
# Secure input (for passwords)
$password = Read-Host "Enter password" -AsSecureString

# Masked input
$secret = Read-Host "Enter secret" -MaskInput

# Convert SecureString to plain text (hvis nødvendig)
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
)
```

**Input Validation:**
```powershell
do {
    $choice = Read-Host "Enter choice [0-7]"
} while ($choice -notmatch "^[0-7]$")

# Eller med regex
while ($input -notmatch "^\d+$") {
    $input = Read-Host "Enter a number"
}
```

## Bruk av Scriptet

### Grunnleggende Kjøring

```powershell
# Kjør cleanup script
.\cleanup.ps1

# Velg alternativ fra meny
Enter choice [0-7]: 1
```

### Eksempel: Slette Dev-miljø

```powershell
PS> .\cleanup.ps1

🧹 Cleanup Script for Terraform Demo

Select cleanup option:

  1) Destroy DEV environment
  2) Destroy TEST environment
  3) Destroy PROD environment
  4) Destroy ALL environments
  5) Clean local files only (workspaces, artifacts)
  6) Force cleanup via Azure CLI (if terraform fails)
  7) Full cleanup (everything)
  0) Cancel

Enter choice [0-7]: 1

───────────────────────────────────────
Cleaning up: dev environment
───────────────────────────────────────

📋 Planning destruction...

Terraform will perform the following actions:

  # azurerm_resource_group.main will be destroyed
  - resource "azurerm_resource_group" "main" {
      ...
    }

Plan: 0 to add, 0 to change, 5 to destroy.

❓ Destroy dev environment? (yes/no): yes

💥 Destroying infrastructure...
azurerm_resource_group.main: Destroying...
azurerm_resource_group.main: Destruction complete after 45s

✅ dev environment destroyed

───────────────────────────────────────
Cleanup script finished
───────────────────────────────────────
```

### Eksempel: Kun Lokale Filer

```powershell
PS> .\cleanup.ps1

Enter choice [0-7]: 5

🧹 Cleaning local files...

  Removing workspaces...
  ✅ Workspaces removed
  Removing artifacts...
  ✅ Artifacts removed

✅ Local cleanup complete
```

### Eksempel: Force Azure Cleanup

```powershell
PS> .\cleanup.ps1

Enter choice [0-7]: 6

💥 Force cleanup via Azure CLI

⚠️  WARNING: This will delete resource groups directly!
   Use this only if terraform destroy fails.

Continue? (yes/no): yes

Available resource groups:

name            location
----            --------
rg-demo-dev    norwayeast
rg-demo-test   norwayeast

Enter resource group name to delete (or 'all' for all demo groups): rg-demo-dev

🔥 Deleting: rg-demo-dev

✅ Deletion initiated
```

## Feilsøking

### Problem: "Workspace not found"

**Løsning:**
```powershell
# Bruk force cleanup (valg 6)
.\cleanup.ps1
# Velg: 6

# Eller manuell Azure CLI cleanup
az group delete --name rg-demo-dev --yes
```

### Problem: "Not logged in to Azure"

**Løsning:**
```powershell
# Login
az login

# Verifiser
az account show

# Prøv cleanup igjen
.\cleanup.ps1
```

### Problem: Function not recognized

**Årsak:** Scriptet kjørt feil eller function ikke definert

**Løsning:**
```powershell
# Dot-source scriptet (load functions)
. .\cleanup.ps1

# Eller kjør funksjonen direkte
Remove-TerraformEnvironment -Environment dev
```

### Problem: ConvertFrom-Json feiler

**Årsak:** Azure CLI returnerer ikke JSON

**Løsning:**
```powershell
# Sjekk Azure CLI output manuelt
az group list --query "[?starts_with(name, 'rg-demo-')]"

# Verifiser at output er valid JSON
az group list --query "[?starts_with(name, 'rg-demo-')]" | ConvertFrom-Json

# Hvis fortsatt feiler, oppdater Azure CLI
az upgrade
```

### Problem: "State lock" error

**Løsning:**
```powershell
# Vent og prøv igjen

# Eller force unlock
cd workspace-dev\terraform
terraform force-unlock <LOCK_ID>

# Eller bruk force cleanup (valg 6)
```

## Avanserte Features

### 1. Parameter til Script

Utvid scriptet med parametere:

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "test", "prod", "all")]
    [string]$Environment,
    
    [switch]$Force,
    [switch]$LocalOnly
)

# Non-interactive mode hvis parameter oppgitt
if ($Environment) {
    if ($Environment -eq "all") {
        Remove-TerraformEnvironment -Environment "dev"
        Remove-TerraformEnvironment -Environment "test"
        Remove-TerraformEnvironment -Environment "prod"
    } else {
        Remove-TerraformEnvironment -Environment $Environment
    }
    exit 0
}

# Ellers vis meny (existing code)
```

**Bruk:**
```powershell
# Non-interactive cleanup
.\cleanup.ps1 -Environment dev

# All environments
.\cleanup.ps1 -Environment all

# Only local files
.\cleanup.ps1 -LocalOnly

# Force mode (no confirmation)
.\cleanup.ps1 -Environment dev -Force
```

### 2. Logging

```powershell
# Legg til i starten
$logFile = "cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Start-Transcript -Path $logFile

# På slutten
Stop-Transcript

Write-Host "Log saved to: $logFile" -ForegroundColor Cyan
```

### 3. Dry-Run Mode

```powershell
param(
    [switch]$WhatIf
)

# I Remove-TerraformEnvironment
if ($WhatIf) {
    Write-Host "WHAT IF: Would destroy $Environment environment" -ForegroundColor Yellow
    terraform plan -destroy -var-file=$envVarsFile
    return
}

# Bruk:
.\cleanup.ps1 -WhatIf
```

### 4. Return Status Object

```powershell
function Remove-TerraformEnvironment {
    # ... existing code ...
    
    # Return object
    return [PSCustomObject]@{
        Environment = $Environment
        Success = $true
        Timestamp = Get-Date
        Message = "Environment destroyed successfully"
    }
}

# Bruk
$result = Remove-TerraformEnvironment -Environment dev
if ($result.Success) {
    Write-Host "Success: $($result.Message)"
}
```

### 5. Parallel Cleanup

```powershell
# Cleanup flere miljøer parallelt
$jobs = @()
$jobs += Start-Job -ScriptBlock { 
    param($env)
    # Load script
    . .\cleanup.ps1
    Remove-TerraformEnvironment -Environment $env
} -ArgumentList "dev"

$jobs += Start-Job -ScriptBlock { 
    param($env)
    . .\cleanup.ps1
    Remove-TerraformEnvironment -Environment $env
} -ArgumentList "test"

# Vent på alle jobs
$jobs | Wait-Job | Receive-Job

# Cleanup jobs
$jobs | Remove-Job
```

### 6. Email Notifikasjon

```powershell
function Send-CleanupNotification {
    param(
        [string]$Environment,
        [bool]$Success
    )
    
    $params = @{
        From = "terraform@company.com"
        To = "admin@company.com"
        Subject = "Terraform Cleanup: $Environment"
        Body = if ($Success) { "✅ Successfully cleaned $Environment" } else { "❌ Failed to clean $Environment" }
        SmtpServer = "smtp.company.com"
    }
    
    Send-MailMessage @params
}

# Bruk i cleanup function
try {
    # Cleanup code...
    Send-CleanupNotification -Environment $Environment -Success $true
} catch {
    Send-CleanupNotification -Environment $Environment -Success $false
    throw
}
```

## PowerShell Best Practices for Cleanup Scripts

### 1. Approved Verbs

```powershell
# ✅ Bra - bruker approved verbs
function Remove-TerraformEnvironment { }
function Clear-LocalFiles { }

# ❌ Dårlig - ikke approved verbs
function Delete-TerraformEnvironment { }  # Bruk Remove-
function Clean-LocalFiles { }              # Bruk Clear-

# Sjekk approved verbs
Get-Verb | Where-Object Verb -like "*move*"
```

### 2. Error Handling

```powershell
# ✅ Bra - comprehensive error handling
try {
    # Risky operation
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    # Log error
    # Send notification
    throw
} finally {
    # Cleanup (always runs)
    Pop-Location
}

# ❌ Dårlig - no error handling
# Risky operation without try-catch
```

### 3. Confirmation Prompts

```powershell
# ✅ Bra - explicit "yes" required
$confirm = Read-Host "Are you sure? (yes/no)"
if ($confirm -ne "yes") { return }

# ⚠️ Greit - case-insensitive
$confirm = Read-Host "Continue? (y/n)"
if ($confirm -like "y*") { }

# ❌ Farlig - any key continues
Read-Host "Press any key to delete..."
```

### 4. Verbose Output

```powershell
# ✅ Bra - støtter -Verbose
[CmdletBinding()]
param()

Write-Verbose "Starting cleanup process..."
Write-Verbose "Removing resource: $resourceName"

# Bruk:
.\cleanup.ps1 -Verbose
```

### 5. Object Returns

```powershell
# ✅ Bra - return object
function Remove-Environment {
    # ... cleanup code ...
    
    return [PSCustomObject]@{
        Success = $true
        Environment = $Environment
        ResourcesDeleted = $count
    }
}

# ❌ Dårlig - ingen return value
function Remove-Environment {
    # ... cleanup code ...
    Write-Host "Done"
}
```

## Sammenligning: Bash vs PowerShell Cleanup

| Feature | Bash | PowerShell |
|---------|------|------------|
| **Functions** | Simple shell functions | Advanced functions with params |
| **JSON parsing** | Requires `jq` | Built-in `ConvertFrom-Json` |
| **Array filtering** | `grep`, `awk` | `Where-Object` pipeline |
| **User input** | `read -p` | `Read-Host` with validation |
| **Switch** | `case` with patterns | `switch` with regex support |
| **Error handling** | Manual checking | Try-catch-finally |
| **Return values** | Exit codes only | Objects with properties |
| **Verbose mode** | Manual if-checks | Built-in `-Verbose` support |

## Sikkerhet og Advarsler

### 🔴 KRITISKE ADVARSLER

#### 1. Full Cleanup (Valg 7)

```powershell
# ALDRI bruk valg 7 i produksjon uten backup
# Sletter ALL infrastruktur og lokale filer
# Ingen mulighet for undo!
```

#### 2. Force Cleanup (Valg 6)

```powershell
# Bypasser Terraform fullstendig
# Kan føre til orphaned resources
# Bruk kun som siste utvei
```

#### 3. Teamkoordinering

```powershell
# Sjekk alltid at ingen andre jobber
# Før cleanup, inform team:
Send-TeamsMessage -Message "Starting cleanup of dev environment"
```

### ✅ Sikkerhetstips

#### 1. Backup State

```powershell
# Før cleanup
cd workspace-dev\terraform
terraform state pull > "backup-state-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
```

#### 2. Dry-Run First

```powershell
# Test med plan først
terraform plan -destroy -var-file=...

# Verifiser output før actual destroy
```

#### 3. Protected Environments

```powershell
# Legg til i Remove-TerraformEnvironment
if ($Environment -eq "prod") {
    Write-Host "🔒 PRODUCTION - Extra confirmation required" -ForegroundColor Red
    $confirmProd = Read-Host "Type 'DELETE PRODUCTION' to confirm"
    if ($confirmProd -ne "DELETE PRODUCTION") {
        Write-Host "❌ Confirmation failed" -ForegroundColor Red
        return
    }
}
```

## Oppsummering

Dette PowerShell cleanup-scriptet tilbyr:

### ✅ PowerShell-fordeler
- **Functions med parameters** - Gjenbrukbar kode
- **Built-in JSON parsing** - ConvertFrom-Json
- **Pipeline-basert filtrering** - Where-Object, ForEach-Object
- **Robust error handling** - Try-catch-finally
- **Rich objekter** - Ikke bare strings
- **Format-cmdlets** - Format-Table for pen output

### 🎯 Best Practices
- Approved verb naming (Remove-, Clear-)
- Parameter validation i functions
- Explicit "yes" confirmations
- Comprehensive error handling
- Colored output for clarity
- Return objects fra functions

### ⚠️ Sikkerhet
- Multiple confirmation prompts
- Terraform destroy plan preview
- Error handling ved hver operasjon
- Azure login validation
- Workspace checks før cleanup

### 🔥 Når Bruke Hva

| Valg | Scenario | Risiko |
|------|----------|--------|
| 1-3 | Normal environment cleanup | ✅ Trygt |
| 4 | Multiple environments | ⚠️ Forsiktig |
| 5 | Local files only | ✅ Trygt |
| 6 | Terraform feiler | 🔴 Farlig |
| 7 | Complete reset | 🔴 Svært farlig |

Med dette PowerShell-scriptet har Windows-utviklere et kraftig cleanup-verktøy med samme funksjonalitet som Bash-versjonen, men med alle fordelene fra moderne PowerShell! 🧹⚡
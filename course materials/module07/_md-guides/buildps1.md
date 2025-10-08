# Terraform Build Script - PowerShell Veiledning

## Oversikt

Dette PowerShell-scriptet (`build.ps1`) er en Windows-native versjon av Terraform build-scriptet. Det automatiserer prosessen med å validere, formatere og pakke Terraform-konfigurasjon til en deploybar artefakt, med full støtte for både moderne Windows-funksjoner (tar) og eldre systemer (Compress-Archive).

## Forskjeller fra Bash-versjonen

| Aspekt | Bash | PowerShell |
|--------|------|------------|
| **Filformat** | `.tar.gz` (gzip) | `.tar.gz` eller `.zip` |
| **Feilhåndtering** | `set -e` | `$ErrorActionPreference = "Stop"` |
| **Output** | `echo` | `Write-Host` med farger |
| **Pipe handling** | `>/dev/null 2>&1` | `Out-Null` og `2>$null` |
| **Navigasjon** | `cd` / `cd ..` | `Push-Location` / `Pop-Location` |
| **Tilgjengelighet** | Linux/Mac/Git Bash | Windows (inkl. PowerShell Core) |

## Forutsetninger

### Nødvendig Programvare

#### Obligatorisk:
- **PowerShell 5.1+** (inkludert i Windows 10/11)
  - Eller **PowerShell Core 7+** (cross-platform)
- **Terraform CLI** (versjon 1.0+)
- **Git** (valgfritt, men anbefalt)

#### Valgfritt:
- **tar** (inkludert i Windows 10 1803+ og Windows 11)
  - Hvis ikke tilgjengelig, bruker scriptet `.zip` i stedet

### Verifiser Forutsetninger

```powershell
# Sjekk PowerShell versjon
$PSVersionTable.PSVersion

# Sjekk Terraform
terraform version

# Sjekk Git
git --version

# Sjekk tar (valgfritt)
tar --version
```

### Execution Policy

PowerShell krever riktig execution policy for å kjøre scripts:

```powershell
# Sjekk nåværende policy
Get-ExecutionPolicy

# Sett policy for nåværende bruker (anbefalt)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Eller kjør script med bypass (engangskjøring)
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

**Execution Policies:**
- `Restricted` - Ingen scripts tillatt (Windows default)
- `RemoteSigned` - Lokale scripts OK, nedlastede må være signert
- `Unrestricted` - All scripts tillatt (ikke anbefalt)
- `Bypass` - Ingenting blokkeres (for testing)

## Detaljert Gjennomgang

### 1. Feilhåndtering

```powershell
$ErrorActionPreference = "Stop"
```

**Forklaring:**
- PowerShells versjon av Bash `set -e`
- Stopper scriptet ved første feil
- Standard er "Continue" (fortsetter ved feil)

**Andre alternativer:**
```powershell
$ErrorActionPreference = "Stop"        # Stopp ved feil
$ErrorActionPreference = "Continue"    # Fortsett ved feil (default)
$ErrorActionPreference = "SilentlyContinue"  # Fortsett uten melding
$ErrorActionPreference = "Inquire"     # Spør bruker ved feil
```

### 2. Farget Output

```powershell
Write-Host "📦 Building Terraform Artifact..." -ForegroundColor Cyan
Write-Host ""
```

**Forklaring:**
- `Write-Host` - Skriver direkte til konsoll (ikke pipeline)
- `-ForegroundColor` - Setter tekstfarge
- Gir mer lesbart output enn plain `Write-Output`

**Tilgjengelige farger:**
- `Black`, `DarkBlue`, `DarkGreen`, `DarkCyan`
- `DarkRed`, `DarkMagenta`, `DarkYellow`, `Gray`
- `DarkGray`, `Blue`, `Green`, `Cyan`
- `Red`, `Magenta`, `Yellow`, `White`

**Best practice:**
```powershell
Write-Host "✅ Success" -ForegroundColor Green
Write-Host "⚠️ Warning" -ForegroundColor Yellow
Write-Host "❌ Error" -ForegroundColor Red
Write-Host "ℹ️ Info" -ForegroundColor Cyan
Write-Host "  Details" -ForegroundColor Gray
```

### 3. Versjonsgenerering

```powershell
try {
    $gitDir = git rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -eq 0) {
        $version = git rev-parse --short HEAD
    } else {
        throw "Not a git repository"
    }
} catch {
    $version = Get-Date -Format "yyyyMMdd-HHmmss"
}
```

**Forklaring:**

#### Try-Catch Blokk
- PowerShells exception handling
- `try` - Prøv å kjøre kode
- `catch` - Håndter feil hvis de oppstår
- `throw` - Kast en exception manuelt

#### Git-sjekk
- `2>$null` - Omdirigerer stderr til null (skjuler feilmeldinger)
- `$LASTEXITCODE` - Exit code fra forrige kommando (0 = suksess)
- Tilsvarende `$?` i Bash

#### Fallback til Timestamp
```powershell
Get-Date -Format "yyyyMMdd-HHmmss"
```
- `Get-Date` - Henter nåværende dato/tid
- `-Format` - Spesifiserer format
- Resultat: `20250107-143022`

**Format-eksempler:**
```powershell
Get-Date -Format "yyyy-MM-dd"           # 2025-01-07
Get-Date -Format "yyyy-MM-dd-HH-mm-ss"  # 2025-01-07-14-30-22
Get-Date -Format "yyyyMMddHHmmss"       # 20250107143022
Get-Date -Format "FileDateTime"         # 20250107T1430226789
```

### 4. Push/Pop Location

```powershell
Push-Location terraform
# ... do work ...
Pop-Location
```

**Forklaring:**
- `Push-Location` - Bytter til ny lokasjon og lagrer gammel på stack
- `Pop-Location` - Går tilbake til forrige lokasjon
- Tryggere enn `Set-Location` (cd) for scripts

**Hvorfor bedre enn cd:**
```powershell
# Problem med cd (ved feil)
Set-Location terraform
# Hvis feil her, er vi fortsatt i terraform/ mappen
# Kan forårsake problemer i resten av scriptet

# Løsning med Push/Pop (ved feil)
Push-Location terraform
try {
    # Work here
} catch {
    Pop-Location  # Sikrer at vi går tilbake
    throw
}
Pop-Location
```

**Stack-konsept:**
```powershell
# Du kan pushe flere ganger
Push-Location C:\Projects\App1
Push-Location .\src
Push-Location .\components

# Og poppe i revers rekkefølge
Pop-Location  # Tilbake til .\src
Pop-Location  # Tilbake til C:\Projects\App1
Pop-Location  # Tilbake til original location
```

### 5. Terraform Validering

```powershell
Write-Host "1️⃣ Validating Terraform..." -ForegroundColor Yellow
Push-Location terraform

try {
    # Format check
    Write-Host "  Checking format..." -ForegroundColor Gray
    $fmtOutput = terraform fmt -recursive -check
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Run 'terraform fmt -recursive' to fix formatting" -ForegroundColor Red
        exit 1
    }
    
    # Initialize
    Write-Host "  Initializing..." -ForegroundColor Gray
    terraform init -backend=false | Out-Null
    
    # Validate
    Write-Host "  Validating configuration..." -ForegroundColor Gray
    terraform validate | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Terraform validation failed" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "❌ Error during validation: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location
```

**Forklaring:**

#### Format Check
```powershell
$fmtOutput = terraform fmt -recursive -check
```
- Lagrer output i variabel (ikke vist til bruker)
- `-check` - Sjekker kun, endrer ikke filer
- Returnerer exit code 0 hvis OK, non-zero hvis feil

#### Out-Null
```powershell
terraform init -backend=false | Out-Null
```
- Sender output til null (vises ikke)
- Tilsvarende `> /dev/null` i Bash
- Brukes når vi bare bryr oss om exit code

#### Exception Variable
```powershell
catch {
    Write-Host "❌ Error during validation: $_" -ForegroundColor Red
}
```
- `$_` - Nåværende exception-objekt
- Inneholder feilmelding og stack trace
- Tilsvarende `$?` i Bash (men mer info)

#### Cleanup ved Feil
```powershell
catch {
    Pop-Location  # Viktig: går tilbake før exit
    exit 1
}
```

### 6. Artefakt-Oppretting

Dette er den mest interessante delen med Windows-spesifikk logikk!

```powershell
Write-Host "2️⃣ Creating artifact..." -ForegroundColor Yellow
$artifactName = "terraform-${version}.zip"

try {
    # Check if tar is available (Windows 10 1803+)
    $tarAvailable = Get-Command tar -ErrorAction SilentlyContinue
```

**Forklaring:**

#### Get-Command
```powershell
$tarAvailable = Get-Command tar -ErrorAction SilentlyContinue
```
- Sjekker om kommando eksisterer
- `-ErrorAction SilentlyContinue` - Ikke vis feil hvis ikke funnet
- Returnerer command-info hvis funnet, `$null` hvis ikke

**Hvorfor sjekke tar?**
- Windows 10 1803+ og Windows 11 har innebygd tar
- Eldre Windows-versjoner har ikke tar
- tar gir `.tar.gz` (kompatibelt med Linux/Mac)
- Fallback bruker `.zip` (native Windows)

#### Tar-basert Komprimering

```powershell
if ($tarAvailable) {
    # Use tar for .tar.gz (compatible with Linux/Mac)
    $artifactName = "terraform-${version}.tar.gz"
    tar -czf $artifactName terraform/ environments/ backend-configs/
    
    if ($LASTEXITCODE -ne 0) {
        throw "tar command failed"
    }
}
```

**Forklaring:**
- Samme tar-kommando som i Bash
- Sjekker `$LASTEXITCODE` manuelt
- `throw` kaster exception som fanges av `catch`

**Fordeler:**
- ✅ Kompatibelt med Linux/Mac scripts
- ✅ Bedre komprimering enn .zip
- ✅ Bevarer Unix file permissions
- ✅ Standard i CI/CD pipelines

#### Compress-Archive Fallback

```powershell
else {
    # Fallback to Compress-Archive (creates .zip)
    Write-Host "  Note: Using .zip format (tar not available)" -ForegroundColor Gray
    
    # Create temporary directory structure
    $tempDir = "temp-build-$version"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Copy files
    Copy-Item -Path "terraform" -Destination $tempDir -Recurse
    Copy-Item -Path "environments" -Destination $tempDir -Recurse
    Copy-Item -Path "backend-configs" -Destination $tempDir -Recurse
    
    # Compress
    Compress-Archive -Path "$tempDir/*" -DestinationPath $artifactName -Force
    
    # Cleanup temp directory
    Remove-Item -Path $tempDir -Recurse -Force
}
```

**Forklaring:**

**Hvorfor temp directory?**
- `Compress-Archive` pakker filer uten root-mappe
- Vi vil ha samme struktur som tar: `terraform/`, `environments/`, etc.
- Temp directory sikrer korrekt struktur i zip-filen

**New-Item:**
```powershell
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
```
- Oppretter ny mappe
- `-Force` - Overskriver hvis eksisterer
- `| Out-Null` - Skjuler output

**Copy-Item:**
```powershell
Copy-Item -Path "terraform" -Destination $tempDir -Recurse
```
- Kopierer filer og mapper
- `-Recurse` - Inkluderer undermapper
- Tilsvarende `cp -r` i Bash

**Compress-Archive:**
```powershell
Compress-Archive -Path "$tempDir/*" -DestinationPath $artifactName -Force
```
- Native PowerShell komprimering
- `-Path` - Hva som skal pakkes (bruker wildcard `*`)
- `-DestinationPath` - Output-filnavn
- `-Force` - Overskriver eksisterende fil

**Cleanup:**
```powershell
Remove-Item -Path $tempDir -Recurse -Force
```
- Sletter temp directory
- `-Recurse` - Inkluderer alt innhold
- `-Force` - Ingen bekreftelse

**Fordeler med .zip:**
- ✅ Native Windows-format
- ✅ Ingen eksterne avhengigheter
- ✅ Fungerer på alle Windows-versjoner
- ✅ Kan åpnes med Windows Explorer

### 7. Artefakt-Informasjon

```powershell
Write-Host "📊 Artifact Information:" -ForegroundColor Cyan
$artifactInfo = Get-Item $artifactName
$sizeInKB = [math]::Round($artifactInfo.Length / 1KB, 2)
$sizeInMB = [math]::Round($artifactInfo.Length / 1MB, 2)

if ($sizeInMB -ge 1) {
    Write-Host "  File: $artifactName" -ForegroundColor White
    Write-Host "  Size: $sizeInMB MB" -ForegroundColor White
} else {
    Write-Host "  File: $artifactName" -ForegroundColor White
    Write-Host "  Size: $sizeInKB KB" -ForegroundColor White
}

Write-Host "  Created: $($artifactInfo.CreationTime)" -ForegroundColor White
```

**Forklaring:**

#### Get-Item
```powershell
$artifactInfo = Get-Item $artifactName
```
- Henter fil-objekt med metadata
- Inneholder: Name, Length, CreationTime, LastWriteTime, etc.

#### PowerShell Constants
```powershell
$sizeInKB = $artifactInfo.Length / 1KB
$sizeInMB = $artifactInfo.Length / 1MB
```
- `1KB` = 1024 bytes (PowerShell konstant)
- `1MB` = 1024 KB = 1048576 bytes
- `1GB` = 1024 MB (også tilgjengelig)

**Andre constants:**
```powershell
1KB  # 1024
1MB  # 1048576
1GB  # 1073741824
1TB  # 1099511627776
1PB  # 1125899906842624
```

#### Math-klassen
```powershell
[math]::Round($value, 2)
```
- .NET Math-klassen
- `Round()` - Runder til angitt antall desimaler
- `2` - To desimaler (f.eks. 45.37 MB)

**Andre Math-funksjoner:**
```powershell
[math]::Ceiling(4.2)   # 5
[math]::Floor(4.8)     # 4
[math]::Round(4.5)     # 4 (banker's rounding)
[math]::Abs(-5)        # 5
[math]::Max(10, 20)    # 20
[math]::Min(10, 20)    # 10
[math]::Sqrt(16)       # 4
[math]::Pow(2, 3)      # 8
```

#### String Interpolation i Subexpression
```powershell
Write-Host "  Created: $($artifactInfo.CreationTime)" -ForegroundColor White
```
- `$()` - Subexpression (evaluerer kode)
- Nødvendig for å aksessere properties i strings
- Uten `$()`: ville skrive objektet direkte

**Eksempler:**
```powershell
# Fungerer ikke riktig:
"File created: $artifactInfo.CreationTime"
# Output: File created: System.IO.FileInfo.CreationTime

# Fungerer:
"File created: $($artifactInfo.CreationTime)"
# Output: File created: 01/07/2025 14:30:22
```

### 8. Next Steps Output

```powershell
Write-Host "🎯 Next steps:" -ForegroundColor Cyan
Write-Host "  - Deploy to dev:  .\scripts\deploy.ps1 -Environment dev -Artifact $artifactName" -ForegroundColor Gray
Write-Host "  - Deploy to test: .\scripts\deploy.ps1 -Environment test -Artifact $artifactName" -ForegroundColor Gray
```

**Forklaring:**
- Viser PowerShell-syntax med named parameters
- `.\` - Relativ sti i PowerShell (ikke bare `.`)
- `-Environment` og `-Artifact` - Named parameters (PowerShell best practice)

## Bruk av Scriptet

### Grunnleggende Kjøring

```powershell
# Naviger til prosjektmappen
cd C:\Projects\terraform-demo

# Kjør build-script
.\build.ps1
```

### Kjøring med Execution Policy Bypass

```powershell
# Engangs bypass (ikke permanent)
powershell -ExecutionPolicy Bypass -File .\build.ps1

# Eller
PowerShell -ExecutionPolicy Bypass .\build.ps1
```

### Kjøring fra Command Prompt (cmd)

```cmd
REM Fra cmd.exe
powershell.exe -ExecutionPolicy Bypass -File .\build.ps1
```

### Forventet Output

```
📦 Building Terraform Artifact...

Version: a3f5c2e

1️⃣ Validating Terraform...
  Checking format...
  Initializing...
  Validating configuration...
✅ Validation complete!

2️⃣ Creating artifact...
✅ Artifact created: terraform-a3f5c2e.tar.gz

📊 Artifact Information:
  File: terraform-a3f5c2e.tar.gz
  Size: 45.37 KB
  Created: 01/07/2025 14:30:22

🎯 Next steps:
  - Deploy to dev:  .\scripts\deploy.ps1 -Environment dev -Artifact terraform-a3f5c2e.tar.gz
  - Deploy to test: .\scripts\deploy.ps1 -Environment test -Artifact terraform-a3f5c2e.tar.gz
```

## Feilsøking

### Problem: "Cannot be loaded because running scripts is disabled"

**Fullt feilmelding:**
```
.\build.ps1 : File C:\Projects\build.ps1 cannot be loaded because running scripts 
is disabled on this system. For more information, see about_Execution_Policies at 
https:/go.microsoft.com/fwlink/?LinkID=135170.
```

**Årsak:** Execution Policy blokkerer scripts

**Løsning 1 - Endre policy (anbefalt):**
```powershell
# For nåværende bruker (krever ikke admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verifiser
Get-ExecutionPolicy -List
```

**Løsning 2 - Bypass for enkelt script:**
```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

**Løsning 3 - Unblock fil (hvis nedlastet):**
```powershell
Unblock-File -Path .\build.ps1
```

### Problem: "terraform: command not found"

**Årsak:** Terraform ikke i PATH

**Løsning:**
```powershell
# Sjekk om terraform er installert
Get-Command terraform -ErrorAction SilentlyContinue

# Hvis ikke funnet, installer Terraform eller legg til PATH
$env:Path += ";C:\Tools\terraform"

# Permanent (via System Properties eller):
[Environment]::SetEnvironmentVariable(
    "Path", 
    $env:Path + ";C:\Tools\terraform", 
    [EnvironmentVariableTarget]::User
)
```

### Problem: "terraform fmt failed"

**Løsning:**
```powershell
# Naviger til terraform-mappen
cd terraform

# Fiks formatering automatisk
terraform fmt -recursive

# Gå tilbake og kjør build
cd ..
.\build.ps1
```

### Problem: "Path not found: terraform/"

**Årsak:** Script kjøres fra feil lokasjon

**Løsning:**
```powershell
# Sjekk nåværende lokasjon
Get-Location

# Naviger til riktig sted (prosjektets rot)
cd C:\Projects\terraform-demo

# Verifiser struktur
Get-ChildItem

# Kjør script
.\build.ps1
```

### Problem: Tar ikke tilgjengelig (eldre Windows)

**Dette er ikke en feil!** Scriptet bruker automatisk .zip i stedet.

**Verifiser:**
```powershell
# Sjekk om tar finnes
Get-Command tar -ErrorAction SilentlyContinue

# Hvis ikke:
# Windows 10 1803+ og Windows 11 har tar innebygd
# Eldre versjoner kan installere Git for Windows (inkluderer tar)
```

**Alternativ - installer tar manuelt:**
```powershell
# Via Chocolatey
choco install gnuwin32-tar.install

# Via Scoop
scoop install tar
```

### Problem: "Access denied" ved filoperasjoner

**Årsak:** Mangler rettigheter eller fil er låst

**Løsning:**
```powershell
# Sjekk fil-locks
Get-Process | Where-Object {$_.Path -like "*terraform*"}

# Kjør PowerShell som Administrator (hvis nødvendig)
Start-Process powershell -Verb RunAs

# Eller sjekk ACL
Get-Acl .\terraform | Format-List
```

## PowerShell-spesifikke Tips og Triks

### 1. Tab Completion

PowerShell har kraftig tab completion:

```powershell
# Tab completion for filer
.\bui<TAB>       # Utvides til .\build.ps1

# Tab completion for parametere
.\build.ps1 -<TAB>   # Viser tilgjengelige parametere

# Tab completion for paths
cd C:\Pr<TAB>    # Utvides til C:\Program Files\
```

### 2. Transcript Logging

Logg all output fra script:

```powershell
# Start logging
Start-Transcript -Path "build-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Kjør script
.\build.ps1

# Stopp logging
Stop-Transcript
```

### 3. Verbose og Debug Output

Legg til verbose/debug i scriptet:

```powershell
[CmdletBinding()]
param()

Write-Verbose "Starting build process..."
Write-Debug "Version variable: $version"

# Kjør med:
.\build.ps1 -Verbose
.\build.ps1 -Debug
```

### 4. Parameter Validation

Forbedre script med parametre:

```powershell
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("manual", "auto")]
    [string]$VersionMode = "auto",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "."
)

# Bruk:
.\build.ps1 -VersionMode manual
.\build.ps1 -OutputPath "C:\Artifacts"
```

### 5. Error Handling Best Practice

```powershell
try {
    # Risky operation
    terraform validate
    
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform validation failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
} finally {
    # Cleanup (kjøres alltid)
    Pop-Location
}
```

### 6. Progress Bars

```powershell
Write-Progress -Activity "Building Artifact" -Status "Validating..." -PercentComplete 30
# ... validation code ...
Write-Progress -Activity "Building Artifact" -Status "Creating archive..." -PercentComplete 70
# ... compression code ...
Write-Progress -Activity "Building Artifact" -Completed
```

## CI/CD Integrering

### Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Build Terraform Artifact'
  inputs:
    filePath: 'build.ps1'
    errorActionPreference: 'stop'
    
- task: PublishBuildArtifacts@1
  inputs:
    PathtoPublish: 'terraform-*.tar.gz'
    ArtifactName: 'terraform-artifact'
```

### GitHub Actions

```yaml
name: Build Terraform Artifact

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      
    - name: Build Artifact
      shell: pwsh
      run: |
        .\build.ps1
        
    - name: Upload Artifact
      uses: actions/upload-artifact@v3
      with:
        name: terraform-artifact
        path: terraform-*.tar.gz
```

### GitLab CI

```yaml
build:
  stage: build
  tags:
    - windows
  script:
    - powershell.exe -ExecutionPolicy Bypass -File .\build.ps1
  artifacts:
    paths:
      - terraform-*.tar.gz
    expire_in: 30 days
```

## Best Practices

### 1. Signed Scripts (Enterprise)

```powershell
# Signer script med code signing certificate
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
Set-AuthenticodeSignature -FilePath .\build.ps1 -Certificate $cert

# Verifiser signatur
Get-AuthenticodeSignature -FilePath .\build.ps1
```

### 2. Module-basert Struktur

```powershell
# TerraformBuild.psm1 (module)
function Invoke-TerraformBuild {
    [CmdletBinding()]
    param(
        [string]$Version = "auto"
    )
    
    # Build logic here
}

Export-ModuleMember -Function Invoke-TerraformBuild

# Bruk i script:
Import-Module .\TerraformBuild.psm1
Invoke-TerraformBuild
```

### 3. Konfigurasjonsfil

```powershell
# build-config.json
{
  "includePaths": ["terraform", "environments", "backend-configs"],
  "excludePatterns": ["*.tfstate", "*.backup"],
  "compressionMethod": "tar",
  "versionPrefix": "v"
}

# I script:
$config = Get-Content .\build-config.json | ConvertFrom-Json
```

### 4. Dry-Run Mode

```powershell
param(
    [switch]$DryRun
)

if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be created" -ForegroundColor Yellow
    # Vis hva som ville blitt gjort
    Write-Host "Would create: terraform-$version.tar.gz"
    exit 0
}
```

## Sammenligning: Bash vs PowerShell

| Funksjon | Bash | PowerShell |
|----------|------|------------|
| **Variabel** | `VERSION="1.0"` | `$version = "1.0"` |
| **String concat** | `"text-${VAR}"` | `"text-$version"` |
| **If statement** | `if [ -f "file" ]; then` | `if (Test-Path "file") {` |
| **For loop** | `for i in *; do` | `foreach ($i in Get-ChildItem) {` |
| **Exit on error** | `set -e` | `$ErrorActionPreference = "Stop"` |
| **Null redirect** | `2>/dev/null` | `2>$null` eller `Out-Null` |
| **Command check** | `command -v tar` | `Get-Command tar` |
| **Pipe to nothing** | `>/dev/null` | `| Out-Null` |
| **Change dir** | `cd dir && ... || cd ..` | `Push-Location; try {...} finally {Pop-Location}` |
| **Compress** | `tar -czf` | `tar -czf` eller `Compress-Archive` |
| **File info** | `ls -lh` | `Get-Item | Select Length,CreationTime` |

## Oppsummering

Dette PowerShell-scriptet tilbyr:

### ✅ Fordeler
- **Native Windows-støtte** - Ingen Git Bash nødvendig
- **Cross-platform** - Fungerer med PowerShell Core på Linux/Mac
- **Intelligent fallback** - Bruker tar hvis tilgjengelig, ellers .zip
- **Farget output** - Mer lesbart enn Bash
- **Bedre error handling** - Try-catch med detaljert info
- **Type safety** - PowerShell er sterkere typed enn Bash
- **Object pipeline** - Jobber med objekter, ikke bare tekst

### 🎯 Best Practices Fulgt
- ✅ Stopper ved feil (`$ErrorActionPreference`)
- ✅ Bruker `Push/Pop-Location` for sikker navigasjon
- ✅ Try-catch-finally for error handling
- ✅ Farget output for bedre UX
- ✅ Detaljert artefakt-informasjon
- ✅ Kompatibel med både moderne og eldre Windows

### 🚀 Når Bruke Dette
- Windows-utviklere uten Git Bash
- Enterprise Windows-miljøer
- Azure DevOps pipelines
- Teams som foretrekker PowerShell
- Cross-platform utvikling (med PowerShell Core)

Med dette scriptet har Windows-utviklere et like kraftig build-verktøy som Linux/Mac-brukere! 🎉
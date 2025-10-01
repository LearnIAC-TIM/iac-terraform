# Importere Terraform tfvars til Azure Key Vault

Denne guiden viser hvordan du kan lagre verdier fra `.tfvars` filer i Azure Key Vault ved hjelp av PowerShell.

## Forutsetninger

- Azure CLI installert og innlogget (`az login`)
- PowerShell 7+ anbefales
- Et eksisterende Azure Key Vault
- Nødvendige tilgangsrettigheter til Key Vault

## Metode 1: Importere hele .tfvars filen som én secret

Denne metoden lagrer hele filen som en enkelt secret i Key Vault.

### PowerShell Script: Import-TfvarsFile.ps1

```powershell
# Parametere
param(
    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$TfvarsFilePath,
    
    [Parameter(Mandatory=$true)]
    [string]$SecretName
)

# Les hele filen som tekst
$fileContent = Get-Content -Path $TfvarsFilePath -Raw

# Lagre til Key Vault
az keyvault secret set `
    --vault-name $KeyVaultName `
    --name $SecretName `
    --value $fileContent

Write-Host "✓ Hele filen '$TfvarsFilePath' er lagret som secret '$SecretName' i Key Vault '$KeyVaultName'"
```

### Bruk av scriptet

```powershell
./Import-TfvarsFile.ps1 `
    -KeyVaultName "mitt-keyvault" `
    -TfvarsFilePath "./terraform.tfvars" `
    -SecretName "terraform-tfvars"
```

---

## Metode 2: Importere individuelle variabler som separate secrets

Denne metoden parser `.tfvars` filen og lagrer hver variabel som en egen secret.

### PowerShell Script: Import-TfvarsVariables.ps1

```powershell
# Parametere
param(
    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$TfvarsFilePath,
    
    [string]$Prefix = ""
)

# Les filen linje for linje
$lines = Get-Content -Path $TfvarsFilePath

# Teller for suksessfulle imports
$successCount = 0

foreach ($line in $lines) {
    # Hopp over tomme linjer og kommentarer
    if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith("#")) {
        continue
    }
    
    # Parse linjen (format: variabel_navn = "verdi")
    if ($line -match '^\s*([a-zA-Z0-9_-]+)\s*=\s*(.+)$') {
        $variableName = $matches[1].Trim()
        $variableValue = $matches[2].Trim()
        
        # Fjern anførselstegn hvis de finnes
        $variableValue = $variableValue -replace '^"(.*)"$', '$1'
        $variableValue = $variableValue -replace "^'(.*)'$", '$1'
        
        # Lag secret navn (med prefix hvis angitt)
        if ($Prefix) {
            $secretName = "$Prefix-$variableName"
        } else {
            $secretName = $variableName
        }
        
        # Lagre til Key Vault
        try {
            az keyvault secret set `
                --vault-name $KeyVaultName `
                --name $secretName `
                --value $variableValue `
                --output none
            
            Write-Host "✓ Lagret: $secretName = $variableValue"
            $successCount++
        }
        catch {
            Write-Host "✗ Feil ved lagring av $secretName : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`n$successCount secrets ble lagret i Key Vault '$KeyVaultName'"
```

### Bruk av scriptet

```powershell
# Uten prefix
./Import-TfvarsVariables.ps1 `
    -KeyVaultName "mitt-keyvault" `
    -TfvarsFilePath "./terraform.tfvars"

# Med prefix (anbefalt for å organisere secrets)
./Import-TfvarsVariables.ps1 `
    -KeyVaultName "mitt-keyvault" `
    -TfvarsFilePath "./terraform.tfvars" `
    -Prefix "terraform"
```

---

## Eksempel på terraform.tfvars fil

```hcl
# Azure konfigurasjon
resource_group_name = "rg-student-prod"
location = "norwayeast"
environment = "production"

# App Service konfigurasjon
app_service_name = "app-student-web"
app_service_sku = "B1"

# Database konfigurasjon
sql_server_name = "sql-student-server"
sql_admin_username = "sqladmin"
sql_admin_password = "P@ssw0rd123!"
```

---

## Hente secrets i GitHub Actions Workflow

### Eksempel: Bruk av individuelle secrets

```yaml
name: Terraform Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Hent secrets fra Key Vault
      uses: azure/CLI@v1
      with:
        inlineScript: |
          echo "RESOURCE_GROUP=$(az keyvault secret show --vault-name mitt-keyvault --name terraform-resource-group-name --query value -o tsv)" >> $GITHUB_ENV
          echo "LOCATION=$(az keyvault secret show --vault-name mitt-keyvault --name terraform-location --query value -o tsv)" >> $GITHUB_ENV
          echo "APP_NAME=$(az keyvault secret show --vault-name mitt-keyvault --name terraform-app-service-name --query value -o tsv)" >> $GITHUB_ENV
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
    
    - name: Terraform Init
      run: terraform init
    
    - name: Terraform Apply
      run: |
        terraform apply -auto-approve \
          -var="resource_group_name=${{ env.RESOURCE_GROUP }}" \
          -var="location=${{ env.LOCATION }}" \
          -var="app_service_name=${{ env.APP_NAME }}"
```

---

## Viktige fallgruver og anbefalinger

### 1. Formatering av hele .tfvars filer

**Problem:** Når du importerer hele `.tfvars` filen som én secret, kan linjeskift og spesialtegn ødelegges.

**Løsning:** 
- Bruk `-Raw` parameteren i PowerShell for å bevare formatering
- Test alltid at filen kan brukes etter henting fra Key Vault

### 2. Manglende anførselstegn rundt strenger

**Problem:** I `.tfvars` filer er strengverdier normalt uten anførselstegn:
```hcl
resource_group_name = rg-student-prod  # Mangler ""
```

Men i YAML workflows må verdier med bindestreker ha anførselstegn:
```yaml
# ✗ FEIL - kan feile hvis verdi inneholder spesialtegn
resource_group: ${{ env.RESOURCE_GROUP }}

# ✓ RIKTIG
resource_group: "${{ env.RESOURCE_GROUP }}"
```

**Anbefaling:** 
- Bruk alltid anførselstegn rundt variabler i YAML
- Vurder å legge til anførselstegn i `.tfvars` filen fra start

### 3. Spesialtegn i secret-navn

**Problem:** Key Vault secret-navn kan ikke inneholde understreker `_` i noen Azure-tjenester.

**Løsning:**
- Bruk bindestreker `-` i stedet for understreker
- Scriptet over håndterer dette ved å erstatte `_` med `-`

### 4. Komplekse datatyper

**Problem:** Lister og objekter i `.tfvars` filer er vanskelige å parse:
```hcl
tags = {
  environment = "production"
  project = "student-app"
}
```

**Anbefaling:**
- Bruk kun enkle nøkkel-verdi par for automatisk import
- Håndter komplekse strukturer manuelt

### 5. Sensitive verdier

**Problem:** Passord og API-nøkler lagres i klartekst i `.tfvars` filer.

**Anbefaling:**
- **ALDRI** commit `.tfvars` filer med sensitive verdier til Git
- Legg til `*.tfvars` i `.gitignore`
- Bruk Key Vault som primær kilde for sensitive verdier
- Opprett secrets manuelt for passord og API-nøkler

### 6. Secret-versjonering

**Viktig å vite:** Key Vault beholder alle versjoner av secrets. Når du oppdaterer en secret, opprettes en ny versjon automatisk.

---

## Best Practices

1. **Organiser secrets med prefix**: Bruk prefix som `terraform-`, `dev-`, `prod-` for å skille miljøer
2. **Dokumenter secret-navn**: Hold en liste over hvilke secrets som finnes i Key Vault
3. **Bruk managed identities**: I produksjon, bruk Managed Identity i stedet for service principals
4. **Sett opp tilgangskontroll**: Gi kun nødvendige tilganger til Key Vault
5. **Overvåk tilgang**: Aktiver logging for å se hvem som henter secrets

---

## Feilsøking

### "Secret name is invalid"
- Secret-navn kan kun inneholde `a-z`, `0-9` og `-`
- Maks 127 tegn

### "Access denied"
- Sjekk at du har `Secret Management` tilgang i Key Vault
- Kjør `az keyvault set-policy` for å gi tilgang

### "Secret not found" i GitHub Actions
- Verifiser at secret-navnet er korrekt
- Sjekk at GitHub Actions har tilgang til Key Vault via Service Principal

---

## Oppsummering

- **Metode 1** (hele filen): Enkel, men vanskelig å bruke individuelle verdier
- **Metode 2** (individuelle secrets): Anbefalt for fleksibilitet og enkel bruk i workflows
- Husk alltid anførselstegn i YAML workflows
- Aldri commit sensitive `.tfvars` filer til Git
- Bruk Key Vault som single source of truth for sensitive konfigurasjon
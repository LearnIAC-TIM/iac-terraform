# Terraform Cleanup Script - Komplett Veiledning

## Oversikt

Dette Bash-scriptet (`cleanup.sh`) er et kraftig og farlig verktøy som lar deg rydde opp i Terraform-deployments og lokale filer. Scriptet tilbyr en **interaktiv meny** med 8 ulike valg, fra å slette enkeltmiljøer til fullstendig opprydding av alt.

⚠️ **KRITISK ADVARSEL:** Dette scriptet sletter infrastruktur og data. Bruk med ekstrem forsiktighet, spesielt i produksjonsmiljøer!

## Forutsetninger

### Nødvendig Programvare
- **Bash shell** (Linux/macOS/Git Bash)
- **Terraform CLI** (for terraform destroy)
- **Azure CLI** (`az`) for Azure-operasjoner
- **Gyldig Azure-pålogging** med nødvendige slette-rettigheter

### Nødvendige Tilganger
- **Contributor** eller **Owner** rolle på subscription/resource groups
- Tilgang til Terraform state storage
- Rettigheter til å slette ressurser

## Når Bruker du Dette Scriptet?

### ✅ Passende Bruksområder
- Rydde opp i dev/test-miljøer etter testing
- Slette gamle workspace-filer lokalt
- Fjerne infrastruktur som ikke lenger trengs
- Tømme miljø før full re-deployment
- Debugging når Terraform er i uønsket tilstand

### ⛔ Når du IKKE skal bruke det
- I produksjon uten grundig gjennomgang
- Når andre jobber i samme miljø
- Hvis du er usikker på hva som vil bli slettet
- Uten backup av kritisk data

## Detaljert Gjennomgang

### 1. Shebang og Feilhåndtering

```bash
#!/bin/bash
set -e
```

**Forklaring:**
- `set -e` - Stopper scriptet ved feil, men...
- I dette scriptet brukes også manuell feilhåndtering (sjekk `return` statements)
- Kombinasjonen gir robust feilhåndtering for kritiske operasjoner

### 2. Destroy Environment Funksjon

Dette er scriptets kjernelogikk for å slette infrastruktur.

```bash
destroy_environment() {
    local ENV=$1
    local WORKSPACE="workspace-${ENV}"
```

**Forklaring:**
- `local` - Gjør variablene lokale til funksjonen (ikke globale)
- `$1` - Første parameter til funksjonen (miljønavn: dev, test, prod)
- Funksjon kan kalles flere ganger med ulike miljøer

#### 2.1 Workspace-Validering

```bash
if [ ! -d "$WORKSPACE" ]; then
    echo "⚠️  Workspace not found: $WORKSPACE"
    echo "   Skipping terraform destroy (use Azure cleanup if needed)"
    echo ""
    return
fi
```

**Forklaring:**
- `[ ! -d "$WORKSPACE" ]` - Sjekker om workspace-mappen IKKE eksisterer
- Hvis workspace mangler, kan Terraform ikke kjøres
- `return` - Avslutter funksjonen (ikke hele scriptet)
- Brukeren får beskjed om å bruke Azure CLI cleanup i stedet

**Hvorfor dette er viktig:**
- Unngår feil når workspace er allerede fjernet
- Infrastrukturen kan fortsatt eksistere i Azure selv om workspace er borte

#### 2.2 Azure-Autentisering

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null)
if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "❌ Error: Not logged in to Azure"
    echo "   Please run: az login"
    return 1
fi

export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
```

**Forklaring:**
- `2>/dev/null` - Skjuler feilmeldinger (stderr)
- `return 1` - Returnerer feilkode (1 = feil, 0 = suksess)
- Eksporterer subscription ID for Terraform

**Hvorfor skjule feilmeldinger?**
- Gir mer brukervennlig output
- Vi håndterer feilen selv med klar melding

#### 2.3 Terraform Initialisering

```bash
cd "$WORKSPACE/terraform"

if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init -backend-config=../backend-configs/backend-${ENV}.tfvars
    echo ""
fi
```

**Forklaring:**
- Sjekker om `.terraform/` mappen eksisterer
- Hvis ikke: initialiserer Terraform med backend-konfigurasjon
- Nødvendig for å laste ned providers og koble til state

**Hvorfor kun "if needed"?**
- Sparer tid hvis allerede initialisert
- Unngår unødvendige API-kall til backend

#### 2.4 Destruction Plan

```bash
echo "📋 Planning destruction..."
terraform plan -destroy -var-file=../environments/${ENV}.tfvars
echo ""
```

**Forklaring:**
- `terraform plan -destroy` - Viser hva som vil bli slettet
- **IKKE** `-out` flag her (planen lagres ikke)
- Gir brukeren oversikt før bekreftelse

**Hva planen viser:**
```
Plan: 0 to add, 0 to change, 15 to destroy.

Changes to Outputs:
  - resource_group_name = "myapp-dev-rg" -> null
  - storage_account_id  = "/subscriptions/.../storage" -> null
```

#### 2.5 Brukerbekreftelse

```bash
read -p "❓ Destroy $ENV environment? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "⏭️  Skipped $ENV"
    cd ../..
    echo ""
    return
fi
```

**Forklaring:**
- `read -p` - Leser input fra bruker med prompt
- Krever eksplisitt "yes" (ikke "y" eller "Yes")
- Dette er en ekstra sikkerhet mot utilsiktet sletting
- `cd ../..` - Går tilbake før retur

**Hvorfor strikt "yes"?**
- Forhindrer at brukeren ved et uhell trykker feil tast
- Tvinger bevisst valg ved kritiske operasjoner

#### 2.6 Destruksjon

```bash
echo ""
echo "💥 Destroying infrastructure..."
terraform destroy -var-file=../environments/${ENV}.tfvars -auto-approve

cd ../..
echo ""
echo "✅ $ENV environment destroyed"
echo ""
```

**Forklaring:**
- `terraform destroy` - Sletter all infrastruktur
- `-auto-approve` - Hopper over ekstra bekreftelse (allerede bekreftet i skriv)
- Går tilbake til prosjektrot etter fullført sletting

**Hva skjer under destruksjon:**
1. Terraform leser state-filen
2. Identifiserer alle ressurser som skal slettes
3. Sletter ressurser i riktig rekkefølge (reverse dependencies)
4. Oppdaterer state til tom tilstand
5. Beholder state-filen (for historikk)

### 3. Hovedmeny

```bash
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
```

**Forklaring:**
- Interaktiv meny med 8 valg
- Numerisk input (0-7)
- Tydelige beskrivelser for hvert valg

### 4. Case Statement - Valgbehandling

#### Valg 1-3: Enkeltmiljø

```bash
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
```

**Forklaring:**
- Enkel case for å kalle `destroy_environment` med riktig miljø
- `;;` - Avslutter case-blokk (som `break` i andre språk)

#### Valg 4: Alle Miljøer

```bash
    4)
        destroy_environment "dev"
        destroy_environment "test"
        destroy_environment "prod"
        ;;
```

**Forklaring:**
- Kaller funksjonen tre ganger sekvensielt
- Hver destruksjon krever individuell bekreftelse
- Stopper ved første feil (pga `set -e`)

**Viktig å merke seg:**
- Du får spørsmål for hvert miljø
- Kan velge å hoppe over enkelte
- Hvis dev feiler, fortsetter ikke til test/prod

#### Valg 5: Kun Lokale Filer

```bash
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
```

**Forklaring:**

**Workspace-sletting:**
- `ls -d workspace-*` - Lister kun mapper som matcher mønster
- `2>/dev/null` - Skjuler feil hvis ingen treff
- `rm -rf workspace-*` - Sletter alle workspace-mapper rekursivt

**Artefakt-sletting:**
- `ls terraform-*.tar.gz` - Finner alle .tar.gz filer
- `rm -f terraform-*.tar.gz` - Sletter uten bekreftelse
- `-f` - Force (ingen advarsel hvis filen ikke finnes)

**Når bruke dette?**
- Du har allerede slettet infrastruktur manuelt
- Workspace-filer tar for mye plass
- Rydde opp etter feilede deployments
- Nullstille lokal tilstand

**Viktig:** Sletter IKKE infrastrukturen i Azure!

#### Valg 6: Force Cleanup via Azure CLI

Dette er den mest kraftige og farlige delen av scriptet.

```bash
    6)
        echo "💥 Force cleanup via Azure CLI"
        echo ""
        echo "⚠️  WARNING: This will delete resource groups directly!"
        echo "   Use this only if terraform destroy fails."
        echo ""
        read -p "Continue? (yes/no): " confirm
```

**Når bruke dette:**
- Terraform destroy feiler gjentatte ganger
- State-fil er korrupt eller mangler
- Ressurser er slettet manuelt og Terraform er ute av sync
- Emergency cleanup nødvendig

**Advarsler:**
- Bypasser Terraform helt
- Ingen "plan" å se på forhånd
- Sletter resource groups med ALT innhold
- Kan føre til "orphaned" ressurser i andre groups

##### 6.1 Liste Resource Groups

```bash
if [ "$confirm" == "yes" ]; then
    echo ""
    echo "Available resource groups:"
    az group list --query "[?starts_with(name, 'rg-demo-')].{Name:name, Location:location}" -o table
    echo ""
    read -p "Enter resource group name to delete (or 'all' for all demo groups): " rg_name
```

**Forklaring:**

- `az group list` - Lister alle resource groups
- `--query` - JMESPath query for filtrering
- `[?starts_with(name, 'rg-demo-')]` - Filtrer på navn som starter med "rg-demo-"
- `.{Name:name, Location:location}` - Velg kun Name og Location felter
- `-o table` - Output som tabell (lettere å lese)

**Eksempel output:**
```
Name                Location
------------------  -----------
rg-demo-dev        norwayeast
rg-demo-test       norwayeast
rg-demo-prod       westeurope
```

##### 6.2 Slette Resource Groups

```bash
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
```

**Forklaring:**

**For-loop:**
- `$(...)` - Command substitution (kjører kommando og itererer over output)
- `-o tsv` - Tab-Separated Values (ren tekst, en linje per gruppe)
- Loop kjører én gang per resource group

**Azure Delete:**
- `az group delete` - Sletter resource group
- `--yes` - Bekrefter automatisk (ingen prompt)
- `--no-wait` - Returnerer umiddelbart (venter ikke på fullføring)

**Hvorfor --no-wait?**
- Resource group sletting tar lang tid (5-30 minutter)
- Scriptet ville henge mens det venter
- Sletting fortsetter i bakgrunnen i Azure
- Du kan sjekke status med `az group list -o table`

##### 6.3 Slette Enkelt Resource Group

```bash
elif [ ! -z "$rg_name" ]; then
    echo ""
    echo "🔥 Deleting: $rg_name"
    az group delete --name "$rg_name" --yes --no-wait
    echo ""
    echo "✅ Deletion initiated"
fi
```

**Forklaring:**
- `[ ! -z "$rg_name" ]` - Sjekker at input ikke er tom
- Sletter kun den spesifiserte resource group
- Samme `--no-wait` logikk som "all"

#### Valg 7: Full Cleanup

```bash
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
```

**Forklaring:**

**Hva slettes:**
1. ✅ All infrastruktur i dev (via Terraform)
2. ✅ All infrastruktur i test (via Terraform)
3. ✅ All infrastruktur i prod (via Terraform)
4. ✅ Alle workspace-mapper
5. ✅ Alle bygde artefakter

**Viktig:**
- Kombinerer valg 4 (alle miljøer) + valg 5 (lokale filer)
- Krever én bekreftelse for hele operasjonen
- Deretter individuell bekreftelse for hvert miljø
- Mest omfattende cleanup-alternativet

#### Valg 0: Avbryt

```bash
    0)
        echo "Cancelled"
        exit 0
        ;;
```

**Forklaring:**
- `exit 0` - Avslutter scriptet med suksess-kode
- Ingenting slettes

#### Ugyldig Valg

```bash
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
```

**Forklaring:**
- `*` - Default case (matcher alt annet)
- `exit 1` - Avslutter med feilkode

## Bruk av Scriptet

### Grunnleggende Kjøring

```bash
# Gjør scriptet kjørbart (første gang)
chmod +x cleanup.sh

# Kjør scriptet
./cleanup.sh
```

### Eksempel: Slette Dev-miljø

```bash
$ ./cleanup.sh

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
      - id       = "/subscriptions/.../resourceGroups/myapp-dev-rg"
      - location = "norwayeast"
      - name     = "myapp-dev-rg"
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

```bash
$ ./cleanup.sh

Enter choice [0-7]: 5

🧹 Cleaning local files...

  Removing workspaces...
  ✅ Workspaces removed
  Removing artifacts...
  ✅ Artifacts removed

✅ Local cleanup complete
```

### Eksempel: Force Cleanup

```bash
$ ./cleanup.sh

Enter choice [0-7]: 6

💥 Force cleanup via Azure CLI

⚠️  WARNING: This will delete resource groups directly!
   Use this only if terraform destroy fails.

Continue? (yes/no): yes

Available resource groups:
Name                Location
------------------  -----------
rg-demo-dev        norwayeast
rg-demo-test       norwayeast

Enter resource group name to delete (or 'all' for all demo groups): rg-demo-dev

🔥 Deleting: rg-demo-dev

✅ Deletion initiated
```

## Feilsøking

### Problem: "Workspace not found"

**Årsak:** Workspace-mappen eksisterer ikke lokalt

**Løsninger:**

```bash
# Alternativ 1: Bruk force cleanup (valg 6)
./cleanup.sh
# Velg 6, deretter skriv inn resource group navnet

# Alternativ 2: Manuell sletting via Azure Portal eller CLI
az group delete --name rg-demo-dev --yes
```

### Problem: "Not logged in to Azure"

**Årsak:** Azure CLI session er utløpt

**Løsning:**
```bash
# Logg inn på nytt
az login

# Velg riktig subscription
az account set --subscription "My Subscription"

# Prøv cleanup igjen
./cleanup.sh
```

### Problem: "Error acquiring state lock"

**Årsak:** State-låsen er tatt av en annen operasjon

**Løsning:**
```bash
# Vent 5-10 minutter, prøv igjen

# Hvis fortsatt låst, force unlock
cd workspace-dev/terraform
terraform force-unlock <LOCK_ID>

# Eller bruk force cleanup (valg 6)
```

### Problem: "Some resources failed to delete"

**Årsak:** Ressursavhengigheter eller Azure-begrensninger

**Løsning:**
```bash
# Prøv destroy én gang til (kan være temporary Azure issue)
./cleanup.sh

# Hvis fortsatt feiler, bruk force cleanup
# Valg 6, så manuell sletting av resource group
```

### Problem: Terraform destroy tar evig tid

**Årsak:** Mange ressurser eller Azure er treg

**Løsning:**
```bash
# Avbryt med Ctrl+C

# Bruk force cleanup i stedet
./cleanup.sh
# Velg 6 for Azure CLI cleanup (raskere)
```

### Problem: "Resource group not found" etter cleanup

**Dette er forventet!** Resource group er slettet. Verifiser:

```bash
# Sjekk at resource group er borte
az group list --query "[?name=='rg-demo-dev']" -o table

# Tomt resultat = vellykket sletting
```

## Sikkerhet og Best Practices

### 🔴 KRITISKE ADVARSLER

#### 1. Produksjonsmiljøer

```bash
# ALDRI bruk valg 4 eller 7 uten grundig gjennomgang
# Disse sletter ALLE miljøer inkludert prod

# For prod: Bruk valg 3 og dobbeltsjekk alt
```

#### 2. Backup Før Sletting

```bash
# Eksporter viktig data først
az storage blob download-batch \
  --source mycontainer \
  --destination ./backup/

# Ta backup av Terraform state
terraform state pull > backup-state-$(date +%Y%m%d).json
```

#### 3. Teamkoordinering

```bash
# Sjekk at ingen andre jobber i miljøet
# Gi beskjed i team-chat før cleanup

# Sjekk state locks
az storage blob list \
  --account-name tfstateaccount \
  --container-name tfstate \
  --query "[?contains(name, '.lock')]"
```

### ✅ Best Practices

#### 1. Test Cleanup i Dev Først

```bash
# Test alltid i dev før prod
./cleanup.sh
# Velg 1 (dev only)

# Verifiser at alt fungerte
az group list -o table
```

#### 2. Bruk Riktig Verktøy

| Scenario | Anbefalt Valg |
|----------|---------------|
| Normal cleanup | Valg 1-3 (Terraform destroy) |
| Terraform feiler | Valg 6 (Force via Azure CLI) |
| Kun lokale filer | Valg 5 |
| Emergency full cleanup | Valg 7 (med forsiktighet!) |

#### 3. Logging

```bash
# Logg all cleanup for audit trail
./cleanup.sh 2>&1 | tee cleanup-$(date +%Y%m%d-%H%M%S).log

# Send til syslog
logger -t terraform-cleanup "Cleanup initiated for dev environment"
```

#### 4. Verifiser Etter Cleanup

```bash
# Sjekk Azure
az group list -o table

# Sjekk lokale filer
ls -la workspace-*/
ls -la terraform-*.tar.gz

# Sjekk Terraform state
cd workspace-dev/terraform
terraform show  # Skal vise tomt
```

## Avanserte Scenarioer

### Protected Environments

Legg til beskyttelse for prod:

```bash
# I destroy_environment funksjonen, før destruksjon:
if [ "$ENV" == "prod" ]; then
    echo "🔒 PRODUCTION ENVIRONMENT - Extra confirmation required"
    read -p "Type the environment name to confirm: " confirm_env
    if [ "$confirm_env" != "prod" ]; then
        echo "❌ Confirmation failed"
        return 1
    fi
fi
```

### Selective Resource Deletion

```bash
# Før full destroy, tillat selektiv sletting
echo "Delete specific resources? (yes/no): "
read selective

if [ "$selective" == "yes" ]; then
    # List all resources
    terraform state list
    
    echo "Enter resource to remove (e.g., azurerm_storage_account.main): "
    read resource
    
    terraform state rm "$resource"
    terraform destroy -target="$resource" -auto-approve
fi
```

### Dry-Run Mode

```bash
# Legg til i starten av scriptet
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo "🧪 DRY RUN MODE - No actual deletion"
fi

# I destroy_environment funksjonen:
if [ "$DRY_RUN" == "true" ]; then
    echo "DRY RUN: Would destroy $ENV environment"
    terraform plan -destroy -var-file=../environments/${ENV}.tfvars
    return
fi
```

### Cleanup Monitoring

```bash
# Legg til på slutten av scriptet
send_notification() {
    local message=$1
    
    # Slack notification
    curl -X POST $SLACK_WEBHOOK \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"$message\"}"
    
    # Email notification
    echo "$message" | mail -s "Terraform Cleanup" admin@company.com
}

# Etter vellykket cleanup
send_notification "✅ Cleanup completed for $ENV environment"
```

### Resource Group Tag Check

```bash
# Før sletting, sjekk tags for beskyttelse
check_protection_tags() {
    local rg=$1
    
    protected=$(az group show --name "$rg" \
        --query "tags.protected" -o tsv 2>/dev/null)
    
    if [ "$protected" == "true" ]; then
        echo "❌ Error: Resource group is protected by tags"
        return 1
    fi
}
```

## State Management

### Hva Skjer Med State?

Efter cleanup:

```bash
# State-filen beholdes (tom eller med minimal info)
cd workspace-dev/terraform
terraform show  # Output: "No resources found"

# State fortsatt i Azure Storage
az storage blob list \
  --account-name tfstateaccount \
  --container-name tfstate

# State inneholder historikk
terraform state list  # Tom liste
```

### Slette State Manuelt

```bash
# Hvis du vil fjerne state helt
az storage blob delete \
  --account-name tfstateaccount \
  --container-name tfstate \
  --name dev.terraform.tfstate

# ADVARSEL: Gjør dette kun hvis infrastrukturen allerede er slettet
```

## Recovery og Rollback

### Hvis du Angrer

```bash
# Hvis du avbrøt under destruksjon (Ctrl+C)
# Infrastrukturen er delvis slettet

# Alternativer:
# 1) Fullfør destruksjonen
./cleanup.sh  # Velg samme miljø igjen

# 2) Re-deploy fra artefakt
./scripts/deploy.sh dev terraform-backup.tar.gz

# 3) Manuell opprydding
az group delete --name rg-demo-dev --yes
```

### Backup før Cleanup

```bash
# Lage backup-script som kjøres FØR cleanup
backup_before_cleanup() {
    local ENV=$1
    local BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup state
    cd workspace-${ENV}/terraform
    terraform state pull > "$BACKUP_DIR/${ENV}-state.json"
    
    # Backup tfvars
    cp ../environments/${ENV}.tfvars "$BACKUP_DIR/"
    
    # Backup resource info
    az group show --name "rg-demo-${ENV}" > "$BACKUP_DIR/${ENV}-rg.json"
    
    cd ../..
    
    echo "✅ Backup saved to: $BACKUP_DIR"
}

# Kjør før cleanup
backup_before_cleanup "dev"
./cleanup.sh
```

## Oppsummering

Dette cleanup-scriptet er et **kraftig verktøy med stor påvirkning**:

### Funksjoner
✅ Interaktiv meny med 8 valg  
✅ Terraform-basert destruksjon (trygg og sporbar)  
✅ Force cleanup via Azure CLI (emergency)  
✅ Lokal filrensing uten cloud impact  
✅ Batch-sletting av alle miljøer  
✅ Brukerbekreftelse for kritiske operasjoner  

### Sikkerhetslag
🔒 Krever eksplisitt "yes" bekreftelse  
🔒 Viser destroy plan før sletting  
🔒 Individuell bekreftelse per miljø  
🔒 Advarsler for farlige operasjoner  
🔒 Validerer Azure-innlogging først  

### Når Bruke Hva

| Valg | Når | Sikkerhet |
|------|-----|-----------|
| 1-3 | Normal cleanup av enkeltmiljø | ✅ Trygt |
| 4 | Cleanup av alle miljøer | ⚠️ Forsiktig |
| 5 | Kun lokale filer | ✅ Trygt |
| 6 | Terraform feiler / emergency | 🔴 Farlig |
| 7 | Fullstendig reset | 🔴 Svært farlig |

### Viktigste Takeaways

⚠️ **ALDRI** kjør valg 4, 6, eller 7 i prod uten backup  
⚠️ **ALLTID** verifiser destroy plan før bekreftelse  
⚠️ **ALLTID** koordiner med team før cleanup  
⚠️ **ALLTID** test i dev før prod  

Med riktig bruk er dette et uvurderlig verktøy for infrastrukturhåndtering. Med feil bruk kan det slette kritisk infrastruktur på sekunder. **Bruk med respekt!** 🧹⚠️
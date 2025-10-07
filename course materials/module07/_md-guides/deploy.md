# Terraform Deploy Script - Komplett Veiledning

## Oversikt

Dette Bash-scriptet (`deploy.sh`) automatiserer deployment av Terraform-infrastruktur til Azure. Scriptet håndterer alt fra artefakt-ekstraksjon, Azure-autentisering, Terraform-initialisering til selve deploymentprosessen med plan og apply.

## Forutsetninger

### Nødvendig Programvare
- **Bash shell** (Linux/macOS/Git Bash)
- **Terraform CLI** (versjon 1.0+)
- **Azure CLI** (`az`) installert og konfigurert
- **Gyldig Azure-abonnement** med nødvendige tilganger

### Azure-Tilganger
Du må ha tilstrekkelige rettigheter til:
- Lese abonnements-ID
- Opprette og modifisere ressurser i målmiljøet
- Aksess til Terraform state storage (Azure Storage Account)

### Nødvendige Filer
- Bygd Terraform-artefakt (`.tar.gz` fil fra `build.sh`)
- Backend-konfigurasjon for miljøet (`backend-configs/backend-{env}.tfvars`)
- Miljøvariabler (`environments/{env}.tfvars`)

## Detaljert Gjennomgang

### 1. Shebang og Feilhåndtering

```bash
#!/bin/bash
set -e
```

**Forklaring:**
- `set -e` - Kritisk sikkerhetsfunksjon som stopper deploymentet ved feil
- Forhindrer delvis deployment av infrastruktur
- Sikrer at feil ikke overses i produksjonsmiljøer

### 2. Parameter-Håndtering

```bash
ENVIRONMENT=$1
ARTIFACT=$2
```

**Forklaring:**
- `$1` - Første kommandolinjeargument (miljø: dev, test, prod)
- `$2` - Andre argument (sti til artefakt-fil)

**Eksempel:**
```bash
./scripts/deploy.sh dev terraform-a3f5c2e.tar.gz
# ENVIRONMENT = "dev"
# ARTIFACT = "terraform-a3f5c2e.tar.gz"
```

### 3. Input-Validering

#### 3.1 Valider Miljø

```bash
if [ -z "$ENVIRONMENT" ]; then
  echo "❌ Error: Environment required"
  echo "Usage: ./scripts/deploy.sh <environment> <artifact>"
  exit 1
fi
```

**Forklaring:**
- `[ -z "$ENVIRONMENT" ]` - Sjekker om variabelen er tom (zero length)
- `exit 1` - Avslutter med feilkode (ikke-null = feil)
- Viser brukseksempel til brukeren

#### 3.2 Valider Artefakt-Parameter

```bash
if [ -z "$ARTIFACT" ]; then
  echo "❌ Error: Artifact required"
  exit 1
fi
```

**Samme logikk** som miljø-validering

#### 3.3 Valider Artefakt-Fil Eksisterer

```bash
if [ ! -f "$ARTIFACT" ]; then
  echo "❌ Error: Artifact not found: $ARTIFACT"
  exit 1
fi
```

**Forklaring:**
- `[ ! -f "$ARTIFACT" ]` - Sjekker at filen eksisterer og er en vanlig fil
- `!` - NOT operator (negerer testen)
- Forhindrer at scriptet fortsetter med ugyldig artefakt

### 4. Azure-Autentisering

```bash
echo "🔍 Getting Azure subscription ID..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

if [ -z "$SUBSCRIPTION_ID" ]; then
  echo "❌ Error: Could not get subscription ID. Please run 'az login' first."
  exit 1
fi

echo "✅ Using subscription: $SUBSCRIPTION_ID"
```

**Steg-for-steg:**

1. **Hent Subscription ID:**
   - `az account show` - Viser nåværende Azure-konto info
   - `--query id` - Filtrerer ut kun subscription ID
   - `-o tsv` - Output som Tab-Separated Values (rent tekstformat)
   - `$()` - Command substitution (lagrer output i variabel)

2. **Valider Login:**
   - Hvis `SUBSCRIPTION_ID` er tom, er du ikke logget inn
   - Veileder brukeren til å kjøre `az login`

3. **Eksporter til Terraform:**
   ```bash
   export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
   ```
   - Terraform bruker `ARM_SUBSCRIPTION_ID` environment variable
   - Gjør at Terraform vet hvilket Azure-abonnement som skal brukes

**Hvorfor viktig?**
- Sikrer at deployment går til riktig Azure-abonnement
- Forhindrer utilsiktet deployment til feil miljø
- Terraform kan ikke autentisere uten dette

### 5. Workspace-Oppsett

```bash
WORKSPACE="workspace-${ENVIRONMENT}"
rm -rf $WORKSPACE
mkdir -p $WORKSPACE
```

**Forklaring:**

- **Workspace-navn:** `workspace-dev`, `workspace-test`, `workspace-prod`
- `rm -rf $WORKSPACE` - Sletter gammel workspace (ren start)
  - `-r` - Recursive (inkluderer undermapper)
  - `-f` - Force (ingen bekreftelse)
- `mkdir -p $WORKSPACE` - Oppretter ny workspace
  - `-p` - Parents (lager også parent-mapper om nødvendig)

**Hvorfor?**
- Gir isolert miljø for hver deployment
- Forhindrer konflikt mellom samtidige deployments
- Sikrer ren tilstand for hver kjøring

### 6. Artefakt-Ekstraksjon

```bash
echo "1️⃣ Extracting artifact..."
tar -xzf $ARTIFACT -C $WORKSPACE
echo "✅ Artifact extracted"
```

**Forklaring:**
- `-x` - Extract (pakk ut)
- `-z` - gZip (dekomprimér)
- `-f` - File (spesifiser fil)
- `-C` - Change directory (pakk ut i spesifikk mappe)

**Resultat:**
```
workspace-dev/
├── terraform/
├── environments/
└── backend-configs/
```

### 7. Terraform Initialisering

```bash
cd $WORKSPACE/terraform

echo "2️⃣ Initializing Terraform..."
terraform init -backend-config=../backend-configs/backend-${ENVIRONMENT}.tfvars
```

**Hva skjer:**

1. **Flytter til terraform-mappen** i workspace
2. **Initialiserer Terraform** med:
   - Download av providers (AzureRM, etc.)
   - Konfigurasjon av backend (state storage)
   - Oppretting av `.terraform/` mappe

**Backend-konfigurasjon:**
```hcl
# backend-dev.tfvars eksempel
resource_group_name  = "terraform-state-rg"
storage_account_name = "tfstatedevaccount"
container_name       = "tfstate"
key                  = "dev.terraform.tfstate"
```

**Hvorfor backend?**
- Lagrer Terraform state i Azure Storage
- Muliggjør teamsamarbeid (delt state)
- Gir state locking (forhindrer samtidig endring)
- Backup og versjonering av state

### 8. Terraform Plan

```bash
echo "3️⃣ Planning deployment..."
terraform plan -var-file=../environments/${ENVIRONMENT}.tfvars -out=tfplan
```

**Forklaring:**

- `terraform plan` - Lager eksekveringsplan
- `-var-file=` - Laster miljøspesifikke variabler
- `-out=tfplan` - Lagrer planen til fil

**Hva planen viser:**
- ➕ Ressurser som skal opprettes (grønne)
- 🔄 Ressurser som skal endres (gule)
- ➖ Ressurser som skal slettes (røde)
- 📊 Totalt antall endringer

**Eksempel output:**
```
Plan: 5 to add, 2 to change, 0 to destroy.
```

**Hvorfor lagre planen?**
- Sikrer at `apply` kjører nøyaktig det som ble planlagt
- Forhindrer race conditions (endringer mellom plan og apply)
- Gjør deployment deterministisk

### 9. Terraform Apply

```bash
echo "4️⃣ Applying changes..."
terraform apply -auto-approve tfplan
```

**Forklaring:**

- `terraform apply` - Utfører endringene
- `-auto-approve` - Hopper over bekreftelsessteget
- `tfplan` - Bruker lagret plan (ikke ny beregning)

**Hva skjer:**
1. Terraform leser den lagrede planen
2. Utfører API-kall til Azure
3. Oppretter/endrer/sletter ressurser
4. Oppdaterer state-filen
5. Låser state under prosessen

**⚠️ ADVARSEL om -auto-approve:**
- Kjører deployment uten manuell godkjenning
- Passende for CI/CD pipelines
- **IKKE anbefalt** for manuelle kjøringer i produksjon
- Vurder å fjerne for prod-miljøer

### 10. Output og Opprydding

```bash
echo "✅ Deployment complete!"
echo ""
echo "📤 Outputs:"
terraform output

cd ../..
```

**Forklaring:**

- `terraform output` - Viser definerte outputs fra deploymentet
  - Eksempel: IP-adresser, DNS-navn, resource IDs
- `cd ../..` - Går tilbake til prosjektets rotmappe
  - Fra `workspace-dev/terraform/` til prosjektrot

**Eksempel outputs:**
```
resource_group_name = "myapp-dev-rg"
app_service_url = "https://myapp-dev.azurewebsites.net"
storage_account_id = "/subscriptions/.../myapp-dev-storage"
```

## Bruk av Scriptet

### Grunnleggende Kjøring

```bash
# Gjør scriptet kjørbart (første gang)
chmod +x scripts/deploy.sh

# Deploy til dev
./scripts/deploy.sh dev terraform-a3f5c2e.tar.gz

# Deploy til test
./scripts/deploy.sh test terraform-a3f5c2e.tar.gz

# Deploy til prod
./scripts/deploy.sh prod terraform-a3f5c2e.tar.gz
```

### Komplett Workflow

```bash
# 1. Logg inn på Azure
az login

# 2. Velg riktig subscription
az account set --subscription "My Subscription"

# 3. Bygg artefakt
./build.sh

# 4. Deploy til dev
./scripts/deploy.sh dev terraform-a3f5c2e.tar.gz
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
```

## Filstruktur Krav

```
project-root/
├── scripts/
│   └── deploy.sh                      # Dette scriptet
├── terraform-a3f5c2e.tar.gz          # Bygd artefakt
├── backend-configs/
│   ├── backend-dev.tfvars            # Backend config for dev
│   ├── backend-test.tfvars           # Backend config for test
│   └── backend-prod.tfvars           # Backend config for prod
└── environments/
    ├── dev.tfvars                     # Variabler for dev
    ├── test.tfvars                    # Variabler for test
    └── prod.tfvars                    # Variabler for prod
```

### Eksempel: backend-dev.tfvars

```hcl
resource_group_name  = "terraform-state-rg"
storage_account_name = "tfstatedevsa"
container_name       = "tfstate"
key                  = "dev.terraform.tfstate"
```

### Eksempel: dev.tfvars

```hcl
environment         = "dev"
location            = "norwayeast"
resource_group_name = "myapp-dev-rg"
app_service_sku     = "B1"
enable_monitoring   = false
```

## Feilsøking

### Problem: "Environment required"
**Årsak:** Ingen miljø-parameter oppgitt

**Løsning:**
```bash
./scripts/deploy.sh dev terraform-a3f5c2e.tar.gz
```

### Problem: "Artifact not found"
**Årsak:** Feil sti eller artefakt ikke bygd

**Løsning:**
```bash
# Sjekk at filen eksisterer
ls -lh terraform-*.tar.gz

# Bygg ny artefakt
./build.sh

# Deploy med korrekt sti
./scripts/deploy.sh dev terraform-a3f5c2e.tar.gz
```

### Problem: "Could not get subscription ID"
**Årsak:** Ikke logget inn på Azure

**Løsning:**
```bash
# Logg inn
az login

# Verifiser innlogging
az account show

# Prøv igjen
./scripts/deploy.sh dev terraform-a3f5c2e.tar.gz
```

### Problem: "Error loading backend config"
**Årsak:** Manglende eller ugyldig backend-konfigurasjon

**Løsning:**
```bash
# Sjekk at filen eksisterer
ls backend-configs/backend-dev.tfvars

# Valider innhold
cat backend-configs/backend-dev.tfvars

# Sjekk at storage account eksisterer i Azure
az storage account show --name tfstatedevsa --resource-group terraform-state-rg
```

### Problem: "Error acquiring state lock"
**Årsak:** En annen person/prosess holder state-låsen

**Løsning:**
```bash
# Vent til annen deployment er ferdig, ELLER

# Sjekk hvem som holder låsen
az storage blob list \
  --account-name tfstatedevsa \
  --container-name tfstate \
  --query "[?name=='dev.terraform.tfstate'].{Name:name,LastModified:properties.lastModified}"

# Hvis låsen henger (gammel deployment feilet), force-unlock
terraform force-unlock <LOCK_ID>
```

### Problem: "Insufficient permissions"
**Årsak:** Mangler Azure-rettigheter

**Løsning:**
```bash
# Sjekk dine roller
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)

# Du trenger minimum "Contributor" rolle på subscription eller resource group
```

## Sikkerhet og Best Practices

### 🔒 Sikkerhetstips

#### 1. Secrets Management
```bash
# ALDRI hardkod secrets i .tfvars filer
# Bruk Azure Key Vault eller environment variables

# Eksempel: Les secret fra Key Vault
az keyvault secret show \
  --vault-name mykeyvault \
  --name db-password \
  --query value -o tsv
```

#### 2. State Protection
```bash
# Aktiver soft delete på storage account
az storage account blob-service-properties update \
  --account-name tfstatedevsa \
  --enable-delete-retention true \
  --delete-retention-days 30
```

#### 3. Least Privilege
- Bruk dedikerte service principals for CI/CD
- Ikke bruk personlige kontoer i automatiserte pipelines
- Implementer MFA for produksjon

### ✅ Best Practices

#### 1. Gjennomgå Plan Før Apply
For produksjon, fjern `-auto-approve`:

```bash
# Modifiser scriptet for prod
if [ "$ENVIRONMENT" == "prod" ]; then
  terraform apply tfplan  # Krever manuell godkjenning
else
  terraform apply -auto-approve tfplan
fi
```

#### 2. Logging og Audit
```bash
# Lagre deployment-logger
./scripts/deploy.sh prod terraform-a3f5c2e.tar.gz 2>&1 | tee deployment-$(date +%Y%m%d-%H%M%S).log
```

#### 3. Rollback-Strategi
```bash
# Behold gamle artefakter
mv terraform-*.tar.gz archive/

# For rollback: deploy gammel artefakt
./scripts/deploy.sh prod archive/terraform-old-version.tar.gz
```

#### 4. Dry-Run Modus
Legg til en dry-run funksjon:

```bash
# Tillegg til scriptet
if [ "$3" == "--dry-run" ]; then
  echo "🧪 DRY RUN MODE - No changes will be applied"
  # Kjør kun plan, ikke apply
  terraform plan -var-file=../environments/${ENVIRONMENT}.tfvars
  exit 0
fi
```

## CI/CD Integrering

### GitHub Actions

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build Artifact
        run: ./build.sh
      
      - name: Deploy to Dev
        run: ./scripts/deploy.sh dev terraform-*.tar.gz
```

### Azure DevOps

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: 'My-Azure-Subscription'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      ./build.sh
      ./scripts/deploy.sh dev terraform-*.tar.gz
```

## Avanserte Scenarioer

### Multi-Region Deployment

```bash
# Utvid scriptet til å støtte regioner
REGION=$3

if [ ! -z "$REGION" ]; then
  terraform plan \
    -var-file=../environments/${ENVIRONMENT}.tfvars \
    -var="location=${REGION}" \
    -out=tfplan
fi
```

### Parallel Deployments

```bash
# Deploy til flere miljøer samtidig
./scripts/deploy.sh dev terraform-a3f5c2e.tar.gz &
./scripts/deploy.sh test terraform-a3f5c2e.tar.gz &
wait  # Vent på begge
```

### Blue-Green Deployment

```bash
# Deploy ny versjon ved siden av gammel
SLOT=$3  # "blue" eller "green"

terraform workspace new ${ENVIRONMENT}-${SLOT} || terraform workspace select ${ENVIRONMENT}-${SLOT}
terraform apply -auto-approve tfplan
```

## Monitorering

### Slack Notifikasjoner

```bash
# Legg til på slutten av scriptet
if [ $? -eq 0 ]; then
  curl -X POST $SLACK_WEBHOOK \
    -H 'Content-Type: application/json' \
    -d "{\"text\":\"✅ Deployment to $ENVIRONMENT succeeded\"}"
else
  curl -X POST $SLACK_WEBHOOK \
    -H 'Content-Type: application/json' \
    -d "{\"text\":\"❌ Deployment to $ENVIRONMENT failed\"}"
fi
```

## Oppsummering

Dette deployment-scriptet er et kraftig verktøy som:

✅ **Automatiserer** hele deployment-prosessen  
✅ **Validerer** input og miljø før deployment  
✅ **Sikrer** at riktig Azure-abonnement brukes  
✅ **Isolerer** hver deployment i egen workspace  
✅ **Bruker** lagret plan for deterministiske deployments  
✅ **Viser** klare outputs og deployment-status  

### Viktige Sikkerhetsprinsipper

⚠️ Alltid gjennomgå plan før apply til produksjon  
⚠️ Bruk dedikerte service principals for automation  
⚠️ Lagre aldri secrets i versjonskontroll  
⚠️ Implementer state locking og backup  
⚠️ Test deployments i dev før prod  

### Neste Steg

1. **Test scriptet** i dev-miljø først
2. **Verifiser** backend-konfigurasjon og tilganger
3. **Implementer** logging og monitorering
4. **Integrer** i CI/CD pipeline
5. **Lag** rollback-prosedyrer

Med dette scriptet har du et solid fundament for infrastruktur-deployment til Azure! 🚀
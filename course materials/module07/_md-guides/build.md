# Terraform Build Script - Veiledning

## Oversikt

Dette Bash-scriptet (`build.sh`) automatiserer prosessen med å bygge og pakke Terraform-konfigurasjon til en deploybar artefakt. Scriptet validerer Terraform-koden, genererer en versjon, og pakker alt sammen i en komprimert tar-fil som kan distribueres til ulike miljøer.

## Forutsetninger

Før du kjører scriptet, sørg for at du har:

- **Bash shell** (standard på Linux/macOS, Git Bash på Windows)
- **Terraform CLI** installert og tilgjengelig i PATH
- **Git** (valgfritt, men anbefalt for versjonering)
- **Skrivetilgang** til katalogen scriptet kjører i

## Detaljert Gjennomgang

### 1. Shebang og Feilhåndtering

```bash
#!/bin/bash
set -e
```

**Forklaring:**
- `#!/bin/bash` - Shebang som forteller systemet at dette er et Bash-script
- `set -e` - Kritisk sikkerhetsfunksjon som stopper scriptet umiddelbart hvis en kommando feiler
  - Uten dette ville scriptet fortsette selv om valideringen feilet
  - Sikrer at du aldri bygger en artefakt med ugyldig kode

### 2. Versjonsgenerering

```bash
if git rev-parse --git-dir > /dev/null 2>&1; then
  VERSION=$(git rev-parse --short HEAD)
else
  VERSION=$(date +%Y%m%d-%H%M%S)
fi
```

**Forklaring:**
- Scriptet prøver først å bruke Git for versjonering
- `git rev-parse --git-dir` - Sjekker om vi er i et Git-repository
- `> /dev/null 2>&1` - Skjuler output (både stdout og stderr)
- `git rev-parse --short HEAD` - Henter en kort versjon av siste commit-hash (f.eks. `a3f5c2e`)
- **Fallback:** Hvis Git ikke er tilgjengelig, brukes timestamp (f.eks. `20250107-143022`)

**Hvorfor to metoder?**
- Git-hash er deterministisk og sporbar til kildekode
- Timestamp fungerer i miljøer uten Git (CI/CD systemer, produksjon)

### 3. Terraform Validering

```bash
echo "1️⃣ Validating Terraform..."
cd terraform
terraform fmt -recursive || (echo "⚠️  Run 'terraform fmt -recursive' to fix formatting" && exit 1)
terraform init -backend=false
terraform validate
cd ..
```

**Steg-for-steg:**

#### 3.1 Formatsjekk
```bash
terraform fmt -recursive
```
- Sjekker at all Terraform-kode følger standard formatering
- `-recursive` - Sjekker alle undermapper
- Feiler hvis koden ikke er riktig formatert
- **Løsning:** Kjør kommandoen manuelt for å fikse formateringen

#### 3.2 Initialisering
```bash
terraform init -backend=false
```
- Initialiserer Terraform-arbeidsmiljøet
- Laster ned nødvendige providers (AWS, Azure, etc.)
- `-backend=false` - Hopper over backend-konfigurasjon
  - Vi trenger ikke remote state for validering
  - Gjør scriptet raskere og mer portabelt

#### 3.3 Validering
```bash
terraform validate
```
- Sjekker syntaks og logisk konsistens
- Verifiserer:
  - Gyldige ressursdefinisjoner
  - Korrekte variabelreferanser
  - Riktig bruk av outputs
  - Modul-avhengigheter

### 4. Artefakt-Oppretting

```bash
ARTIFACT_NAME="terraform-${VERSION}.tar.gz"

tar -czf $ARTIFACT_NAME \
  terraform/ \
  environments/ \
  backend-configs/
```

**Forklaring:**

- **Filnavn:** `terraform-a3f5c2e.tar.gz` eller `terraform-20250107-143022.tar.gz`
- **tar-kommando:**
  - `-c` - Create (opprett ny arkivfil)
  - `-z` - gZip (komprimer med gzip)
  - `-f` - File (spesifiser filnavn)

**Inkluderte mapper:**
1. `terraform/` - Hovedkoden (resources, modules, etc.)
2. `environments/` - Miljøspesifikke variabler (dev, test, prod)
3. `backend-configs/` - Backend-konfigurasjon for state-lagring

### 5. Informasjon og Neste Steg

```bash
ls -lh $ARTIFACT_NAME
```
- Viser filstørrelse i lesbart format (MB/KB)
- Hjelper deg å verifisere at artefakten ble opprettet

## Mappestruktur

Scriptet forventer følgende struktur:

```
project-root/
├── build.sh                    # Dette scriptet
├── terraform/                  # Terraform hovedkode
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── environments/               # Miljøvariabler
│   ├── dev.tfvars
│   ├── test.tfvars
│   └── prod.tfvars
└── backend-configs/           # Backend-konfigurasjon
    ├── dev.hcl
    ├── test.hcl
    └── prod.hcl
```

## Bruk av Scriptet

### Grunnleggende Kjøring

```bash
# Gjør scriptet kjørbart (første gang)
chmod +x build.sh

# Kjør scriptet
./build.sh
```

### Forventet Output

```
📦 Building Terraform Artifact...

Version: a3f5c2e

1️⃣ Validating Terraform...
Success! The configuration is valid.

✅ Validation complete!

2️⃣ Creating artifact...
✅ Artifact created: terraform-a3f5c2e.tar.gz

📊 Artifact Information:
-rw-r--r-- 1 user user 45K Oct 7 14:30 terraform-a3f5c2e.tar.gz

🎯 Next steps:
  - Deploy to dev:  ./scripts/deploy.sh dev terraform-a3f5c2e.tar.gz
  - Deploy to test: ./scripts/deploy.sh test terraform-a3f5c2e.tar.gz
```

## Feilsøking

### Problem: "terraform: command not found"
**Løsning:** Installer Terraform CLI eller legg til i PATH

### Problem: "terraform fmt failed"
**Løsning:** 
```bash
cd terraform
terraform fmt -recursive
cd ..
./build.sh
```

### Problem: "No such file or directory: terraform/"
**Løsning:** Kjør scriptet fra riktig mappe (prosjektets rot)

### Problem: Validering feiler
**Løsning:** Sjekk Terraform-koden for syntaksfeil:
```bash
cd terraform
terraform validate
```

## Best Practices

### 1. Versjonskontroll
Alltid commit endringer før bygging:
```bash
git add .
git commit -m "feat: update infrastructure"
./build.sh
```

### 2. CI/CD Integrering
Bruk scriptet i pipeline:
```yaml
# GitHub Actions eksempel
- name: Build Terraform Artifact
  run: |
    chmod +x build.sh
    ./build.sh
```

### 3. Artefakt-Lagring
Lagre bygde artefakter i et repository:
```bash
# Eksempel med AWS S3
aws s3 cp terraform-*.tar.gz s3://artifacts-bucket/terraform/
```

## Utvidelsesmuligheter

### Legg til Checksums
```bash
# Etter tar-kommandoen
sha256sum $ARTIFACT_NAME > ${ARTIFACT_NAME}.sha256
echo "✅ Checksum: $(cat ${ARTIFACT_NAME}.sha256)"
```

### Legg til Linting
```bash
# Før validering
echo "🔍 Running tflint..."
tflint --recursive
```

### Legg til Security Scanning
```bash
# Etter validering
echo "🔒 Security scanning..."
tfsec terraform/
```

## Sikkerhet

### Hva Scriptet IKKE gjør
- ❌ Lagrer ikke secrets i artefakten
- ❌ Committer ikke automatisk til Git
- ❌ Deployer ikke til skymiljøer
- ❌ Endrer ikke eksisterende infrastruktur

### Hva du må passe på
- ✅ Ikke inkluder `.tfvars`-filer med secrets
- ✅ Bruk environment variables eller secret managers
- ✅ Sjekk at `.gitignore` ekskluderer sensitive filer

## Oppsummering

Dette scriptet er et robust verktøy for å bygge Terraform-artefakter med:
- ✅ Automatisk versjonering
- ✅ Kodevalidering
- ✅ Formatsjekk
- ✅ Reproduserbare bygger
- ✅ Enkel deployment-pipeline

Ved å bruke dette scriptet sikrer du at kun validert og korrekt formatert Terraform-kode pakkes og distribueres til dine miljøer.
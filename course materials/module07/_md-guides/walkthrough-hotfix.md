# Infrastructure as Code - Komplett Workflow Guide

> En steg-for-steg guide til god IaC praksis med Terraform og GitHub Actions

---

## 📋 Del 1: Normal Deployment Workflow

Denne delen dekker den komplette prosessen fra utvikling til produksjon.

---

### ✅ Steg 1: Sjekk main og pull

**Formål:** Sørg for at du har siste versjon av koden før du starter.

```bash
# Bytt til main branch
git checkout main

# Hent siste endringer fra GitHub
git pull origin main

# Verifiser at du er oppdatert
git status
```

**Forventet output:**
```
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```

---

### ✅ Steg 2: Opprett feature branch

**Formål:** Isoler dine endringer fra main branch (trunk-based development).

```bash
# Opprett og bytt til ny feature branch
# Bruk beskrivende navn som forklarer hva du gjør
git checkout -b feature/add-monitoring

# Alternative eksempler:
# git checkout -b feature/upgrade-storage-tier
# git checkout -b feature/add-cost-tags
# git checkout -b hotfix/fix-network-config
```

**Verifiser at du er på riktig branch:**
```bash
git branch
# Output viser: * feature/add-monitoring
```

---

### ✅ Steg 3: Utvikle og test lokalt

**Formål:** Gjør endringer i koden og test lokalt før du committer.

#### 3.1: Gjør endringer i Terraform-kode

```bash
# Åpne filer i din editor (VS Code, vim, etc.)
code terraform/main.tf
```

**Eksempel endring i `main.tf`:**
```hcl
# Før:
resource "azurerm_storage_account" "main" {
  name                     = "stdemoprod7x3k2a"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Etter (lagt til tags):
resource "azurerm_storage_account" "main" {
  name                     = "stdemoprod7x3k2a"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    CostCenter  = "IT-Infrastructure"
  }
}
```

#### 3.2: Valider Terraform-syntaks

```bash
# Naviger til terraform-mappen
cd terraform

# Initialiser Terraform (Hvis ikke gjort før. OG - Hva er det som mangler i lokalt oppsett om en ikke får kjørt igjennom uten subscription? Tips: Environmental variables (søk opp environmental variables for terraform og bash / powershell i Terraform docks)
terraform init # (MÅ VÆRE MED BACKEND CONFIG og key for state file, for at plan skal gi god info, hvis ikke vil alt alltid være en nyopprettelse)

# Valider syntaks
terraform fmt -check
terraform validate # Vil feile uten terraform init først.
```

**Forventet output:**
```
Success! The configuration is valid.
```

#### 3.3: Se hva som vil endres (plan)

```bash
# Kjør terraform plan for dev-miljøet
terraform plan -var-file="environments/dev.tfvars"

# Les output nøye:
# + = Nye ressurser
# ~ = Endringer i eksisterende ressurser
# - = Ressurser som slettes
```

**Eksempel output:**
```
Terraform will perform the following actions:

  # azurerm_storage_account.main will be updated in-place
  ~ resource "azurerm_storage_account" "main" {
      ~ tags = {
          + "CostCenter"  = "IT-Infrastructure"
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

#### 3.4: Test i dev-miljø (valgfritt lokalt)

```bash
# Kun hvis du har tilgang og vil teste før push
terraform apply -var-file="environments/dev.tfvars"

# Hvis du testet lokalt, husk å rydde opp eller la CD ta over
```

---

### ✅ Steg 4: Commit og push

**Formål:** Lagre endringene dine og push til GitHub for code review.

#### 4.1: Sjekk status

```bash
# Se hvilke filer som er endret
git status

# Se detaljerte endringer
git diff
```

#### 4.2: Legg til endringer

```bash
# Legg til alle endrede filer
git add .

# Eller legg til spesifikke filer
git add terraform/main.tf
git add terraform/variables.tf
```

#### 4.3: Commit med god commit-melding

```bash
# Skriv beskrivende commit message
git commit -m "Add cost tracking tags to storage account

- Added Environment tag
- Added ManagedBy tag
- Added CostCenter tag

This helps with cost allocation and resource management."
```

**Tips for gode commit messages:**
- Første linje: Kort oppsummering (50 tegn eller mindre)
- Tom linje
- Detaljert beskrivelse av hva og hvorfor
- Bruk presens: "Add" ikke "Added"

#### 4.4: Push til GitHub

```bash
# Push feature branch til GitHub
git push origin feature/add-monitoring

# Første gang du pusher en ny branch:
git push --set-upstream origin feature/add-monitoring
```

**Forventet output:**
```
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 326 bytes | 326.00 KiB/s, done.
Total 3 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To github.com:your-username/your-repo.git
 * [new branch]      feature/add-monitoring -> feature/add-monitoring
```

---

### ✅ Steg 5: Opprett Pull Request

**Formål:** Start code review-prosessen og la CI validere koden.

#### 5.1: Gå til GitHub

```
https://github.com/YOUR-USERNAME/YOUR-REPO/pulls
```

#### 5.2: Opprett Pull Request

1. Klikk "Compare & pull request" (vises automatisk etter push)
2. Eller klikk "New pull request"
3. Velg:
   - Base: `main`
   - Compare: `feature/add-monitoring`

#### 5.3: Fyll ut PR-beskrivelse

**Tittel:**
```
Add cost tracking tags to storage account
```

**Beskrivelse:**
```markdown
## Changes
- Added Environment, ManagedBy, and CostCenter tags to storage account
- This enables better cost tracking and resource management

## Testing
- [x] Terraform validate passed
- [x] Terraform plan reviewed
- [ ] Awaiting CI validation

## Deployment Plan
1. Deploy to dev (automatic via CI)
2. Manual testing in dev
3. Deploy to test
4. Deploy to prod (with approval)

## Related Issues
Fixes #123
```

#### 5.4: Opprett PR

Klikk "Create pull request"

---

### ✅ Steg 6: CI kjører automatisk (validering kun)

**Formål:** Automatisk validering av koden uten å deploye til prod.

#### Hva skjer automatisk når du oppretter PR:

```yaml
# .github/workflows/terraform-ci.yml kjører:

1. Checkout code
2. Setup Terraform
3. terraform fmt -check
4. terraform validate
5. terraform plan (for alle miljøer)
```

#### Følg med i GitHub Actions:

1. Gå til "Actions" tab i GitHub
2. Se workflowen kjøre
3. Sjekk at alle steg er grønne ✅

**Eksempel output fra CI:**

```
✅ Terraform Format and Style
✅ Terraform Initialization
✅ Terraform Validation
✅ Terraform Plan - Dev
✅ Terraform Plan - Test
✅ Terraform Plan - Prod

The plan shows 0 to add, 3 to change, 0 to destroy.
```

#### Hvis CI feiler:

```bash
# Fikse lokalt
git checkout feature/add-monitoring
# ... gjør endringer
git add .
git commit -m "Fix terraform formatting"
git push origin feature/add-monitoring

# CI kjører automatisk på nytt
```

---

### ✅ Steg 7: Code review og godkjenning

**Formål:** Få koden gjennomgått av teammedlemmer før merge.

#### For reviewer:

1. Gå til Pull Request
2. Klikk "Files changed"
3. Gjennomgå endringene:
   - Er koden lesbar?
   - Følger den best practices?
   - Er det sikkerhetsproblemer?
   - Er terraform plan output fornuftig?

#### Legg til kommentarer:

```markdown
**Kommentar på linje 45:**
> Bør vi også legge til en "Owner" tag her?

**Generell kommentar:**
> Ser bra ut! Men kan du bekrefte at disse tags er i tråd med 
> organisasjonens tagging policy?
```

#### Godkjenn PR:

1. Klikk "Review changes"
2. Velg "Approve"
3. Skriv kommentar: "LGTM! (Looks Good To Me)"
4. Klikk "Submit review"

---

### ✅ Steg 8: Merge til main

**Formål:** Inkludere endringene i main branch (trunk).

#### Forutsetninger før merge:

- ✅ CI må være grønn
- ✅ Minst én godkjenning (avhenger av branch protection rules)
- ✅ Ingen merge conflicts

#### Merge Pull Request:

```bash
# I GitHub UI:
1. Klikk "Squash and merge" (anbefalt)
   - Eller "Merge pull request" for å beholde alle commits
2. Bekreft merge message
3. Klikk "Confirm squash and merge"
4. Klikk "Delete branch" (rydder opp feature branch)
```

**Hva skjer nå:**
- Feature branch merges til main
- Feature branch slettes på GitHub
- CD workflow trigges automatisk!

---

### ✅ Steg 9: CD kjører automatisk (10-30 min)

**Formål:** Automatisk deployment til alle miljøer etter vellykket merge.

#### CD Workflow kjører automatisk:

```yaml
# .github/workflows/terraform-cd.yml
# Trigger: push to main branch

Workflow:
1. Deploy to Dev
   ├── Terraform plan
   ├── Terraform apply
   └── Verify deployment (2-5 min)

2. Deploy to Test  
   ├── Terraform plan
   ├── Terraform apply
   └── Verify deployment (2-5 min)

3. Deploy to Prod (requires manual approval!)
   ├── Wait for approval...
   ├── Terraform plan
   ├── Terraform apply
   └── Verify deployment (2-5 min)
```

#### Følg med i Actions:

```
1. Gå til GitHub → Actions tab
2. Se "Terraform CD" workflow kjøre
3. Observer progressen:

   ✅ Deploy Dev (3 min)
   ✅ Deploy Test (3 min)
   ⏸️  Deploy Prod (Awaiting approval)
```

**⚠️ VIKTIG:** IKKE gå videre til neste steg før CD er fullført!

---

### ✅ Steg 10: Vent til CD er fullført

**Formål:** Sørg for at dev og test deployments er vellykkede før prod.

#### Overvåk deployment:

```bash
# I GitHub Actions, se at:
✅ Dev deployment: Completed successfully (3 min)
✅ Test deployment: Completed successfully (3 min)
⏸️  Prod deployment: Awaiting approval
```

#### Verifiser i Azure Portal (anbefalt):

**Dev miljø:**
```
Azure Portal → Resource Groups → rg-demo-dev
├── Storage Account: stdemodeva1b2c3
│   ├── Status: Available ✅
│   ├── Tags: ✅
│   │   ├── Environment: dev
│   │   ├── ManagedBy: Terraform
│   │   └── CostCenter: IT-Infrastructure
│   └── Last Modified: 2 minutes ago
```

**Test miljø:**
```
Azure Portal → Resource Groups → rg-demo-test
├── Storage Account: stdemotestd4e5f6
│   ├── Status: Available ✅
│   ├── Tags: ✅
│   │   ├── Environment: test
│   │   ├── ManagedBy: Terraform
│   │   └── CostCenter: IT-Infrastructure
│   └── Last Modified: 5 minutes ago
```

#### Hvis noe feiler:

```
❌ Deploy Test: Failed!

1. IKKE godkjenn prod!
2. Les error message i Actions
3. Fikse problemet
4. Opprett ny PR med fix
5. Merge → CD starter på nytt
```

---

### ✅ Steg 11: Godkjenn prod

**Formål:** Manuell godkjenning før produksjonsdeployment.

#### Godkjenn i GitHub Actions:

```
1. Gå til Actions tab
2. Klikk på "Terraform CD" workflow som kjører
3. Se "Review deployments" box:
   
   📋 Waiting for review
   └── Prod environment is waiting for approval
   
4. Klikk "Review deployments"
5. Velg ✅ "prod"
6. Skriv kommentar (valgfritt):
   "Dev and test verified OK. Approving prod deployment."
7. Klikk "Approve and deploy"
```

#### CD fortsetter automatisk:

```
✅ Dev deployment: Completed
✅ Test deployment: Completed  
🚀 Prod deployment: Running... (3-5 min)
```

#### Vent til prod er ferdig:

```
✅ Prod deployment: Completed successfully
```

---

### ✅ Steg 12: Verifiser alle miljøer i Azure

**Formål:** Manuell verifikasjon at alt fungerer som forventet i produksjon.

#### Verifiser i Azure Portal:

**Prod miljø:**
```
Azure Portal → Resource Groups → rg-demo-prod
├── Storage Account: stdemoproda7b8c9
│   ├── Status: Available ✅
│   ├── Tags: ✅ (verifiser at nye tags er der)
│   ├── Performance: Normal ✅
│   └── Last Modified: Just now
```

#### Test funksjonalitet (om relevant):

```bash
# Test connectivity
az storage account show \
  --name stdemoproda7b8c9 \
  --resource-group rg-demo-prod

# Verifiser tags
az storage account show \
  --name stdemoproda7b8c9 \
  --resource-group rg-demo-prod \
  --query tags

# Output:
{
  "CostCenter": "IT-Infrastructure",
  "Environment": "prod",
  "ManagedBy": "Terraform"
}
```

#### Sjekkliste for verifikasjon:

- ✅ Alle miljøer deployet (dev, test, prod)
- ✅ Ressurser eksisterer i Azure
- ✅ Tags er korrekte
- ✅ Ingen feilmeldinger i Azure
- ✅ Funksjonalitet virker som forventet

---

### ✅ Steg 13: Git tag (lokalt)

**Formål:** Markere denne versjonen som en stabil release.

#### Bestem versjonsnummer:

Bruk [Semantic Versioning](https://semver.org/):
```
v<MAJOR>.<MINOR>.<PATCH>

v1.2.3
 │ │ │
 │ │ └─ PATCH: Bugfixes, små endringer
 │ └─── MINOR: Ny funksjonalitet (backward compatible)
 └───── MAJOR: Breaking changes
```

**Eksempler:**
- `v1.0.0` - Første produksjonsrelease
- `v1.1.0` - La til nye tags (minor update)
- `v1.1.1` - Fikset tagging bug (patch)
- `v2.0.0` - Endret storage tier (breaking change)

#### Opprett tag lokalt:

```bash
# Sørg for at du er på main og oppdatert
git checkout main
git pull origin main

# Opprett annotated tag med beskrivende melding
git tag -a v1.1.0 -m "Release v1.1.0 - Add cost tracking tags

Features:
- Added Environment tag for all resources
- Added ManagedBy tag (Terraform)
- Added CostCenter tag for cost allocation

Deployment Status:
✅ Dev: Deployed and verified
✅ Test: Deployed and verified  
✅ Prod: Deployed and verified

Date: $(date '+%Y-%m-%d %H:%M:%S')"

# Verifiser at tag ble opprettet
git tag -l "v1.*"
```

**Forventet output:**
```
v1.0.0
v1.1.0
```

#### Se tag-detaljer:

```bash
# Vis tag message
git show v1.1.0

# Output:
tag v1.1.0
Tagger: Your Name <your.email@example.com>
Date:   Mon Oct 13 13:45:00 2025 +0200

Release v1.1.0 - Add cost tracking tags

Features:
- Added Environment tag for all resources
...
```

---

### ✅ Steg 14: Push tag til GitHub

**Formål:** Gjøre taggen tilgjengelig for hele teamet.

```bash
# Push den spesifikke taggen
git push origin v1.1.0

# Eller push alle tags
git push origin --tags
```

**Forventet output:**
```
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 521 bytes | 521.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:your-username/your-repo.git
 * [new tag]         v1.1.0 -> v1.1.0
```

#### Verifiser i GitHub:

```
1. Gå til GitHub repository
2. Klikk på "Tags" (ved siden av branches)
3. Se at v1.1.0 er der
```

---

### ✅ Steg 15: Opprett GitHub Release

**Formål:** Dokumentere releasen med changelog og notes.

#### Opprett Release i GitHub UI:

```
1. Gå til GitHub repository
2. Klikk "Releases" (i høyre sidebar)
3. Klikk "Draft a new release"

4. Fyll ut release form:

   Choose a tag: [v1.1.0 ▼]
   
   Release title: v1.1.0 - Cost Tracking Tags
   
   Describe this release:
   ┌─────────────────────────────────────────┐
   │ ## 🎯 What's New                        │
   │                                          │
   │ ### Features                             │
   │ - ✨ Added cost tracking tags to all    │
   │   storage accounts                       │
   │ - 📊 Environment-specific tagging        │
   │ - 🏷️ CostCenter tag for billing         │
   │                                          │
   │ ### Deployment                           │
   │ - ✅ Dev: Verified                       │
   │ - ✅ Test: Verified                      │
   │ - ✅ Prod: Verified                      │
   │                                          │
   │ ### Changed Files                        │
   │ - `terraform/main.tf`                    │
   │ - `terraform/variables.tf`               │
   │                                          │
   │ ### How to Rollback                      │
   │ If needed, deploy previous version:      │
   │ `v1.0.0`                                 │
   └─────────────────────────────────────────┘

5. Klikk "Publish release"
```

#### Release er nå synlig:

```
https://github.com/YOUR-USERNAME/YOUR-REPO/releases/tag/v1.1.0

Releases
└── v1.1.0 - Cost Tracking Tags
    ├── Latest ✅
    ├── Published 5 minutes ago
    ├── Assets (Source code zip, tar.gz)
    └── Used by 3 environments
```

---

## 🎉 Fullført: Normal Deployment Workflow

Du har nå fullført alle 15 stegene! Oppsummering:

1. ✅ Sjekket main og pullet siste endringer
2. ✅ Opprettet feature branch
3. ✅ Utviklet og testet lokalt
4. ✅ Committet og pushet til GitHub
5. ✅ Opprettet Pull Request
6. ✅ CI kjørte automatisk (validering)
7. ✅ Code review og godkjenning
8. ✅ Merget til main
9. ✅ CD kjørte automatisk (10-30 min)
10. ✅ Ventet til CD var fullført
11. ✅ Godkjente prod deployment
12. ✅ Verifiserte alle miljøer i Azure
13. ✅ Opprettet git tag lokalt
14. ✅ Pushet tag til GitHub
15. ✅ Opprettet GitHub Release

**Neste steg:** Lær hvordan du ruller tilbake hvis noe går galt!

---

---

## 🔄 Del 2: Rollback Workflow

Når noe går galt i produksjon, må du kunne rulle tilbake raskt og trygt.

---

## 🚨 Scenario: Noe gikk galt!

**Situasjon:**
- Du deployet `v1.1.0` som la til cost tracking tags
- Noen dager senere oppdaget du et problem:
  - Tags forårsaker konflikter med eksisterende Azure Policies
  - Ressurser blir flagget som non-compliant
  - Du må rulle tilbake til `v1.0.0`

---

## 📋 Rollback: Steg-for-steg

Det finnes **tre metoder** for å rulle tilbake. Vi går gjennom den anbefalte metoden først.

---

### 🎯 Metode 1: Feature Branch Rollback (Anbefalt)

**Hvorfor denne metoden:**
- ✅ Følger samme workflow som normal utvikling
- ✅ Får code review og CI validation
- ✅ Kan teste i dev før prod
- ✅ Clean Git history
- ✅ Trygt og forutsigbart

---

#### Rollback Steg 1: Identifiser problemet

```bash
# Se hvilken versjon som kjører i prod
# (Azure Portal eller fra previous deployment)

# List alle tags
git tag -l --sort=-creatordate

# Output:
# v1.1.0  ← Current (problematisk)
# v1.0.0  ← Forrige (stabil)

# Se hva som er forskjellen
git log v1.0.0..v1.1.0 --oneline

# Output:
# abc1234 Add cost tracking tags

# Les commit for å forstå hva som ble endret
git show abc1234
```

---

#### Rollback Steg 2: Sjekk at du er på main

```bash
# Bytt til main
git checkout main

# Hent siste endringer
git pull origin main

# Verifiser status
git status

# Output:
# On branch main
# Your branch is up to date with 'origin/main'.
```

---

#### Rollback Steg 3: Opprett rollback feature branch

```bash
# Opprett descriptive branch for rollback
git checkout -b feature/rollback-to-v1.0.0

# Verifiser at du er på ny branch
git branch

# Output:
# * feature/rollback-to-v1.0.0
#   main
```

---

#### Rollback Steg 4: Hent kode fra stabil versjon

**Dette er det magiske steget!** Du henter automatisk alle filer fra den stabile versjonen:

```bash
# Hent ALLE Terraform-filer fra v1.0.0
git checkout v1.0.0 -- terraform/

# Dette kommandoen:
# 1. Finner v1.0.0 tag
# 2. Henter alle filer i terraform/ mappen fra den taggen
# 3. Legger endringene i staging area
# 4. Du er fortsatt på feature/rollback-to-v1.0.0 branch
```

**Alternativt, hent kun spesifikke filer:**
```bash
# Kun main.tf fra v1.0.0
git checkout v1.0.0 -- terraform/main.tf

# Flere spesifikke filer
git checkout v1.0.0 -- terraform/main.tf terraform/variables.tf
```

---

#### Rollback Steg 5: Verifiser endringene

```bash
# Se hva som ble endret
git status

# Output:
# On branch feature/rollback-to-v1.0.0
# Changes to be committed:
#   modified:   terraform/main.tf

# Se detaljerte endringer
git diff --staged

# Output viser at tags fjernes:
# -  tags = {
# -    Environment = var.environment
# -    ManagedBy   = "Terraform"
# -    CostCenter  = "IT-Infrastructure"
# -  }
```

---

#### Rollback Steg 6: Commit rollback

```bash
git commit -m "Rollback to v1.0.0 configuration

Reason: Cost tracking tags conflict with Azure Policies
Impact: Resources flagged as non-compliant
Solution: Remove tags, investigate policy conflicts

Reverting:
- Removed Environment tag
- Removed ManagedBy tag  
- Removed CostCenter tag

Testing plan:
1. Deploy to dev
2. Verify policy compliance
3. Deploy to test
4. Deploy to prod

Related: Issue #145"
```

---

#### Rollback Steg 7: Push rollback branch

```bash
# Push til GitHub
git push origin feature/rollback-to-v1.0.0

# Eller med --set-upstream første gang
git push --set-upstream origin feature/rollback-to-v1.0.0
```

---

#### Rollback Steg 8: Opprett Pull Request

```
1. Gå til GitHub
2. Klikk "Compare & pull request"
3. Fyll ut PR:

Title: Rollback to v1.0.0 - Remove cost tracking tags

Description:
## 🚨 Rollback PR

### Problem
Cost tracking tags (added in v1.1.0) conflict with Azure Policies,
causing resources to be flagged as non-compliant.

### Solution
Rollback to v1.0.0 configuration by removing the tags.

### Testing
- [ ] CI validation
- [ ] Deploy to dev
- [ ] Verify policy compliance in dev
- [ ] Deploy to test
- [ ] Deploy to prod (with approval)

### Related
- Relates to #145 (Azure Policy conflict)
- Reverts v1.1.0

4. Klikk "Create pull request"
```

---

#### Rollback Steg 9: CI validerer automatisk

```
GitHub Actions kjører:
✅ Terraform Format and Style
✅ Terraform Validation
✅ Terraform Plan - Dev (shows tags will be removed)
✅ Terraform Plan - Test
✅ Terraform Plan - Prod

CI er grønn! ✅
```

---

#### Rollback Steg 10: Code review

```
Reviewer:
"Rollback looks correct. I've verified:
- Tags will be removed from all environments
- No other changes in the plan
- This matches v1.0.0 state

Approved ✅"
```

---

#### Rollback Steg 11: Merge rollback PR

```bash
# I GitHub UI:
1. Klikk "Squash and merge"
2. Confirm merge message
3. Klikk "Confirm squash and merge"
4. Klikk "Delete branch"
```

---

#### Rollback Steg 12: CD kjører automatisk

```
Terraform CD workflow starter:

✅ Deploy Dev (removes tags)
✅ Deploy Test (removes tags)
⏸️  Deploy Prod (awaiting approval)
```

---

#### Rollback Steg 13: Verifiser dev og test

```
Azure Portal:
✅ Dev: Tags removed, policy compliant
✅ Test: Tags removed, policy compliant
```

---

#### Rollback Steg 14: Godkjenn prod rollback

```
GitHub Actions → Review deployments → Approve prod

"Rollback verified in dev and test. Approving prod."

✅ Prod deployment: Running...
✅ Prod deployment: Completed
```

---

#### Rollback Steg 15: Verifiser prod

```bash
# Sjekk at tags er fjernet
az storage account show \
  --name stdemoproda7b8c9 \
  --resource-group rg-demo-prod \
  --query tags

# Output:
null  # Tags er fjernet ✅

# Verifiser policy compliance
az policy state list \
  --resource-group rg-demo-prod \
  --query "[?complianceState=='NonCompliant']"

# Output:
[]  # Ingen non-compliant ressurser ✅
```

---

#### Rollback Steg 16: Tag rollback-versjonen

```bash
# Sørg for at du er på main
git checkout main
git pull origin main

# Opprett tag for rollback-versjonen
git tag -a v1.0.1 -m "Release v1.0.1 - Rollback

Rollback to v1.0.0 configuration due to Azure Policy conflicts.

Changes:
- Removed cost tracking tags
- Restored v1.0.0 storage account configuration

Reason:
- Tags conflicted with existing Azure Policies
- Resources were flagged as non-compliant
- Reverted until policy conflicts are resolved

Deployment Status:
✅ Dev: Deployed and verified
✅ Test: Deployed and verified  
✅ Prod: Deployed and verified

Previous version: v1.1.0 (reverted)
Stable version: v1.0.0"

# Push tag
git push origin v1.0.1
```

**Hvorfor v1.0.1 og ikke v1.0.0?**
- `v1.0.0` refererer til den originale commiten
- `v1.0.1` er en ny commit som har samme konfigurasjon
- Semantic versioning: PATCH økning for bugfix/rollback

---

#### Rollback Steg 17: Opprett GitHub Release

```
GitHub → Releases → Draft new release

Tag: v1.0.1
Title: v1.0.1 - Rollback to stable configuration

Description:
## 🔄 Rollback Release

This is a rollback to the v1.0.0 configuration.

### Why?
Cost tracking tags (introduced in v1.1.0) conflicted with 
existing Azure Policies, causing compliance issues.

### What Changed?
- ❌ Removed Environment tag
- ❌ Removed ManagedBy tag
- ❌ Removed CostCenter tag
- ✅ Restored v1.0.0 storage configuration

### Status
- ✅ All environments deployed successfully
- ✅ Azure Policy compliance restored
- ✅ No production impact

### Next Steps
- Investigate Azure Policy conflicts
- Update policies or modify tagging strategy
- Re-introduce tags in future release when resolved

Klikk "Publish release"
```

---

## ✅ Rollback Fullført!

Du har nå rullet tilbake til en stabil versjon! Oppsummering:

1. ✅ Identifiserte problemet (v1.1.0 tags konflikt)
2. ✅ Opprettet rollback feature branch
3. ✅ Hentet kode fra v1.0.0 automatisk
4. ✅ Committet og pushet rollback
5. ✅ Opprettet rollback PR
6. ✅ CI validerte endringene
7. ✅ Code review og godkjenning
8. ✅ Merget rollback PR
9. ✅ CD deployet til alle miljøer
10. ✅ Verifiserte prod rollback
11. ✅ Tagget rollback-versjon (v1.0.1)
12. ✅ Opprettet GitHub Release

**Resultat:**
- Produksjon er tilbake til stabil tilstand
- Git history er clean og sporbar
- Ingen data tapt
- Problemet kan undersøkes og fikses i ro og mak

---

## 🎓 Alternative Rollback-metoder

---

### Metode 2: Revert Commit (Rask rollback)

**Bruk når:** Du trenger rask rollback og vil beholde clean Git history.

```bash
# Steg 1: Finn merge commit
git log --oneline

# Output:
# abc1234 (HEAD -> main, tag: v1.1.0) Merge pull request #42
# def5678 Add cost tracking tags
# 789abcd (tag: v1.0.0) Previous version

# Steg 2: Reverter merge commit
git revert abc1234

# Git åpner editor for commit message
# Lagre og lukk

# Steg 3: Push revert
git push origin main

# CD kjører automatisk!
# ✅ Revert deployes til alle miljøer
```

**Fordeler:**
- ✅ Rask (bare 3 kommandoer)
- ✅ Clean Git history (forward-only)
- ✅ Automatisk CD deployment

**Ulemper:**
- ⚠️ Går direkte til prod (ingen review)
- ⚠️ Krever at du er sikker på hva du gjør

---

### Metode 3: Deploy Tidligere Tag (Akutt-rollback)

**Bruk kun i akutte situasjoner!**

```bash
# Steg 1: Trigger CD manuelt med gammel tag
# GitHub Actions → Terraform CD → Run workflow

# Inputs:
# version: "v1.0.0"
# environment: "prod"  
# confirm: "deploy"

# Steg 2: CD deployer v1.0.0 til prod
✅ Prod: Rolled back to v1.0.0

# ⚠️ PROBLEM: Main branch har fortsatt v1.1.0!
# Du må nå fikse Git history med Metode 1 eller 2
```

**Fordeler:**
- ✅ Raskeste rollback (minutter)
- ✅ Direkte til prod

**Ulemper:**
- ⚠️ Main branch og prod er ikke synkronisert (drift!)
- ⚠️ MÅ følges opp med Git-endring
- ⚠️ Farlig hvis man glemmer å fikse Git

**Bruk denne kun som:**
- Akutt rollback i kritisk situasjon
- Følg umiddelbart opp med Metode 1 for å fikse Git

---

## 📊 Sammenligning av Rollback-metoder

| Aspekt | Metode 1: Feature Branch | Metode 2: Revert | Metode 3: Deploy Tag |
|--------|--------------------------|------------------|---------------------|
| **Hastighet** | 30-60 min | 10-15 min | 5 min |
| **Code Review** | ✅ Ja | ❌ Nei | ❌ Nei |
| **CI Validering** | ✅ Ja | ❌ Nei | ❌ Nei |
| **Test i dev først** | ✅ Ja | ❌ Nei | ❌ Nei |
| **Git history** | ✅ Clean | ✅ Clean | ⚠️ Drift! |
| **Best practice** | ✅ Ja | ⚠️ OK | ❌ Akutt kun |
| **Når bruke** | Normal rollback | Rask rollback | Kritisk akutt |

---

## 💡 Best Practices for Rollback

### 1. **Alltid ha tags**
```bash
# Uten tags:
git checkout abc1234  # Hva er dette? 🤷

# Med tags:
git checkout v1.0.0  # Siste stabile versjon! ✅
```

### 2. **Test rollback i dev først**
```bash
# Deploy gammel versjon til dev
# Verifiser at rollback fungerer
# Deretter til test
# Til slutt til prod
```

### 3. **Dokumenter hvorfor**
```bash
git tag -a v1.0.1 -m "Rollback

Reason: Azure Policy conflicts
Related: Issue #145"
```

### 4. **Kommuniser rollback**
```
Slack/Teams:
"🚨 Rolling back prod to v1.0.0 due to policy conflicts. 
ETA: 10 minutes. Will update when complete."
```

### 5. **Etterfølgende analyse**
```markdown
## Post-Rollback Analysis

### What happened?
- v1.1.0 tags conflicted with policies

### Why wasn't it caught earlier?
- Policy rules not tested in dev/test
- Dev/test policies differ from prod

### How to prevent?
- Sync policies across all environments
- Add policy compliance tests to CI
- Test with production-like policies
```

---

## 🎯 Oppsummering

### Normal Workflow (15 steg)
1. Feature branch → PR → Review → Merge
2. CD auto-deploys: dev → test → prod
3. Verify → Tag → Release

### Rollback Workflow (17 steg)
1. Identify problem
2. Feature branch rollback (git checkout tag -- path)
3. PR → Review → Merge
4. CD auto-deploys rollback
5. Verify → Tag rollback version → Release

**Nøkkelprinsipp:**
> Rollback følger samme workflow som normal deployment!
> Dette gir trygghet, validering og sporbarhet.

---

## 📚 Videre Læring

### Praktiske Øvelser

#### Øvelse 1: Normal Deployment
1. Legg til en ny resource (Virtual Network)
2. Følg alle 15 steg
3. Verifiser i Azure
4. Tag som v1.2.0

#### Øvelse 2: Rollback med Feature Branch
1. Gjør en feil (feil subnet range)
2. Deploy til prod
3. Oppdage problemet
4. Rollback med feature branch metode
5. Tag som v1.2.1

#### Øvelse 3: Sammenlign Metoder
1. Test alle tre rollback-metoder
2. Observer forskjeller
3. Diskuter når hver metode passer

---

## 🚀 Tips for Suksess

### 1. Automatiser der det er mulig
```yaml
# Pre-commit hooks
- terraform fmt
- terraform validate
- tflint
```

### 2. Skriv gode commit messages
```bash
# ❌ Dårlig
git commit -m "fix"

# ✅ Bra
git commit -m "Fix subnet CIDR range conflict

Changed: 10.0.0.0/16 → 10.1.0.0/16
Reason: Conflicted with existing network
Impact: Dev and test environments"
```

### 3. Hold tags konsistente
```bash
# Alltid samme format
v1.0.0
v1.1.0
v1.2.0

# Ikke bland formater!
```

### 4. Dokumenter alt
- Commit messages
- PR descriptions
- Tag messages
- GitHub Releases
- README

### 5. Øv på rollback
```bash
# Test rollback regelmessig
# Det skal ikke være første gang i prod!
```

---

## 🎓 Lykke til!

Du har nå en komplett guide til Infrastructure as Code best practices!

**Husk:**
- 🔄 Følg workflowen konsistent
- 🏷️ Tag alle stabile versjoner
- 📝 Dokumenter alt
- ✅ Test før prod
- 🚨 Øv på rollback


---

*God praksis gir trygg drift!* 🎯
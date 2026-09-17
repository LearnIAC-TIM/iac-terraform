# Demo: fra laptop til leveranseflyt

Kjøreplan for en live-demo i VS Code som følger figur 01–07 i
`modules/05-delivery-workflows/img/`. Terraform-koden er bevisst triviell — én
resource group. Poenget er *hvem* som kjører, *hvor* state ligger og *hvor*
verdiene kommer fra.

```
demo/
├── .github/workflows/deploy-dev.yml   # figur 03 og 05
├── .gitignore                         # *.tfvars og state holdes ute
├── backend.hcl                        # ikke hemmelig, committes
├── backend/                           # bootstrap: storage account + Key Vault + RBAC
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tfvars.eksempel
└── infra/                             # stacken som rulles ut
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── dev.tfvars.eksempel
```

> Mappa ligger under `docs/` bare for å bo et sted. Workflowen virker kun når
> `demo/` er **rota** i et eget repo — GitHub leser bare
> `.github/workflows/` på toppnivå. Kopier innholdet til et nytt repo i
> GitHub-organisasjonen din før demoen.

---

## Før forelesningen (ikke live)

RBAC-tildelinger bruker noen minutter på å slå gjennom. Gjør dette på forhånd.

1. **GitHub-organisasjon, repo og environment `dev`** som på side 4, med
   environment secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`,
   `AZURE_SUBSCRIPTION_ID` og `KEYVAULT_NAME`.
2. **Federated credential** på App Registration-en med subject
   `repo:<org>/<repo>:environment:dev`.
3. **Object-ID** til service principal-en (ikke client-ID-en):
   ```bash
   az ad sp show --id <client-id> --query id -o tsv
   ```
4. **Bootstrap:**
   ```bash
   cd backend
   cp backend.tfvars.eksempel terraform.tfvars   # fyll inn kortnavn og object-ID
   terraform init && terraform apply
   terraform output -raw backend_hcl             # lim inn i ../backend.hcl
   terraform output -raw keyvault_name           # → KEYVAULT_NAME i GitHub
   ```
5. **Verdiene i Key Vault** (Key Vault tåler ikke `_` i navn):
   ```bash
   KV=$(terraform output -raw keyvault_name)
   az keyvault secret set --vault-name "$KV" --name rg-name  --value rg-demo-<dittkortnavn>
   az keyvault secret set --vault-name "$KV" --name location --value westeurope
   ```
6. `cp infra/dev.tfvars.eksempel infra/dev.tfvars` og fyll inn samme verdier.
7. Sjekk at `backend "azurerm" {}` i `infra/main.tf` er **kommentert ut** —
   demoen starter uten backend.

---

## Live

### 01 · Alt ligger på laptopen

Vis mappa i VS Code. Kode, identitet og state — alt her.

```bash
az account show --query user.name -o tsv     # «det er meg som er identiteten»
cd infra
terraform init
terraform plan  -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
ls                                           # terraform.tfstate ligger i mappa
```

Poeng: `git push` nå ville lagret koden, men ikke startet noe.

### 02 · State flytter ut — kjøringen blir igjen

Fjern kommentaren foran `backend "azurerm" {}` i `infra/main.tf`.

```bash
terraform init -migrate-state \
  -backend-config=../backend.hcl \
  -backend-config="key=dev/infra.tfstate"
rm terraform.tfstate terraform.tfstate.backup
```

Vis blobben i portalen (storage account → `tfstate` → `dev/infra.tfstate`).
Kjør `terraform plan -var-file=dev.tfvars` igjen: *No changes* — state ble med.

Poeng: state er delt og låst, men det er fortsatt du som kjører `apply`, som deg.

### 03 · Repoet er kilden, runneren er utøveren

Åpne `.github/workflows/deploy-dev.yml` og gå gjennom de ni stegene — de har
samme nummer som boksene i figur 03.

Endre taggen `endre = "meg"` i `infra/main.tf` til noe annet, og push:

```bash
git add -A
git status          # ingen .tfvars, ingen .tfstate — takket være .gitignore
git commit -m "Demo: endre tag"
git push
```

Bytt til **Actions** i GitHub. Kjøringen har startet av seg selv, og navnet er
commit-meldingen.

### 04 · Hva har flyttet seg?

Mens runneren jobber: pek i loggen på hvor hvert svar i figur 04 nå ligger.

| Spørsmål | Hvor i loggen |
|---|---|
| Hvor ligger koden? | steg 1 checkout |
| Hvem kjører apply? | `Runner Image` øverst i «Set up job» |
| Med hvilken identitet? | steg 3 azure/login — ingen passord |
| Hvor ligger state? | steg 5 init — `Successfully configured the backend "azurerm"` |
| Hvor kommer verdiene fra? | steg 4 — og steg 9 sletter fila igjen |

Vis til slutt taggen i portalen og **Activity log** på resource groupen:
endringen er gjort av service principal-en, ikke av deg.

### 05 · Én YAML-fil: trigger, identitet og steg

Tilbake i `deploy-dev.yml`. Tre linjer å peke på:

- `on: push` + `branches: [main]` — **når**.
- `environment: dev` — **hvem**. Det er dette federated credential-en matcher på.
- `permissions: id-token: write` — kommenter den ut, push, og se steg 3 feile.
  Sett den tilbake.

### 06 · To feedbackløkker

Legg inn en skrivefeil i `infra/main.tf`, f.eks. `var.rg_nam`.

Lokalt:

```bash
terraform validate    # feilen er synlig på ett sekund
```

Push den samme feilen og ta tiden til steg 6 feiler på runneren. Rett feilen og
push igjen — og vis at historikken nå har en commit som bare retter en
skrivefeil.

### 07 · Hva kjører du lokalt, og hva går via repoet?

```bash
terraform fmt
terraform validate
terraform plan -var-file=dev.tfvars   # lokalt, med din pålogging, mot samme state
git diff
```

`apply` gjør du ikke lengre herfra — den går via push. Poeng: leser og sjekker
det, kan det gjøres lokalt; endrer det et miljø, går det via repoet.

Bonus: start en `plan` lokalt mens workflowen kjører `apply`, og vis
state-låsen.

---

## Rydd opp etter demoen

```bash
cd infra   && terraform destroy -var-file=dev.tfvars
cd ../backend && terraform destroy
```

Key Vault-et ligger i soft delete i 7 dager. Skal du kjøre demoen igjen med
samme kortnavn før det:

```bash
az keyvault purge --name kv-demo-<dittkortnavn>
```

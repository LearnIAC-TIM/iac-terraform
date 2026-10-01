# Demo – modul 6 / Oppgave 6

Alt som trengs for å kjøre Oppgave 6 i `LearnIAC-TIM/iac-terraform`, med
nettverks-stacken. Workflowene er løsningsforslaget til Oppgave 6
(`docs/module-06/oppgave-6-gjennomgang.html`) **ordrett**, med to unntak som
er merket under.

```text
.github/workflows/
  pr-kontroller.yml      fmt og validate, ingen Azure-tilgang     K2
  pr-plan.yml            plan mot dev som PR-kommentar            K4–K5
  terraform-env.yml      plan → apply mot ett miljø, gjenbrukt    K6, K7, K9, K12
  deploy-nettverk.yml    dev → test → prod i én kjøring            K8, K10–K12
  riv-ned-nettverk.yml   opprydding, nå også prod                 Del G
stacks/nettverk/         fra Oppgave 5, med .terraform.lock.hcl (4 plattformer)
modules/network/         fra Oppgave 4
shared/backend.hcl       rg-tfstate-tim / sttfstatetim123 / tfstate
tfvars/                  dev, test, prod → Key Vault. ALDRI i Git
scripts/                 oppsett og kontroll, kjøres lokalt herfra
utgangspunkt/            deploy-nettverk.yml slik den var etter Oppgave 5
```

## Avvik fra løsningsforslagene

| Fil | Avvik | Hvorfor |
|---|---|---|
| `pr-kontroller.yml` | `fmt -check -recursive stacks modules`, ikke fra rota | Repoet har 28 uformaterte `.tf`-filer i `course_materials/`, `testing/` og `_old/`. Fra rota er porten rød på hver PR |
| `modules/network/main.tf` | `azurerm ~> 5.4`, ikke `~> 4.0` | Stacken krever `~> 5.4`. Med modulen fra Oppgave 4 uendret feiler `init` med *no available releases match ~> 4.0, ~> 5.4* |
| `riv-ned-nettverk.yml` | `prod` i lista, concurrency-gruppe `nettverk` | Del G river ned alle tre. Samme gruppe som kjeden, så de ikke kan gå samtidig |

## Hva kopieres til repoet?

`.github/`, `stacks/`, `modules/` og `shared/` til rota av `iac-terraform`. Ingen av
dem kolliderer med noe som ligger der. Repoets egen `.gitignore` stopper allerede
`*.tfvars` og `.terraform/`. Behold den.

**Ikke** `tfvars/` og **ikke** `scripts/`. `config.sh` inneholder client-ID og
Key Vault-navn, og repoet er public.

## Før opptak

```bash
az login
gh auth status

cd ressurser/06/demo
./scripts/01-sjekk-azure.sh                  # backend + Key Vault
./scripts/02-last-opp-tfvars.sh              # tfvars-dev, -test, -prod
./scripts/03-github-environments.sh          # KEYVAULT_NAME på dev/test/prod
./scripts/05-sjekk-oppsett.sh --for-opptak   # skal ende med 0 feil
```

Repoet i **utgangstilstanden** videoplanen beskriver:

- `utgangspunkt/deploy-nettverk.yml` → `.github/workflows/deploy-nettverk.yml`
- `stacks/`, `modules/`, `shared/` som her, med låsefila committet
- `riv-ned-nettverk.yml` kan ligge der fra start
- **ikke** `pr-kontroller.yml`, `pr-plan.yml` eller `terraform-env.yml`. De bygges på skjermen
- ingen branch protection på `main`, ingen `prod-plan`
- **ingen regler på `prod`.** I dag har den *required reviewers: torivarm*. Fjern dem
  før opptak hvis kapittel 6 skal vise at de legges på

Sluttilstanden er `.github/workflows/` her.

## Kapittel 6: `prod-plan`

Videoen oppretter den på skjermen. For å hoppe over det, eller rette opp etterpå:

```bash
./scripts/03-github-environments.sh --med-prod-plan
./scripts/04-federated-credential-prod-plan.sh
./scripts/05-sjekk-oppsett.sh                # nå også prod-plan
```

## Det skriptene ikke gjør

Det som er poenget å vise, gjøres for hånd i GitHub:

- `prod`: required reviewers, *Prevent self-review* av, deployment branches → `main`
- `main`: branch protection med `fmt og validate` som required check,
  0 approvals og *Do not allow bypassing*

`05-sjekk-oppsett.sh` skriver ut hva som står der, så du kan kontrollere etterpå.

## Merk om videoplanen

`video-plan-modul-6.md` er skrevet for webapp-stacken (`terraform-projects/stacks/webapp`,
`deploy-webapp.yml`). Med denne demoen er stiene `stacks/nettverk`,
`deploy-nettverk.yml`, og fella i kapittel 5 blir `path: stacks/nettverk/tfplan`.

## Rydd opp

`riv-ned-nettverk.yml` for dev, test og prod. Prod venter på godkjenning, som ved
utrulling. Backend, Key Vault og `tfvars-prod` blir stående.

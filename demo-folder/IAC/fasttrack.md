# Fast Track: Fra GitHub til Azure med Terraform, GitHub Actions og Federated Identity

*Veiledning for praktisk gjennomføring av Infrastructure as Code*

## Kapittel 1: Etablering av miljøvariabler for Terraform og autentisering

En vellykket start på øvingen forutsetter at studentene setter opp riktige miljøvariabler lokalt. Dette gjør autentiseringen mot Azure forutsigbar og sørger for at Terraform finner nødvendige identifikatorer. Miljøvariabler defineres forskjellig avhengig av om studenten arbeider i Bash eller PowerShell. Begge formatene vises her for å sikre at hver deltaker kan bruke sitt foretrukne arbeidsmiljø.

**Format for miljøvariabler i Bash:**

```bash
export ARM_CLIENT_ID="<AppRegistration-ClientId>"
export ARM_TENANT_ID="<TenantId>"
export ARM_SUBSCRIPTION_ID="<SubscriptionId>"
export ARM_USE_OIDC=true
```

**Format for miljøvariabler i PowerShell:**

```powershell
$env:ARM_CLIENT_ID="<AppRegistration-ClientId>"
$env:ARM_TENANT_ID="<TenantId>"
$env:ARM_SUBSCRIPTION_ID="<SubscriptionId>"
$env:ARM_USE_OIDC="true"
```

Disse variablene representerer identiteten som Terraform skal bruke når infrastrukturen skal bygges, og de samsvarer med den App Registration som senere kobles sammen med GitHub via federerte credentials.

---

## Kapittel 2: Identifikasjon av bruker-ID og tjenesteprinsipp-ID

Når miljøvariablene er på plass, må en finne App Registration (Service Principal ID) og bruker ID. Dette brukes både når en skal sette rettigheter på backend og Key Vault.

---

## Kapittel 3: Distribusjon av backend i Azure for Terraform state-lagring

For at Terraform skal kunne fungere som et teamverktøy, må tilstanden lagres utenfor studentenes maskiner. Dette kapitlet viser hvordan backend mappeverket brukes til å opprette en Azure Storage Account med en container som lagrer state-filene. Under videoen demonstreres initiering og første kjøring slik at studentene observerer hvordan Terraform oppretter ressursene. Når backend er etablert virker dette som et sentralt ankerpunkt for all videre aktivitet, og enhver ny struktur i prosjektet vil bruke denne containeren som sitt faste lagringssted.

---

## Kapittel 4: Lokal testing med TFLint og Checkov

Etter at backend fungerer, arbeider studentene med kvalitetssikring av Terraform-prosjektet ved hjelp av TFLint og Checkov. Denne delen av arbeidet viser hvorfor testing er vesentlig i IaC: feil og sikkerhetsmangler blir identifisert før endringer når GitHub eller Azure. Lokal kjøring viser også hvordan statiske analyser oppfører seg før de flyttes inn i workflowene. Installasjonsprosedyrene følges fra studentenes maskiner, og testene kjøres mot prosjektmappene slik at struktur, naming, policy og sikkerhet evalueres grundig.

---

## Kapittel 5: Distribusjon av Terraform-kode for miljøer som dev og test

Når testene er godkjent, fortsetter studentene med innføringen av miljøbasert infrastruktur. Prosjektstrukturen inneholder egne områder for dev og test, og Terraform-koden som er gitt demonstrerer hvordan parametere og moduler brukes for å skille ressursene. Studentene kjører terraform-init etterfulgt av plan og apply, og verifiserer at storage account for hvert miljø faktisk opprettes i Azure med riktig konfigurasjon. Dette viser hvordan den samme grunnkoden kan brukes til flere miljøer uten duplisering, og hvordan modulær struktur gjør prosjektet skalérbart.

---

## Kapittel 6: Verifikasjon av federerte credentials i Azure AD

Etter at både backend og prosjekt er deployert lokalt, trenger studentene å kontrollere at GitHub-repositoryet har tilgang gjennom federation. Denne kontrollen innebærer å åpne App Registration i Azure AD, navigere til federated credentials, og se at korrekt repository og gren er registrert. Dersom denne tilknytningen mangler eller er feil konfigurert, vil GitHub Actions senere mislykkes i init-fasen. Kontroll av denne konfigurasjonen sikrer også at studentene kan relatere autentiseringsfeil til enten azure- eller github-siden.

---

## Kapittel 7: Opprettelse av workflow for testing i GitHub Actions (MÅ ha lagt til Github Secrets)

Studentene oppretter en første workflow som utelukkende fokuserer på testing. Denne workflowen ligger i `.github/workflows` og definerer kjøringen av både TFLint og Checkov i en automatisert kjede. Videoen viser hvordan denne filen struktureres og forklarer hver del av dens funksjon. Når workflowen lagres og push opereres til repositoryet, vil GitHub automatisk starte testen og dermed gi studentene umiddelbar innsikt i hva som må forbedres før infrastrukturen kan bygges videre.

---

## Kapittel 8: Opprettelse av separate workflows for CI og CD

Når testløpet fungerer, deles pipeline i to deler. Den første delen fungerer som en ren CI-prosess som utfører analyser, policykontroll og terraform-plan. Den andre delen utgjør CD-delen og bruker federert autentisering for å gjennomføre terraform-apply i de utpekte miljøene. Dette kapitlet viser logikken bak separasjonen av arbeidsløp, slik at hver del kan styres etter sine egne regler og approvals. Videoen demonstrerer hvordan filene blir opprettet og lagt til repositoryet og forklarer hvordan GitHub organiserer disse workflowene når de trigges av commits, tags eller manuelt gjennomførte dispatches.

---

## Kapittel 9: Utføring av full CI/CD-kjede

Når både CI og CD-workflows er på plass, vil en oppleve en fullverdig leveransestruktur. Når en endring commit-es, vil CI-workflowen kjøre først og validere kode, struktur og policy. Når testen godkjennes, vil CD-workflowen kunne startes manuelt eller trigges etter gitte regler. Azure vil deretter motta oppdateringer akkurat slik det skjer i profesjonelle miljøer. Dette gir et direkte møte med hvordan automatisert IaC-deploy opptrer og hvilke fordeler dette gir for kvalitet og drift.

---

## Kapittel 10: Rulling tilbake av endringer

Som avslutning i gjennomføringen blir rollback demonstrert. En ruller endringer tilbake enten ved å endre koden til en tidligere versjon eller ved å bruke terraform-destruksjon for miljøer som skal fjernes. Dette gir innsikt i hvordan IaC både bygger og fjerner infrastruktur på en kontrollert måte. Det viser også at feilangrep eller uønskede endringer alltid kan reverseres med kode, og understreker hvorfor deklarativ infrastrukturrepresentasjon er så verdifull i praksis.

---

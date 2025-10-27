# Azure Web App Slot Swap Lab 🚀

Dette er en praktisk labb for å lære om moderne deployment-mønstre med Azure App Service, slot swap, og testing-strategier.

## 📋 Læringsmål

Etter å ha fullført denne labben skal studentene kunne:

1. ✅ Sette opp Azure App Service med staging og production slots
2. ✅ Implementere Blue-Green deployment via slot swap
3. ✅ Skrive og kjøre ulike typer tester (offline, static analysis, online)
4. ✅ Forstå forskjellen mellom ephemeral og persistent miljøer
5. ✅ Bruke feature toggles for gradvis utrulling
6. ✅ Automatisere deployment med GitHub Actions

## 🏗️ Arkitektur

```
┌─────────────────┐
│   GitHub Repo   │
│   (Source Code) │
└────────┬────────┘
         │
         ├──────> PR: Ephemeral Test Environment
         │        - Offline tests
         │        - Static analysis
         │        - Terraform plan
         │
         └──────> Main: Persistent Environment
                  ┌────────────────────────────┐
                  │   Azure App Service Plan   │
                  └────────────┬───────────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
              ┌─────▼─────┐         ┌────▼─────┐
              │  Staging  │         │Production│
              │   Slot    │◄────────┤   Slot   │
              │  (v2 UI)  │  Swap   │  (v1 UI) │
              └───────────┘         └──────────┘
```

## 🚀 Kom i gang

### Forutsetninger

- Azure-konto med aktiv subscription
- Azure CLI installert
- Terraform installert (>= 1.0)
- Node.js 18+ installert
- Git og GitHub-konto

### Steg 1: Sett opp Azure Resources

1. **Logg inn på Azure:**
   ```bash
   az login
   ```

2. **Opprett Service Principal for CI/CD:**
   ```bash
   az ad sp create-for-rbac --name "webapp-lab-sp" \
     --role contributor \
     --scopes /subscriptions/<DIN-SUBSCRIPTION-ID> \
     --sdk-auth
   ```
   
   Lagre output - denne brukes i GitHub Secrets.

3. **Konfigurer Terraform:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Rediger terraform.tfvars med dine verdier
   # VIKTIG: app_name må være globalt unikt!
   ```

4. **Deploy infrastruktur:**
   ```bash
   cd ..
   ./scripts/deploy-infrastructure.sh
   ```

### Steg 2: Deploy Applikasjonen

1. **Deploy til staging:**
   ```bash
   ./scripts/deploy-app.sh <app-name> <resource-group> staging
   ```

2. **Verifiser staging:**
   Åpne `https://<app-name>-staging.azurewebsites.net` i nettleseren.
   Du skal se versjon "v2" med grønn bakgrunn (feature toggle aktivert).

3. **Deploy til production:**
   ```bash
   ./scripts/deploy-app.sh <app-name> <resource-group> production
   ```

4. **Verifiser production:**
   Åpne `https://<app-name>.azurewebsites.net` i nettleseren.
   Du skal se versjon "v1" med blå bakgrunn (feature toggle deaktivert).

### Steg 3: Kjør Tester

Labben inkluderer fire nivåer av tester:

1. **Offline Tests** (ingen Azure-tilkobling):
   ```bash
   ./tests/offline-tests.sh
   ```

2. **Static Analysis**:
   ```bash
   ./tests/static-analysis-tests.sh
   ```

3. **Online Verification**:
   ```bash
   export RESOURCE_GROUP="<din-rg>"
   export APP_NAME="<ditt-app>"
   ./tests/online-verification-tests.sh
   ```

4. **Online Outcome Tests**:
   ```bash
   ./tests/online-outcome-tests.sh
   ```

### Steg 4: Utfør Blue-Green Deployment

```bash
./scripts/swap-slots.sh <app-name> <resource-group>
```

Etter swap skal production nå vise "v2" med grønn bakgrunn! 🎉

## 📂 Mappestruktur

```
azure-webapp-lab/
├── terraform/              # Infrastruktur som kode
│   ├── main.tf            # Hovedkonfigurasjon
│   ├── variables.tf       # Input variabler
│   ├── outputs.tf         # Output verdier
│   └── terraform.tfvars.example
├── app/                   # Node.js applikasjon
│   ├── package.json
│   ├── server.js          # Express server med feature toggle
│   └── .deployment
├── scripts/               # Deployment scripts
│   ├── deploy-infrastructure.sh
│   ├── deploy-app.sh
│   └── swap-slots.sh
├── tests/                 # Test suite
│   ├── offline-tests.sh
│   ├── static-analysis-tests.sh
│   ├── online-verification-tests.sh
│   └── online-outcome-tests.sh
├── .github/workflows/     # CI/CD pipelines
│   ├── pr-validation.yml
│   └── main-deployment.yml
└── docs/                  # Dokumentasjon
    └── TESTING_STRATEGY.md
```

## 🧪 Testing-strategi

### Test-pyramiden:

```
           ┌─────────────────┐
           │  Online Outcome │  ← Få, trege, kostbare
           └────────┬────────┘
                    │
         ┌──────────▼─────────┐
         │ Online Verification│
         └──────────┬─────────┘
                    │
        ┌───────────▼──────────┐
        │  Static Analysis     │
        └───────────┬──────────┘
                    │
     ┌──────────────▼─────────────┐
     │      Offline Tests          │  ← Mange, raske, billige
     └─────────────────────────────┘
```

## 🎯 Oppgaver for Studenter

### Grunnleggende (Alle skal gjøre)

1. ✅ Deploy infrastruktur med Terraform
2. ✅ Deploy app til staging og production
3. ✅ Kjør alle fire test-nivåer
4. ✅ Utfør vellykket slot swap
5. ✅ Verifiser feature toggle

### Middels (Velg 2-3)

6. 🔧 Modifiser appen til å vise studentens navn
7. 🔧 Legg til en ny feature toggle (f.eks. dark mode)
8. 🔧 Utvid testene med ekstra sjekker
9. 🔧 Legg til Application Insights
10. 🔧 Implementer automatisk rollback

### Avansert (Velg 1-2)

11. 🚀 Sett opp full GitHub Actions CI/CD
12. 🚀 Implementer canary deployment
13. 🚀 Legg til Azure Policy
14. 🚀 Infrastructure testing med Terratest
15. 🚀 Monitoring med alerts

## 🆘 Troubleshooting

### Terraform Apply feiler
**Løsning:** app_name må være globalt unikt. Prøv med dine initialer + tall.

### Health check feiler
**Løsning:** 
- Sjekk Azure Portal → App Service → Log stream
- Verifiser at PORT miljøvariabel er satt
- Kontroller at Node.js app startet

### Feature toggle vises ikke
**Løsning:**
- Sjekk Application Settings i Azure Portal
- Verifiser FEATURE_TOGGLE_NEW_UI
- Restart app service

## 📚 Ressurser

- [Azure App Service Docs](https://docs.microsoft.com/azure/app-service/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/)
- [GitHub Actions for Azure](https://github.com/Azure/actions)
- [Blue-Green Deployment](https://martinfowler.com/bliki/BlueGreenDeployment.html)

## 📧 Kontakt

Ved spørsmål, kontakt:
- Lærer: [navn@epost.no]
- Slack: #webapp-lab

---

**Lykke til!** 🎓🚀

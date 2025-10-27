# 🎓 Azure Web App Slot Swap Lab - Komplett Pakke

## 📦 Hva er inkludert?

Denne pakken inneholder alt du trenger for å kjøre en praktisk labb om:
- Azure App Service med staging/production slots
- Blue-Green deployment via slot swap
- Feature toggles
- Komplett testing-strategi (4 nivåer)
- CI/CD med GitHub Actions

## 📁 Struktur (19 filer)

```
azure-webapp-lab/
├── 📖 README.md                    # Hovedinstruksjoner for studenter
├── 🚫 .gitignore                  # Git ignore-regler
│
├── 🏗️  terraform/                  # Infrastruktur som kode
│   ├── main.tf                    # Hovedkonfigurasjon (RG, App Service, Slots)
│   ├── variables.tf               # Input-variabler
│   ├── outputs.tf                 # Output-verdier (URLs, IDs)
│   └── terraform.tfvars.example   # Eksempel på konfigurasjon
│
├── 🌐 app/                        # Node.js web applikasjon
│   ├── package.json               # NPM dependencies
│   ├── server.js                  # Express server med feature toggle
│   └── .deployment                # Azure deployment konfig
│
├── 📜 scripts/                    # Deployment scripts
│   ├── deploy-infrastructure.sh   # Deploy Terraform
│   ├── deploy-app.sh              # Deploy app til slot
│   └── swap-slots.sh              # Utfør blue-green swap
│
├── 🧪 tests/                      # Test suite (4 nivåer)
│   ├── offline-tests.sh           # Syntaks, sikkerhet (⚡ 10 sek)
│   ├── static-analysis-tests.sh   # Policy, Terraform plan (🔍 30 sek)
│   ├── online-verification-tests.sh # Infra verification (✅ 2 min)
│   └── online-outcome-tests.sh    # E2E, health checks (🎯 5 min)
│
├── ⚙️  .github/workflows/          # CI/CD pipelines
│   ├── pr-validation.yml          # PR workflow (ephemeral)
│   └── main-deployment.yml        # Main workflow (persistent)
│
└── 📚 docs/                       # Dokumentasjon
    └── TESTING_STRATEGY.md        # Detaljert test-strategi

```

## 🚀 Rask Start

### 1. Pakk ut og naviger
```bash
cd azure-webapp-lab
```

### 2. Les README.md
Åpn `README.md` for komplette instruksjoner.

### 3. Konfigurer Azure
```bash
# Logg inn
az login

# Konfigurer Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Rediger terraform.tfvars - VIKTIG: app_name må være globalt unikt!
```

### 4. Deploy infrastruktur
```bash
cd ..
./scripts/deploy-infrastructure.sh
```

### 5. Deploy app
```bash
# Deploy til staging
./scripts/deploy-app.sh <app-name> <resource-group> staging

# Deploy til production
./scripts/deploy-app.sh <app-name> <resource-group> production
```

### 6. Test
```bash
# Kjør alle tester
./tests/offline-tests.sh
./tests/static-analysis-tests.sh

export RESOURCE_GROUP="<din-rg>"
export APP_NAME="<ditt-app>"
./tests/online-verification-tests.sh
./tests/online-outcome-tests.sh
```

### 7. Slot Swap
```bash
./scripts/swap-slots.sh <app-name> <resource-group>
```

## 🎯 Pedagogiske Mål

Denne labben lærer studentene:

### 1. **Infrastructure as Code**
- Terraform for Azure-ressurser
- Variables, outputs, state management
- Best practices for IaC

### 2. **Modern Deployment Patterns**
- Blue-Green deployment med slot swap
- Zero-downtime deployments
- Rollback-strategier

### 3. **Feature Toggles**
- Runtime konfigurasjon
- A/B testing muligheter
- Gradvis utrulling

### 4. **Testing Pyramid**
```
         ┌─────────┐
         │  E2E    │  ← Få, trege, dyre
         └────┬────┘
              │
      ┌───────▼──────┐
      │ Integration  │
      └───────┬──────┘
              │
   ┌──────────▼─────────┐
   │    Unit/Static     │  ← Mange, raske, billige
   └────────────────────┘
```

### 5. **CI/CD Best Practices**
- Ephemeral environments for PR
- Persistent test environment
- Scheduled drift detection
- Automated testing i pipeline

### 6. **Cloud Security**
- HTTPS-only enforcement
- Minimum TLS versjon
- Azure Policy compliance
- Tagging strategy

## 📊 Test-nivåer Oversikt

| Nivå | Tid | Kostnad | Når | Azure Credentials |
|------|-----|---------|-----|-------------------|
| 1. Offline | 10s | $0 | Hver commit | ❌ Nei |
| 2. Static Analysis | 30s | $0.01 | Hver PR | ✅ Ja |
| 3. Online Verification | 2m | $0.05 | Main merge | ✅ Ja |
| 4. Online Outcome | 5m | $0.10 | Main + scheduled | ✅ Ja |

**Total månedlig kostnad:** $5-15 (ved aktiv utvikling)

## 🎓 Oppgaveforslag

### Grunnleggende (alle)
1. ✅ Deploy komplett infrastruktur
2. ✅ Deploy til begge slots
3. ✅ Kjør alle 4 test-nivåer
4. ✅ Utfør vellykket slot swap
5. ✅ Verifiser feature toggle

### Middels (velg 2-3)
6. 🔧 Modifiser UI med eget navn/design
7. 🔧 Legg til ny feature toggle (dark mode)
8. 🔧 Utvid test-suite med egne tester
9. 🔧 Legg til Application Insights
10. 🔧 Implementer auto-rollback

### Avansert (velg 1-2)
11. 🚀 Full GitHub Actions pipeline
12. 🚀 Canary deployment (gradvis trafikk)
13. 🚀 Azure Policy integration
14. 🚀 Infrastructure testing (Terratest)
15. 🚀 Custom monitoring med alerts

## 💡 Viktige Konsepter

### Blue-Green Deployment
```
Before Swap:
Production → v1.0 (blå)
Staging → v2.0 (grønn) ← Testing her først

After Swap:
Production → v2.0 (grønn) ✅
Staging → v1.0 (blå) ← Klar for rollback
```

### Feature Toggles
```javascript
// Production slot: FEATURE_TOGGLE_NEW_UI = false → v1 UI (blå)
// Staging slot: FEATURE_TOGGLE_NEW_UI = true → v2 UI (grønn)
```

## 🆘 Vanlige Problemer

### "app_name already exists"
**Løsning:** App navn må være globalt unikt i Azure. Bruk dine initialer + tall.

### "Terraform init fails"
**Løsning:** Sjekk at Azure credentials er satt (`az login` først).

### "Health check fails"
**Løsning:** 
- Vent 2-3 minutter etter deploy
- Sjekk Log stream i Azure Portal
- Verifiser at PORT miljøvariabel er satt

### "Feature toggle not working"
**Løsning:**
- Verifiser Application Settings i Azure Portal
- Restart app service
- Clear browser cache

## 📚 Nyttige Kommandoer

```bash
# Se alle filer
find . -type f | sort

# Kjør alle tester raskt
for test in tests/*.sh; do bash "$test"; done

# Vis Terraform output
cd terraform && terraform output

# Stream Azure logs
az webapp log tail --name <app-name> --resource-group <rg>

# Vis app settings
az webapp config appsettings list --name <app-name> --resource-group <rg>

# Manual slot swap
az webapp deployment slot swap \
  --name <app-name> \
  --resource-group <rg> \
  --slot staging
```

## 📧 Support

- 📖 Les README.md for komplette instruksjoner
- 📚 Se docs/TESTING_STRATEGY.md for test-detaljer
- 🐛 GitHub Issues for bugs
- 💬 Slack: #webapp-lab

## ✅ Sjekkliste for Studenter

- [ ] Lest README.md
- [ ] Azure CLI installert og innlogget
- [ ] Terraform installert
- [ ] Node.js 18+ installert
- [ ] terraform.tfvars konfigurert
- [ ] Infrastruktur deployet
- [ ] App deployet til staging
- [ ] App deployet til production
- [ ] Offline tests kjørt
- [ ] Static analysis kjørt
- [ ] Online verification kjørt
- [ ] Slot swap utført
- [ ] Feature toggle verifisert
- [ ] Rapport skrevet

## 🎉 Lykke til!

Dette er en omfattende labb som dekker mange viktige konsepter i moderne cloud development. Ta deg god tid, eksperimenter, og ikke vær redd for å gjøre feil - det er slik vi lærer! 🚀

---

**Versjon:** 1.0  
**Sist oppdatert:** Oktober 2025  
**Estimert tidsbruk:** 4-6 timer

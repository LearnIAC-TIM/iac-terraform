# 👨‍🏫 Guide for Lærer

## 🎯 Hva er dette?

En **komplett, kjørbar labb** for å lære studenter om:
- Azure App Service med slot swap
- Blue-Green deployment
- Infrastructure as Code (Terraform)
- Testing-strategier (4 nivåer)
- CI/CD med GitHub Actions
- Feature toggles

## ⚡ Rask Oppsummering

**Tidsbruk for studenter:** 4-6 timer  
**Forkunnskaper:** Grunnleggende Azure, Git, CLI  
**Kostnader:** ~$5-15/måned ved aktiv bruk  
**Vanskelighetsgrad:** Middels-Avansert

## 📦 Hva Får Studentene?

### 19 ferdige filer:
- ✅ Terraform-kode (4 filer) - komplett infrastruktur
- ✅ Node.js web-app (3 filer) - med feature toggle
- ✅ Deployment scripts (3 bash scripts)
- ✅ Test suite (4 bash scripts, 4 nivåer)
- ✅ GitHub Actions (2 workflows)
- ✅ Dokumentasjon (2 markdown filer)
- ✅ .gitignore

### Alt er klart til bruk - ingen placeholders!

## 🚀 Hvordan Bruke Labben

### Forberedelse (En gang)

1. **Del ut materialet:**
   ```bash
   # Gi studentene tilgang til azure-webapp-lab mappen
   # De kan klone fra Git eller laste ned ZIP
   ```

2. **Forutsetninger for studenter:**
   - Azure-konto (student subscription anbefales)
   - Azure CLI installert
   - Terraform installert
   - Node.js 18+
   - Git

3. **Demo (valgfritt):**
   - Vis en kjapp gjennomgang (15-20 min)
   - Demonstrer slot swap visuelt
   - Forklar feature toggle-konseptet

### Gjennomføring

**Del 1: Infrastruktur (1-2 timer)**
- Les README.md
- Konfigurer terraform.tfvars
- Deploy infrastruktur
- Kjør offline + static analysis tests

**Del 2: Applikasjon (1-2 timer)**
- Deploy til staging og production
- Verifiser at begge slots virker
- Kjør online verification tests
- Forstå forskjellen i feature toggles

**Del 3: Deployment (1-2 timer)**
- Utfør slot swap
- Kjør outcome tests
- Observer effekten
- Diskuter rollback-strategi

**Del 4: Forbedringer (1-2 timer)**
- Velg 2-3 middels oppgaver
- Implementer forbedringer
- Test endringene
- (Valgfritt) Sett opp CI/CD

## 🎓 Læringsmål (Blooms Taksonomi)

### Huske (Knowledge)
- ☑️ Definere Blue-Green deployment
- ☑️ Liste opp test-nivåer
- ☑️ Forklare slot swap-konseptet

### Forstå (Comprehension)
- ☑️ Sammenligne staging vs production
- ☑️ Forklare feature toggles
- ☑️ Beskrive testing-pyramiden

### Anvende (Application)
- ☑️ Deploy infrastruktur med Terraform
- ☑️ Utføre slot swap
- ☑️ Kjøre tester på ulike nivåer

### Analysere (Analysis)
- ☑️ Evaluere test-strategi
- ☑️ Identifisere sikkerhetsrisikoer
- ☑️ Sammenligne deployment-mønstre

### Evaluere (Evaluation)
- ☑️ Vurdere kostnad vs nytte
- ☑️ Kritisere arkitektur-valg
- ☑️ Anbefale forbedringer

### Skape (Creation)
- ☑️ Implementere nye features
- ☑️ Designe test-scenarier
- ☑️ Lage CI/CD pipeline

## 📊 Vurdering - Forslag

### Grunnleggende (40%)
```
□ Infrastruktur deployet korrekt (10p)
□ App deployet til begge slots (10p)
□ Alle tester kjører (10p)
□ Slot swap vellykket (10p)
```

### Forståelse (30%)
```
□ Rapport som forklarer:
  - Blue-Green deployment-konseptet (10p)
  - Testing-strategien (10p)
  - Feature toggle-implementasjonen (10p)
```

### Forbedringer (30%)
```
□ 2-3 middels oppgaver fullført (20p)
□ Kode-kvalitet og dokumentasjon (10p)
```

**Bonus (opptil 15%)**
```
□ CI/CD pipeline implementert (+5p)
□ Avanserte oppgaver (+5p)
□ Særlig kreative løsninger (+5p)
```

## 🛠️ Tekniske Detaljer

### Azure Ressurser Som Opprettes

```
Resource Group
└── App Service Plan (B1 tier - $13-15/måned)
    └── Web App
        ├── Production slot (default)
        └── Staging slot
```

**Månedlig kostnad:** $13-15 for B1 tier (anbefalt for lab)

### Feature Toggle Implementasjon

```javascript
// Miljøvariabel per slot:
Production:  FEATURE_TOGGLE_NEW_UI = "false" → Blå UI (v1)
Staging:     FEATURE_TOGGLE_NEW_UI = "true"  → Grønn UI (v2)

// Etter swap:
Production:  FEATURE_TOGGLE_NEW_UI = "true"  → Grønn UI (v2) ✅
Staging:     FEATURE_TOGGLE_NEW_UI = "false" → Blå UI (v1)
```

### Test-strategi - Fire Nivåer

| Nivå | Tid | Når | Fanger |
|------|-----|-----|--------|
| 1. Offline | 10s | Hver commit | Syntaks, sikkerhet |
| 2. Static Analysis | 30s | Hver PR | Policy, plan |
| 3. Online Verification | 2m | Main merge | Infra-config |
| 4. Online Outcome | 5m | Main + scheduled | Funksjonalitet |

## 💡 Pedagogiske Tips

### 1. Vis Visuelt
Før slot swap:
- Åpne prod URL (blå, v1)
- Åpne staging URL (grønn, v2)

Etter swap:
- Refresh prod URL → Nå grønn (v2)! 🎉
- Staging URL → Nå blå (v1)

### 2. Diskuter Trade-offs
- Hvorfor ikke alltid teste alt?
- Kostnad vs sikkerhet
- Hastighet vs grundighet

### 3. Koble til Virkelighet
- Netflix, Facebook, Google bruker lignende teknikker
- Canary deployments
- A/B testing i produksjon

### 4. Gruppediskusjoner
- Hva hvis swap feiler?
- Hvordan håndtere database-migrasjoner?
- Når er Blue-Green bedre enn rolling updates?

## 🐛 Vanlige Feil og Løsninger

### "Terraform apply feiler"
**Årsak:** app_name ikke unikt  
**Løsning:** Bruk initialer + tall (eks: webapp-js-12345)

### "Node modules error ved deploy"
**Årsak:** .deployment fil mangler  
**Løsning:** Sjekk at .deployment finnes i app-mappen

### "Kan ikke se forskjell etter swap"
**Årsak:** Browser cache  
**Løsning:** Hard refresh (Ctrl+Shift+R)

### "GitHub Actions feiler"
**Årsak:** Secrets ikke satt  
**Løsning:** Verifiser alle AZURE_* secrets i GitHub

## 📋 Sjekkliste for Deg

**Før labben:**
- [ ] Test at du kan kjøre alt selv
- [ ] Verifiser at alle scripts fungerer
- [ ] Forbered demo (valgfritt)
- [ ] Del ut azure-webapp-lab mappen

**Under labben:**
- [ ] Introduser case (15 min)
- [ ] Vis slot swap visuelt (5 min)
- [ ] Vær tilgjengelig for spørsmål
- [ ] Observer vanlige feil

**Etter labben:**
- [ ] Samle inn innleveringer
- [ ] Gi konstruktiv feedback
- [ ] Diskuter læringspunkter i plenum

## 🎯 Læringsutbytte

Etter denne labben skal studentene kunne:

1. **Sette opp** Azure infrastruktur med Terraform
2. **Implementere** Blue-Green deployment
3. **Skrive** tester på ulike nivåer
4. **Forstå** når ulike test-strategier er passende
5. **Bruke** feature toggles for risikoreduksjon
6. **Automatisere** deployment med CI/CD

## 🔗 Utvidelser

Hvis studentene vil gå videre:

- **Database:** Legg til Azure SQL med migrations
- **Monitoring:** Application Insights + alerts
- **Security:** Key Vault for secrets
- **Scaling:** Auto-scaling rules
- **Custom Domain:** CNAME + SSL certificate
- **Multi-region:** Traffic Manager

## 📧 Spørsmål?

Hvis du har spørsmål eller forslag til forbedringer:
- Åpne issues i repo
- Kontakt [din epost]

---

**God fornøyelse med undervisningen!** 🎓

PS: Alle scripts er testet og fungerer. Hvis noe ikke virker, sjekk først at:
1. Azure CLI er innlogget (`az login`)
2. Terraform er installert
3. app_name i terraform.tfvars er globalt unikt

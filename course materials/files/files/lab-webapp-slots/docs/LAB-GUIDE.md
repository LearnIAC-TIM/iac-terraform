# 📖 Detaljert Lab-guide

## Scenario

Du er DevOps-ingeniør i et team som utvikler en web-applikasjon. Teamet ønsker å:
1. Redusere risiko ved deployments
2. Teste nye features i produksjonslignende miljø
3. Kunne rulle tilbake raskt ved problemer
4. Automatisere testing og deployment

## Gjennomføring (4 timer)

### Time 1: Grunnleggende Forståelse (60 min)

#### 1.1 Introduksjon til Deployment Slots (20 min)
- Hva er deployment slots?
- Blue-green deployment forklart
- Slot swap vs rolling deployment

**Praktisk demo**: Kjør lokal app med ulike environment variabler

```bash
# Terminal 1: Production mode
export ENVIRONMENT=production FEATURE_TOGGLE_X=false
python app/app.py

# Terminal 2: Test forskjellen
curl http://localhost:8000/feature-x
```

#### 1.2 Infrastructure as Code (20 min)
- Terraform basics
- Azure provider konfigurasjon
- Resource dependencies

**Oppgave**: Analyser `terraform/main.tf`
- Identifiser alle ressurser
- Finn sikkerhetskonfigurasjoner (https_only, tls_version, ftp)
- Diskuter: Hvorfor er tags viktige?

#### 1.3 Test Strategi (20 min)
- Test pyramid
- Shift-left testing
- Cost of bugs

**Diskusjon**:
- Hva er kostnaden ved en bug i production vs staging vs development?
- Hvordan balanserer vi test-dekningsgrad mot utviklingshastighet?

### Time 2: Hands-on Infrastructure (60 min)

#### 2.1 Deploy Infrastructure (30 min)

```bash
# Login
az login

# Sett subscription (om nødvendig)
az account set --subscription "Your Subscription"

# Deploy
cd terraform
terraform init
terraform plan  # Les outputen nøye!
terraform apply

# Noter ned outputs
terraform output
```

**Oppgaver**:
1. Åpne Azure Portal og verifiser at ressursene er opprettet
2. Sjekk tags på ressursene
3. Naviger til Web App → Configuration → Deployment slots

#### 2.2 Kjør Offline og Policy Tests (15 min)

```bash
# Offline
bash scripts/test-offline.sh

# Policy
bash scripts/test-policy.sh
```

**Refleksjon**:
- Hvilke feil ville disse testene fanget opp?
- Når i utviklingsprosessen kjøres de?

#### 2.3 Kjør Verification Tests (15 min)

```bash
WEBAPP_NAME=$(cd terraform && terraform output -raw webapp_name)
RG_NAME=$(cd terraform && terraform output -raw resource_group_name)

bash scripts/test-verify.sh $WEBAPP_NAME $RG_NAME
```

**Analyse**:
- Sjekk scriptet: Hva verifiseres?
- Hvordan ville du utvidet testene?

### Time 3: Application Deployment (60 min)

#### 3.1 Manuell Deploy til Staging (30 min)

```bash
# Pakk applikasjonen
cd app
zip -r ../app.zip . -x "*.pyc" -x "__pycache__/*"
cd ..

# Deploy til staging slot
az webapp deployment source config-zip \
  --resource-group $RG_NAME \
  --name $WEBAPP_NAME \
  --slot staging \
  --src app.zip

# Vent på at deployment fullføres
sleep 30
```

**Test staging**:
```bash
STAGING_URL="https://${WEBAPP_NAME}-staging.azurewebsites.net"

# Health check
bash scripts/test-health.sh $STAGING_URL staging

# Manuell testing
curl $STAGING_URL
curl $STAGING_URL/feature-x
curl $STAGING_URL/health
```

#### 3.2 Sammenlign Staging og Production (15 min)

```bash
PROD_URL="https://${WEBAPP_NAME}.azurewebsites.net"

# Production (skal være tom/default nå)
curl $PROD_URL

# Staging (skal ha din app)
curl $STAGING_URL
```

**Diskuter**:
- Hva ser du av forskjeller?
- Hvordan kan du teste at feature toggle fungerer?

#### 3.3 Slot Swap (15 min)

```bash
# Kjør swap-script (inkluderer pre/post checks)
bash scripts/swap-slots.sh $WEBAPP_NAME $RG_NAME

# Verifiser
curl $PROD_URL
curl $PROD_URL/feature-x
```

**Eksperiment**:
1. Gjør en endring i app.py (f.eks. endre welcome message)
2. Deploy til staging
3. Test staging
4. Swap til production
5. Verifiser endringen i production

### Time 4: CI/CD Automation (60 min)

#### 4.1 GitHub Actions Setup (20 min)

```bash
# Init git repo
git init
git add .
git commit -m "Initial lab setup"

# Opprett GitHub repo og push
git remote add origin <your-repo-url>
git push -u origin main
```

**Konfigurer Secrets** (i GitHub Settings → Secrets):

Opprett Service Principal:
```bash
az ad sp create-for-rbac --name "github-webapp-lab" \
  --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

Legg til secrets:
- `AZURE_CREDENTIALS`: Hele JSON outputen fra kommandoen over
- `AZURE_CLIENT_ID`: `clientId` fra JSON
- `AZURE_CLIENT_SECRET`: `clientSecret` fra JSON
- `AZURE_SUBSCRIPTION_ID`: `subscriptionId` fra JSON
- `AZURE_TENANT_ID`: `tenantId` fra JSON

#### 4.2 Test PR Workflow (20 min)

```bash
# Opprett feature branch
git checkout -b feature/new-endpoint

# Legg til ny endpoint i app.py
cat >> app/app.py << 'ENDPOINT'

@app.route('/api/students')
def students():
    return jsonify({
        'students': ['Alice', 'Bob', 'Charlie'],
        'environment': ENVIRONMENT
    })
ENDPOINT

# Commit og push
git add app/app.py
git commit -m "Add students endpoint"
git push origin feature/new-endpoint
```

**I GitHub**:
1. Opprett Pull Request
2. Observer workflow kjøring
3. Sjekk at alle tests passerer
4. Noter preview URL (i logs)
5. Test preview miljøet

#### 4.3 Merge og Production Deploy (20 min)

```bash
# Merge PR i GitHub UI

# Observér main workflow
# - Kjører alle tests
# - Deployer til staging
# - Swapper til production
```

**Verifiser**:
1. Sjekk at production URL har den nye endpointen
2. Test: `curl $PROD_URL/api/students`
3. Sjekk at preview miljøet ble ryddet opp

## 🎯 Ekstra Utfordringer

### Utfordring 1: Custom Health Checks
Utvid `/health` endpoint til å sjekke:
- Database tilkobling (mock)
- External API (mock)
- Disk space

### Utfordring 2: Gradual Rollout
Modifiser swap-script til å:
1. Route 10% trafikk til ny versjon
2. Vent 5 min
3. Sjekk error rate
4. Full swap eller rollback

### Utfordring 3: Monitoring
Legg til Application Insights:
- Custom metrics
- Exception tracking
- Performance monitoring

### Utfordring 4: Multi-stage Pipeline
Utvid workflow med:
- Dev environment (automatisk deploy)
- Test environment (deploy etter godkjenning)
- Prod environment (deploy etter godkjenning + smoke tests)

## 📊 Evalueringskriterier

### Grunnleggende (bestått)
- ✅ Infrastruktur deployet korrekt
- ✅ Applikasjon kjører i begge slots
- ✅ Slot swap utført vellykket
- ✅ Alle test-scripts kjører uten feil

### Avansert (høy karakter)
- ✅ CI/CD pipeline fullt fungerende
- ✅ Forstår trade-offs i deployment-strategier
- ✅ Implementert ekstra utfordringer
- ✅ God dokumentasjon av endringer

## 🤔 Refleksjonsspørsmål

1. **Sikkerhet**
   - Hvilke sikkerhetstiltak er implementert?
   - Hva mangler? (Secrets management, network isolation, etc.)

2. **Skalerbarhet**
   - Hvordan ville du håndtert 100x mer trafikk?
   - Database i samme setup?

3. **Kostnader**
   - Hva koster dette setuppet per måned?
   - Hvordan optimalisere?

4. **Feilhåndtering**
   - Hva skjer hvis swap feiler?
   - Hvordan rulle tilbake?

5. **Team Workflow**
   - Hvordan ville flere utviklere jobbe sammen?
   - Branch strategi?

---

**Lykke til! 🚀**

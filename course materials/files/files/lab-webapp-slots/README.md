# 🚀 Azure Web App Deployment Slots Lab

Praktisk øvelse i moderne deployment-mønstre med Azure App Service slots, Infrastructure as Code, og CI/CD.

## 📋 Læringsmål

Etter gjennomført lab skal studentene kunne:
- ✅ Sette opp Web App med staging/production slots ved hjelp av Terraform
- ✅ Implementere sikker slot swap-strategi (blue-green deployment)
- ✅ Bruke feature toggles for gradvis utrulling
- ✅ Implementere multi-layer testing (offline → policy → verification → outcomes)
- ✅ Forstå forskjellen mellom ephemeral (PR) og persistent (main) miljøer
- ✅ Orkestere test-pipeline i CI/CD

## 🏗️ Arkitektur

```
┌─────────────────────────────────────────┐
│     Azure App Service Plan (Linux)      │
│  ┌───────────────────────────────────┐  │
│  │     Web App                       │  │
│  │  ┌──────────┐     ┌────────────┐ │  │
│  │  │Production│ ←──→ │  Staging   │ │  │
│  │  │  Slot    │ SWAP │   Slot     │ │  │
│  │  └──────────┘     └────────────┘ │  │
│  │                                   │  │
│  │  Feature Toggle: OFF   Toggle: ON│  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## 🚦 Test-nivåer

### 1. **Offline Testing** (scripts/test-offline.sh)
- Syntaks-validering (Terraform, Python)
- Linting
- Sikkerhetssjekk (hardkodede secrets)
- ✅ **Når**: Ved hver kodeendring, lokalt og i CI

### 2. **Connected Static Analysis** (scripts/test-policy.sh)
- Policy compliance (påkrevde tags)
- HTTPS-only enforcement
- FTP deaktivering
- TLS minimum version
- ✅ **Når**: I PR-validering, før deployment

### 3. **Online Verification** (scripts/test-verify.sh)
- Sjekk at ressurser eksisterer
- Verifiser konfigurasjon
- Sammenlign slots
- ✅ **Når**: Etter infrastructure deployment

### 4. **Online Outcomes** (scripts/test-health.sh)
- Health checks (HTTP 200)
- Feature toggle testing
- Response validation
- ✅ **Når**: Før og etter slot swap

## 🎯 Oppgaver

### Del 1: Lokal Utvikling
1. **Setup miljø**
   ```bash
   # Installer dependencies
   pip install -r app/requirements.txt
   
   # Kjør appen lokalt
   cd app
   export ENVIRONMENT=local
   export FEATURE_TOGGLE_X=true
   python app.py
   ```

2. **Test lokalt**
   ```bash
   curl http://localhost:8000/
   curl http://localhost:8000/health
   curl http://localhost:8000/feature-x
   ```

### Del 2: Infrastructure Deployment
1. **Login til Azure**
   ```bash
   az login
   ```

2. **Deploy med Terraform**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Verifiser deployment**
   ```bash
   cd ..
   WEBAPP_NAME=$(cd terraform && terraform output -raw webapp_name)
   RG_NAME=$(cd terraform && terraform output -raw resource_group_name)
   
   bash scripts/test-verify.sh $WEBAPP_NAME $RG_NAME
   ```

### Del 3: Application Deployment
1. **Deploy til staging**
   ```bash
   az webapp deployment source config-zip \
     --resource-group $RG_NAME \
     --name $WEBAPP_NAME \
     --slot staging \
     --src app.zip  # (create zip first: cd app && zip -r ../app.zip .)
   ```

2. **Test staging**
   ```bash
   STAGING_URL="https://${WEBAPP_NAME}-staging.azurewebsites.net"
   bash scripts/test-health.sh $STAGING_URL staging
   ```

### Del 4: Slot Swap
1. **Utfør swap**
   ```bash
   bash scripts/swap-slots.sh $WEBAPP_NAME $RG_NAME
   ```

2. **Verifiser production**
   ```bash
   PROD_URL="https://${WEBAPP_NAME}.azurewebsites.net"
   bash scripts/test-health.sh $PROD_URL production
   ```

### Del 5: CI/CD Pipeline
1. **Sett opp GitHub repository**
   ```bash
   git init
   git add .
   git commit -m "Initial lab setup"
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Konfigurer GitHub Secrets**
   - `AZURE_CREDENTIALS`: Service Principal JSON
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`

3. **Test PR workflow**
   ```bash
   git checkout -b feature/test-change
   # Gjør en endring i app/app.py
   git commit -am "Test change"
   git push origin feature/test-change
   # Opprett PR i GitHub
   ```

## 🎓 Diskusjonspunkter

1. **Blue-Green vs Canary Deployment**
   - Hva er forskjellen?
   - Når bruker man hvilken strategi?

2. **Feature Toggles**
   - Fordeler og ulemper?
   - Hvordan unngå "technical debt"?

3. **Ephemeral Environments**
   - Hvorfor er PR-baserte miljøer nyttige?
   - Kostnad vs nytte?

4. **Test Pyramid**
   - Hvorfor flere offline tester enn online?
   - Balanse mellom hastighet og grundighet?

## 🧹 Cleanup

```bash
cd terraform
terraform destroy
```

## 📚 Ressurser

- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Deployment Slots Best Practices](https://learn.microsoft.com/en-us/azure/app-service/deploy-best-practices)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## ❓ Troubleshooting

**Problem**: Slot swap feiler
- ✅ Sjekk at begge slots er healthy
- ✅ Verifiser at app settings er korrekt konfigurert

**Problem**: Health check timeout
- ✅ Øk timeout i test-health.sh
- ✅ Sjekk app logs: `az webapp log tail`

**Problem**: Terraform state conflicts
- ✅ Bruk remote backend (Azure Storage)
- ✅ Eller bruk unik prefix per student

---

**🎉 Lykke til med labben!**

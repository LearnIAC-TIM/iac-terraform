# Azure Terraform Workshop - Complete Package 📦

## 🎉 Velkommen!

Dette er en **komplett, produksjonsklar** Terraform-konfigurasjon for å deploye en moderne web-applikasjon infrastruktur i Azure.

## 📁 Hva er inkludert?

### ✅ Infrastruktur (Terraform)
- **App Service Plan** + **Web App** (Linux)
- **PostgreSQL Flexible Server** (private networking)
- **Virtual Network** med subnets og NSGs
- **Application Insights** + **Log Analytics**
- **Managed Identity** for sikkerhet
- **Key Vault** integration

### ✅ Sample Application
- Node.js Express API
- PostgreSQL database integration
- Health check endpoints
- Klar for deployment

### ✅ CI/CD Workflows
- GitHub Actions for Terraform
- GitHub Actions for app deployment
- OIDC authentication (federated credentials)
- Automated testing og validation

### ✅ Dokumentasjon
- Detaljert README
- Quick Start Guide
- GitHub Actions setup guide
- Deployment checklist
- Troubleshooting tips

### ✅ Helper Scripts
- Setup script (automatisk konfigurasjon)
- Deploy script (forenklet deployment)
- Bash utilities

## 🚀 Kom i gang (3 metoder)

### Metode 1: Automatisk (Anbefalt) ⚡
```bash
# 1. Last ned og pakk ut prosjektet
cd azure-terraform-workshop

# 2. Kjør setup-scriptet
./scripts/setup.sh

# 3. Deploy
cd environments/dev
terraform apply
```
**Tid: ~5 minutter setup + 20 minutter deployment**

### Metode 2: Manuell 🔧
```bash
# 1. Konfigurer variabler
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Rediger terraform.tfvars med dine verdier

# 2. Konfigurer backend
# Rediger backend.tf med dine backend-verdier

# 3. Deploy
terraform init
terraform plan
terraform apply
```
**Tid: ~10 minutter setup + 20 minutter deployment**

### Metode 3: Med GitHub Actions 🤖
Se `docs/GITHUB_ACTIONS_SETUP.md` for komplett guide.

## 📊 Prosjektstruktur

```
azure-terraform-workshop/
│
├── README.md                    # Hovedoversikt
├── QUICKSTART.md               # Rask oppstartsguide
├── .gitignore                  # Git ignore rules
│
├── environments/               # Terraform environments
│   └── dev/
│       ├── main.tf            # Root module
│       ├── variables.tf       # Input variabler
│       ├── outputs.tf         # Output verdier
│       ├── backend.tf         # Remote state config
│       └── terraform.tfvars.example
│
├── modules/                    # Reusable Terraform modules
│   ├── networking/            # VNet, subnets, NSGs
│   ├── app-service/           # App Service Plan + Web App
│   ├── database/              # PostgreSQL Flexible Server
│   └── monitoring/            # App Insights + Log Analytics
│
├── sample-app/                # Sample Node.js application
│   ├── server.js             # Express server
│   ├── package.json          # Dependencies
│   └── README.md             # App documentation
│
├── scripts/                   # Helper scripts
│   ├── setup.sh              # Automated setup
│   └── deploy.sh             # Deployment helper
│
├── .github/
│   └── workflows/
│       ├── terraform.yml     # Terraform CI/CD
│       └── deploy-app.yml    # App deployment
│
└── docs/                      # Documentation
    ├── GITHUB_ACTIONS_SETUP.md
    └── DEPLOYMENT_CHECKLIST.md
```

## 🎯 Hva lærer studentene?

### Infrastructure as Code
- ✅ Terraform best practices
- ✅ Modulær arkitektur
- ✅ State management
- ✅ Variable management
- ✅ Output handling

### Azure Services
- ✅ App Service (PaaS)
- ✅ PostgreSQL Flexible Server
- ✅ Virtual Networks og private networking
- ✅ Managed Identity
- ✅ Key Vault
- ✅ Application Insights

### Security
- ✅ Private networking
- ✅ Network Security Groups
- ✅ Managed Identity (no credentials in code!)
- ✅ Key Vault for secrets
- ✅ OIDC authentication for CI/CD

### DevOps Practices
- ✅ CI/CD with GitHub Actions
- ✅ Infrastructure testing
- ✅ Automated deployments
- ✅ Environment management
- ✅ Monitoring and logging

## 📈 Progression Path

### Week 1-2: Basics
- Deploy infrastruktur lokalt
- Forstå Terraform syntax
- Lære Azure services
- Basic networking

### Week 3-4: Intermediate
- Implementer CI/CD
- Deploy sample app
- Legge til testing
- Multi-environment setup

### Week 5-6: Advanced
- Advanced networking
- Blue-Green deployments
- Automated testing with Terratest
- Cost optimization
- Security hardening

## 💰 Kostnadsestimat

**Dev/Test miljø (B-tier):**
- App Service Plan B1: ~400 NOK/måned
- PostgreSQL B1ms: ~150 NOK/måned
- VNet + NSGs: ~50 NOK/måned
- Application Insights: ~100 NOK/måned
- **Total: ~700 NOK/måned**

**Tips for kostnadsreduksjon:**
- Stopp ressurser når de ikke brukes
- Bruk auto-shutdown i dev/test
- Cleanup etter testing
- Monitor costs med Azure Cost Management

## 🔐 Sikkerhet - Best Practices

### ✅ Implementert
- Managed Identity (no hardcoded credentials)
- Private networking for database
- Network Security Groups
- Key Vault for secrets
- OIDC for CI/CD (no service principal keys)
- SSL/TLS enforcement
- Minimum TLS 1.2

### ⚠️ For Produksjon
- [ ] Azure Front Door + WAF
- [ ] DDoS Protection
- [ ] Azure Defender for Cloud
- [ ] Log retention og compliance
- [ ] Backup strategi
- [ ] Disaster recovery plan
- [ ] Regular security audits

## 🧪 Testing Capabilities

### Offline Testing (uten Azure resources)
```bash
terraform fmt -check
terraform validate
tflint
checkov
```

### Online Testing (med Azure resources)
```bash
# Deploy to test environment
terraform apply

# Run integration tests
# (kan utvides med Terratest)
```

### CI Pipeline Testing
- Automated validation
- Security scanning
- Plan verification
- Automated deployment to test env

## 📚 Nyttige Kommandoer

### Terraform
```bash
# Format all files
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan without applying
terraform plan -out=tfplan

# Show current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output app_service_url
```

### Azure CLI
```bash
# List resources
az resource list --resource-group <rg> -o table

# Check App Service status
az webapp show --name <app> --resource-group <rg>

# Test database connection
az postgres flexible-server connect --name <db> --admin-user <user>

# Get secrets from Key Vault
az keyvault secret show --vault-name <kv> --name <secret>

# View logs
az webapp log tail --name <app> --resource-group <rg>
```

### Quick Deploy Helper
```bash
cd environments/dev

# Using the helper script
../../scripts/deploy.sh plan
../../scripts/deploy.sh apply
../../scripts/deploy.sh output
```

## 🆘 Support og Troubleshooting

### Common Issues

**"Backend initialization required"**
→ Kjør `terraform init -reconfigure`

**"Insufficient permissions"**
→ Sjekk Contributor rolle på Resource Group

**"Resource already exists"**
→ Import ressurs eller endre navn

**"Database takes too long"**
→ Dette er normalt! PostgreSQL provisioning tar 10-15 min

### Getting Help
1. Sjekk `docs/DEPLOYMENT_CHECKLIST.md`
2. Les error messages nøye
3. Sjekk Azure Portal for resource status
4. Se på Terraform state: `terraform show`
5. Kontakt kursledelsen

## 📖 Ressurser

### Terraform
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### Azure
- [Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/)
- [PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/)
- [Azure Virtual Networks](https://learn.microsoft.com/en-us/azure/virtual-network/)

### GitHub Actions
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Azure OIDC with GitHub](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure)

### Books & Guides
- Infrastructure as Code by Kief Morris
- Terraform: Up & Running by Yevgeniy Brikman

## 🎓 Learning Outcomes

Etter å ha fullført dette prosjektet vil studentene kunne:

1. **Designe** og implementere cloud infrastruktur med Terraform
2. **Deploye** moderne web-applikasjoner til Azure
3. **Konfigurere** sikker networking med private endpoints
4. **Implementere** CI/CD pipelines med GitHub Actions
5. **Bruke** Managed Identity for sikker autentisering
6. **Integrere** Key Vault for secret management
7. **Sette opp** monitoring med Application Insights
8. **Forstå** Infrastructure as Code best practices
9. **Håndtere** multiple environments (dev/staging/prod)
10. **Debugge** og troubleshoote infrastruktur-problemer

## ✨ Neste Steg

### Utvidelser studentene kan gjøre:

1. **Networking**
   - Legg til Azure Front Door
   - Implementer custom domain + SSL
   - Legg til Azure Firewall

2. **Database**
   - Implementer read replicas
   - Legg til automated backups
   - Sett opp point-in-time restore

3. **Application**
   - Legg til Redis cache
   - Implementer Azure CDN
   - Legg til Azure Functions

4. **Security**
   - Implementer Azure AD authentication
   - Legg til Azure Key Vault for app secrets
   - Sett opp Private Link

5. **DevOps**
   - Legg til Terratest
   - Implementer automated rollback
   - Sett opp blue-green deployments

6. **Monitoring**
   - Avanserte Application Insights queries
   - Custom dashboards
   - Alert rules og action groups

## 🏆 Success Metrics

Prosjektet er vellykket når:
- ✅ Infrastruktur deployes uten feil
- ✅ App Service er tilgjengelig
- ✅ Database connectivity fungerer
- ✅ Monitoring data samles inn
- ✅ CI/CD pipeline kjører
- ✅ Secrets håndteres sikkert
- ✅ Deployment tid < 30 minutter
- ✅ Total kostnad < 1000 NOK/måned

## 🙏 Credits

Dette prosjektet er bygget med best practices fra:
- Terraform official documentation
- Azure Well-Architected Framework
- Infrastructure as Code by Kief Morris
- HashiCorp Learn tutorials
- Azure Architecture Center

---

## 🚀 Ready to Deploy?

1. Les `QUICKSTART.md` for rask start
2. Følg `docs/DEPLOYMENT_CHECKLIST.md` for sikker deployment
3. Se `docs/GITHUB_ACTIONS_SETUP.md` for CI/CD
4. Lykke til! 🎉

**Spørsmål?** Kontakt kursledelsen eller åpne et issue på GitHub.

---

**Version:** 1.0.0  
**Last Updated:** 2024  
**License:** MIT (for educational purposes)

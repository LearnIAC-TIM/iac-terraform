# Azure Terraform Workshop - App Service + Database

## 📋 Oversikt

Dette prosjektet deployer en komplett web-applikasjon infrastruktur i Azure med:
- **Azure App Service** (Linux) for web hosting
- **PostgreSQL Flexible Server** for database
- **Virtual Network** med private networking
- **Application Insights** for monitoring
- **Managed Identity** for sikkerhet

## 🏗️ Arkitektur

```
┌─────────────────────────────────────────────────────┐
│  Existing Resource Group (Student-RG)               │
│                                                      │
│  ├── Storage Account (Terraform State) ✓           │
│  ├── Key Vault (Secrets) ✓                         │
│  └── [Ny infrastruktur under her]                  │
│                                                      │
│      ┌──────────────────────────────────┐          │
│      │  Virtual Network                 │          │
│      │  ├── app-subnet                  │          │
│      │  └── db-subnet                   │          │
│      └──────────────────────────────────┘          │
│               │                                     │
│      ┌────────┴───────────┐                        │
│      │                    │                        │
│      ▼                    ▼                        │
│  ┌─────────┐      ┌──────────────┐                │
│  │App Service│    │  PostgreSQL   │                │
│  │  Plan    │      │   Flexible   │                │
│  └─────────┘      │   Server     │                │
│      │             └──────────────┘                │
│      ▼                                             │
│  ┌─────────┐                                       │
│  │ Web App │                                       │
│  │(Managed │                                       │
│  │Identity)│                                       │
│  └─────────┘                                       │
│      │                                             │
│      ▼                                             │
│  ┌──────────────┐                                  │
│  │ Application  │                                  │
│  │  Insights    │                                  │
│  └──────────────┘                                  │
└─────────────────────────────────────────────────────┘
```

## 📁 Prosjektstruktur

```
azure-terraform-workshop/
├── README.md
├── environments/
│   └── dev/
│       ├── main.tf              # Root module
│       ├── variables.tf         # Input variabler
│       ├── outputs.tf           # Output verdier
│       ├── terraform.tfvars     # Konkrete verdier (IKKE commit!)
│       └── backend.tf           # Remote state config
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── app-service/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── scripts/
    ├── setup.sh                 # Initial setup script
    └── deploy.sh                # Deployment helper
```

## 🚀 Kom i gang

### Forutsetninger

1. Azure CLI installert og innlogget
2. Terraform >= 1.5.0 installert
3. Tilgang til Azure subscription
4. Eksisterende ressurser:
   - Resource Group
   - Storage Account med container for state
   - Key Vault

### Steg 1: Konfigurer variabler

Kopier example-filen og fyll inn dine verdier:

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Rediger `terraform.tfvars` med dine verdier:
- subscription_id
- resource_group_name
- location
- etc.

### Steg 2: Konfigurer backend

Rediger `backend.tf` med dine backend-detaljer:
- storage_account_name
- container_name
- key (state file name)

### Steg 3: Initialize Terraform

```bash
terraform init
```

### Steg 4: Plan deployment

```bash
terraform plan -out=tfplan
```

### Steg 5: Apply changes

```bash
terraform apply tfplan
```

## 🔧 Konfigurasjon

### Viktige variabler

| Variabel | Beskrivelse | Eksempel |
|----------|-------------|----------|
| `project_name` | Prefix for alle ressurser | `student01` |
| `environment` | Miljø-navn | `dev` |
| `location` | Azure region | `norwayeast` |
| `app_service_sku` | App Service Plan size | `B1` |
| `database_sku` | PostgreSQL tier | `B_Standard_B1ms` |

### Støttede regioner

- `norwayeast` (Norge Øst - anbefalt)
- `norwaywest` (Norge Vest)
- `westeurope` (Vest-Europa)
- `northeurope` (Nord-Europa)

## 🧪 Testing

### Lokal validering
```bash
terraform fmt -check
terraform validate
```

### Plan uten apply
```bash
terraform plan
```

### Verifiser deployment
```bash
# Test database connectivity
az postgres flexible-server connect -n <server-name> -u <admin-user>

# Test web app
curl https://<app-name>.azurewebsites.net
```

## 🔐 Sikkerhet

- ✅ Managed Identity for App Service
- ✅ Private Endpoint for database
- ✅ Network Security Groups
- ✅ Secrets i Key Vault
- ✅ No hardcoded credentials

## 📊 Kostnader (estimat)

**Dev-miljø:**
- App Service Plan B1: ~400 NOK/måned
- PostgreSQL Flexible B1ms: ~150 NOK/måned
- Networking: ~50 NOK/måned
- **Total: ~600 NOK/måned**

💡 **Tips:** Stopp ressurser når de ikke brukes!

## 🧹 Cleanup

For å slette alle ressurser:

```bash
terraform destroy
```

**NB:** Dette sletter IKKE Resource Group, Storage Account eller Key Vault (eksisterende ressurser).

## 📚 Neste steg

1. ✅ Deploy basis-infrastruktur
2. 🔄 Legg til CI/CD med GitHub Actions
3. 🧪 Implementer automated testing
4. 📦 Deploy sample applikasjon
5. 📈 Sett opp advanced monitoring

## 🆘 Troubleshooting

### Problem: "Backend initialization required"
**Løsning:** Kjør `terraform init` på nytt

### Problem: "Insufficient permissions"
**Løsning:** Sjekk at du har Contributor-rolle på Resource Group

### Problem: "Resource already exists"
**Løsning:** Enten import eksisterende ressurs eller endre navn

## 📞 Support

For spørsmål, kontakt kursledelsen eller se dokumentasjon:
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/)
- [PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/)

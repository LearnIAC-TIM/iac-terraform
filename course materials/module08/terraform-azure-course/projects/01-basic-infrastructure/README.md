# 01-basic-infrastructure

Grunnleggende Azure infrastruktur med Resource Group, Storage Account og Storage Container.

## 📦 Ressurser som opprettes

- **Resource Group**: `rg-<student>-<env>`
- **Storage Account**: `st<student><env>`
- **Storage Container**: `data`

## 🎯 Læringsmål

- Forstå Terraform grunnleggende syntax
- Lære om Azure Provider konfigurasjon
- Jobbe med remote backend (Azure Storage)
- Utforske ressurs-avhengigheter
- Praktisere testing og validering

## 📋 Forutsetninger

- Azure CLI installert og innlogget
- Terraform >= 1.0 installert
- Tilgang til Azure subscription
- Backend storage account satt opp
- `shared/backend.hcl` konfigurert

## 🚀 Oppsett

### 1. Kopier terraform.tfvars fra template

```bash
cp terraform.tfvars.example terraform.tfvars
```

Rediger `terraform.tfvars` og fyll inn dine verdier:
```hcl
student_name = "ditt_studentnummer"
environment  = "dev"
location     = "norwayeast"
```

### 2. Initialiser Terraform med backend

```bash
terraform init -backend-config=../../shared/backend.hcl \
  -backend-config="key=01-basic-infrastructure/terraform.tfstate"
```

### 3. Valider konfigurasjon

```bash
# Format check
terraform fmt -check

# Syntaks validering
terraform validate
```

### 4. Planlegg deployment

```bash
terraform plan -out=tfplan
```

### 5. Deploy infrastruktur

```bash
terraform apply tfplan
```

### 6. Verifiser deployment

```bash
# Vis outputs
terraform output

# Sjekk i Azure Portal eller via CLI
az group show --name $(terraform output -raw resource_group_name)
az storage account show --name $(terraform output -raw storage_account_name)
```

## 🧪 Testing

### Static Testing

```bash
# Format
terraform fmt -check -recursive

# Validering
terraform validate

# Linting (krever tflint)
tflint --init
tflint
```

### Integration Testing

```bash
# Kjør integration tests
./test/integration_test.sh
```

### Drift Detection

```bash
# Sjekk for manuelle endringer
./test/drift_detection.sh
```

## 🔧 Vanlige kommandoer

```bash
# Se nåværende state
terraform show

# List ressurser
terraform state list

# Hent spesifikk output
terraform output resource_group_name

# Refresh state
terraform refresh

# Graph (krever graphviz)
terraform graph | dot -Tpng > graph.png
```

## 🧹 Opprydding

```bash
# Slett alle ressurser
terraform destroy -auto-approve

# Eller interaktivt
terraform destroy
```

## 📚 Utvidelser

Når du er komfortabel med grunnleggende oppsett, prøv å:

1. **Aktiver Key Vault**: Fjern kommentarer i `main.tf` for Key Vault ressursene
2. **Legg til flere ressurser**: 
   - Virtual Network
   - Network Security Group
   - App Service Plan
3. **Lag moduler**: Refaktorer koden til gjenbrukbare moduler
4. **Legg til flere miljøer**: Opprett `test` og `prod` miljøer

## 🐛 Troubleshooting

### Problem: Backend init feiler

```bash
# Sjekk backend konfigurasjon
cat ../../shared/backend.hcl

# Verifiser at storage account eksisterer
az storage account show --name <STORAGE_ACCOUNT_NAME>
```

### Problem: Naming conflicts

Storage account navn må være unike globalt. Hvis du får feilmelding om at navnet er tatt:

```hcl
# I terraform.tfvars - legg til et unikt suffix
student_name = "student01xyz"
```

### Problem: Authentication issues

```bash
# Re-login til Azure
az login

# Sjekk nåværende subscription
az account show

# Bytt subscription hvis nødvendig
az account set --subscription <SUBSCRIPTION_ID>
```

## 📖 Neste steg

Når du er ferdig med dette prosjektet, gå videre til:
- `02-with-modules` - Lær om Terraform moduler
- `03-testing-example` - Avansert testing med Terratest

## 💡 Tips

- Bruk `terraform plan` ofte før du kjører `apply`
- Commit kode ofte til Git (men ikke `terraform.tfvars` eller `backend.hcl`)
- Dokumenter endringer i commit messages
- Eksperimenter i `dev` miljø først
- Bruk `terraform fmt` før hver commit

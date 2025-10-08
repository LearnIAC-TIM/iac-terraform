# Simple Terraform - Build Once, Deploy Many Demo

Dette prosjektet demonstrerer "Build Once, Deploy Many" prinsippet med Terraform og Azure.

## 🎯 Konsept

**Build Once, Deploy Many** betyr:
- Bygg artifact ÉN gang
- Deploy SAMME artifact til flere miljøer
- Garantert konsistens mellom miljøer

## 📁 Struktur

```
simple-terraform/
├── terraform/          # Terraform kode (felles)
├── environments/       # Miljø-spesifikk config
├── backend-configs/    # Backend config per miljø
└── scripts/           # Build og deploy scripts
```

## 🚀 Lokal Testing

### Forutsetninger
- Terraform >= 1.5.0
- Azure CLI
- Git (for versjonering)

### Steg 1: Bygg Artifact

```bash
./scripts/build.sh
```

Dette oppretter: `terraform-<version>.tar.gz`

### Steg 2: Deploy til Dev

```bash
./scripts/deploy.sh dev terraform-<version>.tar.gz
```

### Steg 3: Deploy SAMME Artifact til Test

```bash
./scripts/deploy.sh test terraform-<version>.tar.gz
```

## 🔍 Verifiser Build Once, Deploy Many

```bash
# Sammenlign lock files (skal være identiske!)
diff workspace-dev/terraform/.terraform.lock.hcl \
     workspace-test/terraform/.terraform.lock.hcl

# Ingen output = success! ✅
```

## ☁️ GitHub Actions

Pipeline kjører automatisk ved push til main:
1. **Build** - Lager artifact
2. **Deploy Dev** - Deployer til dev
3. **Deploy Test** - Deployer SAMME artifact til test

## 🧹 Cleanup

**Linux/Mac:**
```bash
./scripts/cleanup.sh dev terraform-<version>.tar.gz
```


## 📚 Læringsmål

- ✅ Forstå Build Once, Deploy Many
- ✅ Se forskjellen på artifact og deployment
- ✅ Håndtere miljø-spesifikk konfigurasjon
- ✅ Verifisere konsistens mellom miljøer

## 🎓 Neste Steg

Del 2: Artifact Storage i Azure og eksisterende infrastruktur

# Testing Strategi

## Test-nivåer

### 1. Offline Tests ⚡
- **Formål:** Rask validering uten Azure
- **Tid:** ~10 sekunder
- **Tester:** Terraform syntaks, sikkerhet, JSON
- **Kostnader:** $0

### 2. Static Analysis 🔍
- **Formål:** Policy compliance
- **Tid:** ~30 sekunder
- **Tester:** Terraform plan, policies
- **Kostnader:** ~$0.01

### 3. Online Verification ✅
- **Formål:** Verifiser infrastruktur
- **Tid:** ~2 minutter
- **Tester:** Ressurser, konfigurasjon
- **Kostnader:** ~$0.05

### 4. Online Outcome 🎯
- **Formål:** E2E testing
- **Tid:** ~5 minutter
- **Tester:** Health checks, swap, funksjonalitet
- **Kostnader:** ~$0.10

## Test-pyramide

```
           ┌─────────────┐
           │   Outcome   │  ← Få, trege
           └─────┬───────┘
                 │
         ┌───────▼────────┐
         │ Verification   │
         └───────┬────────┘
                 │
        ┌────────▼─────────┐
        │ Static Analysis  │
        └────────┬─────────┘
                 │
     ┌───────────▼──────────┐
     │  Offline Tests       │  ← Mange, raske
     └──────────────────────┘
```

## Best Practices

### DO ✅
- Kjør offline tests før hver commit
- Automatiser alt i CI/CD
- Test rollback prosedyrer
- Monitorér test-kvalitet

### DON'T ❌
- Hopp over raske tester
- Deploy uten verification
- Ignorer feilede tester
- Hardcode credentials

## Metrics

Mål disse:
- Test execution time
- Test failure rate
- Deployment frequency
- MTTR (Mean Time To Recovery)

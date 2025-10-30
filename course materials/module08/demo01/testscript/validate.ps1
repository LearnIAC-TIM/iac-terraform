## Validate.ps1
# PowerShell script to validate Terraform code using multiple tools

Write-Host "🔍 Running Terraform validation..." -ForegroundColor Blue
Write-Host ""

# 1. Terraform Format
Write-Host "📝 Checking Terraform formatting..." -ForegroundColor Cyan
terraform fmt -check -recursive
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Run 'terraform fmt -recursive' to fix formatting" -ForegroundColor Red
}

# 2. Terraform Validate
Write-Host "`n✅ Running terraform validate..." -ForegroundColor Cyan
terraform validate

# 3. TFLint
Write-Host "`n🔎 Running TFLint..." -ForegroundColor Cyan
tflint --init
tflint

# 4. Checkov
Write-Host "`n🛡️  Running Checkov..." -ForegroundColor Cyan
checkov -d . --compact

Write-Host "`n✅ Validation complete!" -ForegroundColor Green
# Parametere
param(
    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$TfvarsFilePath,
    
    [Parameter(Mandatory=$true)]
    [string]$SecretName
)

# Les hele filen som tekst
$fileContent = Get-Content -Path $TfvarsFilePath -Raw

# Lagre til Key Vault
az keyvault secret set `
    --vault-name $KeyVaultName `
    --name $SecretName `
    --value $fileContent

Write-Host "✓ Hele filen '$TfvarsFilePath' er lagret som secret '$SecretName' i Key Vault '$KeyVaultName'"
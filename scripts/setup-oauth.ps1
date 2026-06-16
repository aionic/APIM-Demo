#!/usr/bin/env pwsh
<#
.SYNOPSIS
Set up Entra ID OAuth for APIM developer portal.

.DESCRIPTION
Creates an Entra app registration with APIM redirect URIs,
generates a client secret, and updates variables.tf with credentials.

.EXAMPLE
pwsh .\scripts\setup-oauth.ps1
#>

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Set-Location $repo

Write-Host "=== Entra OAuth Setup for APIM ===" -ForegroundColor Cyan

# Retrieve current APIM gateway URL
Write-Host "`n1. Checking for existing APIM deployment..."
$gateway = terraform output -raw apim_gateway_url 2>/dev/null || $null
if (-not $gateway) {
  Write-Host "⚠️  No APIM deployed yet. Run 'terraform apply' first." -ForegroundColor Yellow
  exit 1
}
Write-Host "✓ Gateway: $gateway" -ForegroundColor Green

# Create a new app registration
Write-Host "`n2. Creating Entra app registration..."
$appId = az ad app create `
  --display-name "APIM-Demo-OAuth" `
  --web-redirect-uris `
    "$gateway/oauth/signin" `
    "$gateway/developer" `
    "http://localhost:3000" `
  --sign-in-audience "AzureADMyOrg" `
  --query appId -o tsv
Write-Host "✓ Created: $appId" -ForegroundColor Green

# Create client secret
Write-Host "`n3. Creating client secret..."
$secretJson = az ad app credential reset --id $appId --years 1 -o json | ConvertFrom-Json
$clientSecret = $secretJson.password
Write-Host "✓ Secret generated (length: $($clientSecret.Length))" -ForegroundColor Green

# Write local tfvars instead of editing source variables
Write-Host "`n4. Updating local tfvars..."
$envDir = Join-Path $repo "env"
$tfvarsPath = Join-Path $envDir "demo.auto.tfvars"
@"
location            = "westus3"
demo_name           = "apim-demo"
publisher_email     = "demo-admin@contoso.example"
publisher_name      = "Contoso Demo"
apim_sku_name       = "StandardV2"
tenant_id           = "$(az account show --query tenantId -o tsv)"
entra_client_id     = "$appId"
entra_client_secret = "$clientSecret"
"@ | Set-Content $tfvarsPath
Write-Host "✓ Wrote $tfvarsPath" -ForegroundColor Green

Write-Host "`n✅ OAuth setup complete!" -ForegroundColor Green
Write-Host "`nNext steps:"
Write-Host "  1. terraform validate"
Write-Host "  2. terraform apply"
Write-Host "  3. Open the developer portal and sign in with your Entra ID credentials"

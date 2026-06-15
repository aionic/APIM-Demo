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

# Check for existing Entra app
Write-Host "`n2. Checking for existing Entra app registration..."
$existingAppId = terraform output -raw entra_app_id 2>/dev/null || $null
if ($existingAppId -and $existingAppId -ne "00000000-0000-0000-0000-000000000000") {
  Write-Host "✓ Existing app found: $existingAppId" -ForegroundColor Green
  $appId = $existingAppId
} else {
  Write-Host "   Creating new app registration..."
  $appJson = az ad app create `
    --display-name "APIM-Demo-OAuth" `
    --web-redirect-uris `
      "$gateway/oauth/signin" `
      "$gateway/developer" `
      "http://localhost:3000" `
    --query "{appId: appId}" -o json
  $appId = $appJson | ConvertFrom-Json | Select-Object -ExpandProperty appId
  Write-Host "✓ Created: $appId" -ForegroundColor Green
}

# Create/reset client secret
Write-Host "`n3. Creating client secret..."
try {
  $secretJson = az ad sp credential reset --id $appId --query "{clientSecret: password}" -o json 2>/dev/null
  $clientSecret = $secretJson | ConvertFrom-Json | Select-Object -ExpandProperty clientSecret
} catch {
  # If SP doesn't exist, create it first
  Write-Host "   Creating service principal..."
  az ad sp create --id $appId 2>/dev/null | Out-Null
  $secretJson = az ad sp credential reset --id $appId --query "{clientSecret: password}" -o json
  $clientSecret = $secretJson | ConvertFrom-Json | Select-Object -ExpandProperty clientSecret
}
Write-Host "✓ Secret generated (length: $($clientSecret.Length))" -ForegroundColor Green

# Update variables.tf
Write-Host "`n4. Updating variables.tf..."
$varContent = Get-Content variables.tf -Raw

# Replace entra_client_id
$varContent = $varContent -replace `
  '(variable "entra_client_id".*?default\s*=\s*)"[^"]*"', `
  "`$1`"$appId`""

# Replace entra_client_secret
$varContent = $varContent -replace `
  '(variable "entra_client_secret".*?default\s*=\s*)"[^"]*"', `
  "`$1`"$clientSecret`""

$varContent | Set-Content variables.tf
Write-Host "✓ variables.tf updated" -ForegroundColor Green

Write-Host "`n✅ OAuth setup complete!" -ForegroundColor Green
Write-Host "`nNext steps:"
Write-Host "  1. terraform validate"
Write-Host "  2. terraform apply"
Write-Host "  3. Visit the developer portal and sign in with your Entra ID credentials"

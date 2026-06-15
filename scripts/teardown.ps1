#!/usr/bin/env pwsh
<#
.SYNOPSIS
Destroy APIM demo infrastructure and clean up resources.

.DESCRIPTION
Safely tears down the entire APIM demo environment via Terraform.
Requires confirmation before proceeding with destruction.
#>

param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot

Set-Location $repo

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║     APIM DEMO INFRASTRUCTURE TEARDOWN  ║" -ForegroundColor Red
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Red

if (-not $Force) {
  Write-Host ""
  Write-Host "⚠️  This will PERMANENTLY DELETE:" -ForegroundColor Yellow
  Write-Host "  • API Management instance"
  Write-Host "  • Log Analytics workspace (all telemetry data)"
  Write-Host "  • Key Vault and secrets"
  Write-Host "  • Cognitive Services account"
  Write-Host "  • Container instances (Grafana)"
  Write-Host "  • Resource group: $(terraform output -raw resource_group_name)"
  Write-Host ""
  
  $confirmation = Read-Host "Type 'destroy' to confirm and proceed"
  if ($confirmation -ne "destroy") {
    Write-Host "Aborted." -ForegroundColor Green
    exit 0
  }
}

Write-Host ""
Write-Host "🔄 Destroying infrastructure..." -ForegroundColor Cyan
terraform destroy -auto-approve

Write-Host ""
Write-Host "✅ Teardown complete!" -ForegroundColor Green
Write-Host "All resources have been deleted."

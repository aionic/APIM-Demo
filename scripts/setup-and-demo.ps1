param(
  [int]$BurstIterations = 30,
  [int]$BurstDelayMs = 250
)

$ErrorActionPreference = "Stop"

# Ensure we're in the repo root
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repo

Write-Host "=== Getting public IP ===" -ForegroundColor Cyan
$publicIp = curl.exe -s https://ifconfig.me
Write-Host "Your public IP: $publicIp" -ForegroundColor Green

Write-Host "`n=== Applying Terraform with your IP ===" -ForegroundColor Cyan
terraform apply `
  -var "allowed_ip_addresses=[`"$publicIp`"]" `
  -auto-approve `
  -input=false

Write-Host "`n=== Retrieving APIM gateway and subscription details ===" -ForegroundColor Cyan
$gateway = terraform output -raw apim_gateway_url
$subKey = terraform output -json subscription_keys | ConvertFrom-Json
$primaryKey = $subKey."demo-subscription".primary_key

Write-Host "Gateway URL: $gateway" -ForegroundColor Green
Write-Host "Subscription Key: $($primaryKey.Substring(0, 8))***" -ForegroundColor Green

Write-Host "`n=== Running smoke test ===" -ForegroundColor Cyan
pwsh .\scripts\invoke-apim-smoke.ps1 -GatewayUrl $gateway -SubscriptionKey $primaryKey

Write-Host "`n=== Running burst telemetry test ===" -ForegroundColor Cyan
pwsh .\scripts\invoke-apim-telemetry-burst.ps1 `
  -GatewayUrl $gateway `
  -SubscriptionKey $primaryKey `
  -Iterations $BurstIterations `
  -DelayMs $BurstDelayMs

Write-Host "`n=== Telemetry generation complete ===" -ForegroundColor Green
Write-Host "Check Log Analytics: https://portal.azure.com/#@microsoft.com/resource/subscriptions/05322c41-8e40-4575-9bc7-4509758926fb/resourceGroups/apim-demo-rg/providers/microsoft.operationalinsights/workspaces/apimdemolawsf41" -ForegroundColor Cyan

# APIM Telemetry Demo Walkthrough

This walkthrough uses the scripts in `scripts\` to generate APIM traffic, then shows how to view it in Azure Monitor / Log Analytics.

## 1) Prerequisites

- Azure CLI logged in to the target subscription
- PowerShell 7
- APIM gateway URL and subscription key
- Log Analytics workspace name

```powershell
$GatewayUrl = "https://apimdemo-apim-sf41.azure-api.net"
$SubscriptionKey = "<apim-subscription-primary-key>"
$WorkspaceRg = "apim-demo-rg"
$WorkspaceName = "apimdemolawsf41"
```

## 2) Generate telemetry

Run a quick smoke test:

```powershell
pwsh .\scripts\invoke-apim-smoke.ps1 `
  -GatewayUrl $GatewayUrl `
  -SubscriptionKey $SubscriptionKey
```

Run a burst load to generate a larger telemetry sample:

```powershell
pwsh .\scripts\invoke-apim-telemetry-burst.ps1 `
  -GatewayUrl $GatewayUrl `
  -SubscriptionKey $SubscriptionKey `
  -Iterations 60 `
  -DelayMs 250
```

## 3) Query telemetry from Log Analytics (CLI)

Get workspace customer ID:

```powershell
$WorkspaceId = az monitor log-analytics workspace show `
  --resource-group $WorkspaceRg `
  --workspace-name $WorkspaceName `
  --query customerId -o tsv
```

### 3.1 Discover which APIM table is populated

```powershell
$q = @'
search *
| where TimeGenerated > ago(30m)
| summarize Count=count() by $table
| order by Count desc
'@
az monitor log-analytics query --workspace $WorkspaceId --analytics-query $q --timespan P1D -o table
```

### 3.2 APIM request volume and status codes (works across table shapes)

```powershell
$q = @'
union isfuzzy=true AzureDiagnostics, ApiManagementGatewayLogs
| where TimeGenerated > ago(30m)
| where ResourceProvider == 'MICROSOFT.APIMANAGEMENT' or _ResourceId contains '/providers/Microsoft.ApiManagement/service/'
| extend Status=coalesce(
    tostring(column_ifexists('ResponseCode','')),
    tostring(column_ifexists('httpStatusCode_d','')),
    tostring(column_ifexists('responseCode_d','')),
    tostring(column_ifexists('responseCode_s',''))
  )
| summarize Requests=count() by Status, bin(TimeGenerated, 5m)
| order by TimeGenerated asc
'@
az monitor log-analytics query --workspace $WorkspaceId --analytics-query $q --timespan P1D -o table
```

### 3.3 Top API operations

```powershell
$q = @'
union isfuzzy=true AzureDiagnostics, ApiManagementGatewayLogs
| where TimeGenerated > ago(30m)
| where ResourceProvider == 'MICROSOFT.APIMANAGEMENT' or _ResourceId contains '/providers/Microsoft.ApiManagement/service/'
| extend ApiPath=coalesce(
    tostring(column_ifexists('requestUri_s','')),
    tostring(column_ifexists('Url','')),
    tostring(column_ifexists('RequestUrl','')),
    tostring(column_ifexists('operationName_s',''))
  )
| summarize Requests=count() by ApiPath
| top 20 by Requests desc
'@
az monitor log-analytics query --workspace $WorkspaceId --analytics-query $q --timespan P1D -o table
```

## 4) Query telemetry in Azure Portal

1. Open **Azure Portal** -> **API Management** -> your APIM instance.
2. Go to **Monitoring** -> **Logs**.
3. Run either of these:

```kusto
search *
| where TimeGenerated > ago(30m)
| where _ResourceId contains "/providers/Microsoft.ApiManagement/service/"
| summarize Count=count() by $table
| order by Count desc
```

```kusto
union isfuzzy=true AzureDiagnostics, ApiManagementGatewayLogs
| where TimeGenerated > ago(30m)
| where ResourceProvider == "MICROSOFT.APIMANAGEMENT" or _ResourceId contains "/providers/Microsoft.ApiManagement/service/"
| summarize Requests=count() by tostring(coalesce(httpStatusCode_d, ResponseCode, responseCode_d, responseCode_s)), bin(TimeGenerated, 5m)
| order by TimeGenerated asc
```

## 5) Notes

- APIM diagnostics ingestion can lag by a few minutes; if no data appears immediately, rerun the query window for 30-60 minutes.
- This repo config enables `GatewayLogs`, `WebSocketConnectionLogs`, and `DeveloperPortalAuditLogs` to Log Analytics.
- If APIM IP filtering blocks your source address, requests can return `403` and still produce useful telemetry for the demo.

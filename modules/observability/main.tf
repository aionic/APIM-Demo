resource "azurerm_resource_group_template_deployment" "apim_monitor_workbook" {
  name                = "apim-monitor-workbook"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  template_spec_version_id = null
  template_content = jsonencode({
    "$schema"        = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    "contentVersion" = "1.0.0.0"
    "parameters" = {
      "workbookDisplayName" = {
        "type"         = "string"
        "defaultValue" = "APIM Demo Dashboard"
      }
      "workbookSourceId" = {
        "type"         = "string"
        "defaultValue" = var.log_analytics_workspace_id
      }
    }
    "resources" = [
      {
        "type"       = "Microsoft.Insights/workbooks"
        "apiVersion" = "2021-03-08"
        "name"       = "[guid(parameters('workbookSourceId'))]"
        "location"   = var.location
        "kind"       = "shared"
        "properties" = {
          "displayName" = "[parameters('workbookDisplayName')]"
          "serializedData" = jsonencode({
            "version" = "Notebook/1.0"
            "items" = [
              {
                "type"    = 1
                "content" = "# APIM Demo Monitoring Dashboard"
                "name"    = "text - Title"
              },
              {
                "type" = 3
                "content" = {
                  "version" = "KqlItem/1.0"
                  "query"   = "ApiManagementGatewayLogs\n| summarize Requests=count(), Errors=sumif(1, ResponseCode >= 400), AvgLatency=avg(Duration) by bin(TimeGenerated, 5m)\n| render timechart"
                  "timeContext" = {
                    "durationMs" = 3600000
                  }
                }
                "name" = "chart - Request Timeline"
              },
              {
                "type" = 3
                "content" = {
                  "version" = "KqlItem/1.0"
                  "query"   = "ApiManagementGatewayLogs\n| summarize count() by ResponseCode\n| render columnchart"
                }
                "name" = "chart - Status Codes"
              },
              {
                "type" = 3
                "content" = {
                  "version" = "KqlItem/1.0"
                  "query"   = "ApiManagementGatewayLogs\n| summarize Requests=count(), AvgLatency=avg(Duration) by tostring(ApiId)\n| sort by Requests desc"
                }
                "name" = "table - API Performance"
              }
            ]
          })
          "sourceId" = "[parameters('workbookSourceId')]"
          "category" = "workbook"
        }
      }
    ]
  })
}

resource "azurerm_dashboard_grafana" "this" {
  name                              = var.grafana_name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  grafana_major_version             = 12
  api_key_enabled                   = false
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "grafana_law_reader" {
  scope                = var.log_analytics_workspace_id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
}

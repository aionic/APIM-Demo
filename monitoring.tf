# Azure Monitor Workbook for APIM dashboard
resource "azurerm_resource_group_template_deployment" "apim_monitor_workbook" {
  name                = "apim-monitor-workbook"
  resource_group_name = azurerm_resource_group.this.name
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
        "defaultValue" = azurerm_log_analytics_workspace.this.id
      }
    }
    "resources" = [
      {
        "type"       = "Microsoft.Insights/workbooks"
        "apiVersion" = "2021-03-08"
        "name"       = "[guid(parameters('workbookSourceId'))]"
        "location"   = azurerm_resource_group.this.location
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

# Grafana container instance
resource "azurerm_container_group" "grafana" {
  name                = "${local.name_prefix}-grafana-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "${local.name_prefix}-grafana-${random_string.suffix.result}"

  container {
    name   = "grafana"
    image  = "grafana/grafana:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 3000
      protocol = "TCP"
    }

    environment_variables = {
      "GF_SECURITY_ADMIN_PASSWORD" = random_password.grafana_admin.result
      "GF_USERS_ALLOW_SIGN_UP"     = "false"
    }
  }

  tags = local.tags
}

resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

# Key Vault secret for Grafana admin password
resource "azurerm_key_vault_secret" "grafana_admin_password" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "grafana-admin-password"
  value        = random_password.grafana_admin.result

  depends_on = [azurerm_key_vault_access_policy.deployer]
}




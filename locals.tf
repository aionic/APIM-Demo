locals {
  name_prefix = lower(replace(replace(replace(var.demo_name, "-", ""), "_", ""), " ", ""))

  resource_group_name  = "${var.demo_name}-rg"
  apim_name            = substr("${local.name_prefix}-apim-${random_string.suffix.result}", 0, 50)
  key_vault_name       = substr("${local.name_prefix}kv${random_string.suffix.result}", 0, 24)
  log_analytics_name   = substr("${local.name_prefix}law${random_string.suffix.result}", 0, 63)
  storage_account_name = substr("${local.name_prefix}st${random_string.suffix.result}", 0, 24)
  ai_service_name      = substr("${local.name_prefix}ais${random_string.suffix.result}", 0, 24)
  ai_hub_name          = substr("${local.name_prefix}hub${random_string.suffix.result}", 0, 64)
  ai_project_name      = substr("${local.name_prefix}proj${random_string.suffix.result}", 0, 64)
  apim_is_v2_sku       = strcontains(var.apim_sku_name, "V2_")

  tags = {
    environment = "demo"
    workload    = "apim-platform"
    owner       = "customer-demo"
  }

  global_policy = <<-XML
<policies>
 <inbound>
   <ip-filter action="allow">
${join("\n", [for ip in var.allowed_ip_addresses : "      <address>${ip}</address>"])}
   </ip-filter>
   <set-header name="x-correlation-id" exists-action="override">
     <value>@(Guid.NewGuid().ToString())</value>
   </set-header>
   <trace source="apim-demo" severity="information">@(string.Format("client={0}; subscription={1}; path={2}", context.Request.IpAddress, context.Subscription?.Id ?? "anonymous", context.Request.Url.Path))</trace>
 </inbound>
 <backend />
 <outbound />
 <on-error />
</policies>
XML

 api_policy = <<-XML
<policies>
 <inbound>
   <base />
   <set-header name="x-demo-secret" exists-action="override">
     <value>{{DemoSecret}}</value>
   </set-header>
    <set-header name="x-demo-source" exists-action="override">
      <value>apim-demo</value>
    </set-header>
    <trace source="apim-demo-api" severity="information">@(string.Format("api={0}; client={1}; secret-present={2}", "${var.demo_name}", context.Request.IpAddress, !string.IsNullOrWhiteSpace("{{DemoSecret}}")))</trace>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML

  apis = {
    weather = {
      display_name          = "Weather API"
      path                  = "weather"
      protocols             = ["https"]
      revision              = "1"
      description           = "Public weather sample imported from Open-Meteo"
      subscription_required = true
      service_url           = "https://api.open-meteo.com/v1"
      import = {
        content_format = "openapi"
        content_value  = file("${path.module}/specs/weather.yaml")
      }
      policy = {
        xml_content = local.api_policy
      }
    }
    time = {
      display_name          = "Time API"
      path                  = "time"
      protocols             = ["https"]
      revision              = "1"
      description           = "Public time sample imported from WorldTimeAPI"
      subscription_required = true
      service_url           = "https://worldtimeapi.org/api"
      import = {
        content_format = "openapi"
        content_value  = file("${path.module}/specs/time.yaml")
      }
      policy = {
        xml_content = local.api_policy
      }
    }
    echo = {
      display_name          = "Echo API"
      path                  = "echo"
      protocols             = ["https"]
      revision              = "1"
      description           = "Echo endpoint to demonstrate tracing and caller IP"
      subscription_required = true
      service_url           = "https://postman-echo.com"
      import = {
        content_format = "openapi"
        content_value  = file("${path.module}/specs/echo.yaml")
      }
      policy = {
        xml_content = local.api_policy
      }
    }
    llm = {
      display_name          = "AI Gateway API"
      path                  = "llm"
      protocols             = ["https"]
      revision              = "1"
      description           = "Foundry/OpenAI-style gateway placeholder for the AI demo path"
      subscription_required = true
      service_url           = azurerm_cognitive_account.this.endpoint
      import = {
        content_format = "openapi"
        content_value  = file("${path.module}/specs/llm.yaml")
      }
      policy = {
        xml_content = local.api_policy
      }
    }
  }
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

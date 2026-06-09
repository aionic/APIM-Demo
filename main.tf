data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = local.resource_group_name
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = local.log_analytics_name
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_key_vault" "this" {
  location                        = azurerm_resource_group.this.location
  name                            = local.key_vault_name
  resource_group_name             = azurerm_resource_group.this.name
  sku_name                        = "standard"
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false
  soft_delete_retention_days      = 7
  tags                            = local.tags
}

resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.this.id
  object_id    = data.azurerm_client_config.current.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
  ]
}

resource "azurerm_key_vault_secret" "demo" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "demo-secret"
  value        = "demo-secret-value-${random_string.suffix.result}"
  content_type = "text/plain"

  depends_on = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_role_assignment" "apim_keyvault_access" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.apim.workspace_identity.principal_id
}

resource "azurerm_cognitive_account" "this" {
  name                          = local.ai_service_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  kind                          = "OpenAI"
  sku_name                      = "S0"
  custom_subdomain_name         = local.ai_service_name
  public_network_access_enabled = true
  local_auth_enabled            = false
  tags                          = local.tags
}

resource "azurerm_role_assignment" "apim_ai_user" {
  scope                = azurerm_cognitive_account.this.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = module.apim.workspace_identity.principal_id
}

resource "azurerm_role_assignment" "current_user_apim_service_contributor" {
  scope                = module.apim.resource_id
  role_definition_name = "API Management Service Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_api_management_authorization_server" "entra" {
  name                = "entra-oauth-demo"
  api_management_name = module.apim.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "Microsoft Identity OAuth"
  description         = "Entra ID authorization server for the APIM demo"

  authorization_endpoint       = "https://login.microsoftonline.com/${coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)}/oauth2/v2.0/authorize"
  client_registration_endpoint = "https://login.microsoftonline.com/${coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)}/oauth2/v2.0/register"
  token_endpoint               = "https://login.microsoftonline.com/${coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)}/oauth2/v2.0/token"
  client_id                    = var.entra_client_id
  client_secret                = var.entra_client_secret
  grant_types                  = ["authorizationCode", "implicit"]
  authorization_methods        = ["GET"]
  bearer_token_sending_methods = ["authorizationHeader"]
  support_state                = true
  default_scope                = "openid profile offline_access"

  depends_on = [module.apim]
}

resource "azurerm_api_management_identity_provider_aad" "entra" {
  api_management_name = module.apim.name
  resource_group_name = azurerm_resource_group.this.name
  client_id           = var.entra_client_id
  client_secret       = var.entra_client_secret
  allowed_tenants     = [coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)]
  signin_tenant       = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)

  depends_on = [module.apim]
}

resource "azapi_resource" "apim_portal_setting_signin" {
  count     = local.apim_is_v2_sku ? 0 : 1
  type      = "Microsoft.ApiManagement/service/portalsettings@2022-08-01"
  name      = "signin"
  parent_id = module.apim.resource_id
  body = {
    properties = {
      enabled = true
    }
  }

  depends_on = [module.apim]
}

resource "azapi_resource" "apim_portal_setting_signup" {
  count     = local.apim_is_v2_sku ? 0 : 1
  type      = "Microsoft.ApiManagement/service/portalsettings@2022-08-01"
  name      = "signup"
  parent_id = module.apim.resource_id
  body = {
    properties = {
      enabled = true
      termsOfService = {
        enabled         = false
        consentRequired = false
        text            = ""
      }
    }
  }

  depends_on = [module.apim]
}

resource "azapi_resource" "apim_portal_revision_published" {
  count     = local.apim_is_v2_sku ? 0 : 1
  type      = "Microsoft.ApiManagement/service/portalRevisions@2022-08-01"
  name      = "terraform-published"
  parent_id = module.apim.resource_id
  body = {
    properties = {
      description = "Developer portal published by Terraform"
      isCurrent   = true
    }
  }

  depends_on = [
    azapi_resource.apim_portal_setting_signin,
    azapi_resource.apim_portal_setting_signup
  ]
}

module "apim" {
  source  = "Azure/avm-res-apimanagement-service/azurerm"
  version = ">= 0.9.0, < 1.0"

  location            = azurerm_resource_group.this.location
  name                = local.apim_name
  publisher_email     = var.publisher_email
  publisher_name      = var.publisher_name
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = var.apim_sku_name
  tags                = local.tags
  managed_identities = {
    system_assigned = true
  }
  public_network_access_enabled = true
  security                      = {}
  diagnostic_settings = {
    apim = {
      name                  = "apim-demo-diag"
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
      log_categories        = ["GatewayLogs", "WebSocketConnectionLogs", "DeveloperPortalAuditLogs"]
      metric_categories     = ["AllMetrics"]
    }
  }
  named_values = {
    "DemoSecret" = {
      display_name = "DemoSecret"
      secret       = true
      value        = azurerm_key_vault_secret.demo.value
    }
    "WeatherBaseUrl" = {
      display_name = "WeatherBaseUrl"
      value        = "https://api.open-meteo.com/v1"
      tags         = ["demo", "external"]
    }
    "TimeBaseUrl" = {
      display_name = "TimeBaseUrl"
      value        = "https://worldtimeapi.org/api"
      tags         = ["demo", "external"]
    }
    "EchoBaseUrl" = {
      display_name = "EchoBaseUrl"
      value        = "https://postman-echo.com"
      tags         = ["demo", "external"]
    }
  }
  apis = local.apis
  products = {
    demo = {
      display_name          = "Demo Product"
      description           = "Starter product for the APIM migration demo"
      subscription_required = true
      approval_required     = false
      state                 = "published"
      api_names             = ["weather", "time", "echo", "llm"]
      group_names           = ["developers"]
    }
  }
  subscriptions = {
    demo-subscription = {
      display_name     = "Demo Subscription"
      scope_type       = "product"
      scope_identifier = "demo"
      state            = "active"
      allow_tracing    = true
    }
  }
}

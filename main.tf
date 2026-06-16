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
  principal_id         = azapi_resource.apim.output.identity.principalId
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
  principal_id         = azapi_resource.apim.output.identity.principalId
}

resource "azurerm_role_assignment" "current_user_apim_service_contributor" {
  scope                = azapi_resource.apim.id
  role_definition_name = "API Management Service Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_api_management_authorization_server" "entra" {
  name                = "entra-oauth-demo"
  api_management_name = azapi_resource.apim.name
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

  depends_on = [azapi_resource.apim]
}

resource "azurerm_api_management_identity_provider_aad" "entra" {
  api_management_name = azapi_resource.apim.name
  resource_group_name = azurerm_resource_group.this.name
  client_id           = var.entra_client_id
  client_secret       = var.entra_client_secret
  allowed_tenants     = [coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)]
  signin_tenant       = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)

  depends_on = [azapi_resource.apim]
}

resource "azapi_resource" "apim_portal_setting_signin" {
  count     = local.apim_is_v2_sku ? 0 : 1
  type      = "Microsoft.ApiManagement/service/portalsettings@2022-08-01"
  name      = "signin"
  parent_id = azapi_resource.apim.id
  body = {
    properties = {
      enabled = true
    }
  }

  depends_on = [azapi_resource.apim]
}

resource "azapi_resource" "apim_portal_setting_signup" {
  count     = local.apim_is_v2_sku ? 0 : 1
  type      = "Microsoft.ApiManagement/service/portalsettings@2022-08-01"
  name      = "signup"
  parent_id = azapi_resource.apim.id
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

  depends_on = [azapi_resource.apim]
}

resource "azapi_resource" "apim_portal_revision_published" {
  count     = local.apim_is_v2_sku ? 0 : 1
  type      = "Microsoft.ApiManagement/service/portalRevisions@2022-08-01"
  name      = "terraform-published"
  parent_id = azapi_resource.apim.id
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

resource "azapi_resource" "apim" {
  type      = "Microsoft.ApiManagement/service@2024-05-01"
  name      = local.apim_name
  parent_id = azurerm_resource_group.this.id
  location  = azurerm_resource_group.this.location
  tags      = local.tags

  identity {
    type = "SystemAssigned"
  }

  schema_validation_enabled = false
  response_export_values    = ["identity.principalId"]

  body = {
    sku = {
      name     = var.apim_sku_name
      capacity = 1
    }
    properties = {
      publisherEmail        = var.publisher_email
      publisherName         = var.publisher_name
      publicNetworkAccess   = "Enabled"
      developerPortalStatus = "Enabled"
      legacyPortalStatus    = "Disabled"
      virtualNetworkType    = "None"
    }
  }
}

resource "azurerm_api_management_policy" "global" {
  api_management_id = azapi_resource.apim.id
  xml_content       = local.global_policy

  depends_on = [azapi_resource.apim]
}

resource "azurerm_api_management_named_value" "this" {
  for_each = local.named_values

  api_management_name = azapi_resource.apim.name
  display_name        = each.value.display_name
  name                = each.key
  resource_group_name = azurerm_resource_group.this.name
  secret              = each.value.secret
  tags                = each.value.tags
  value               = each.value.value

  depends_on = [azapi_resource.apim]
}

resource "azurerm_api_management_api" "this" {
  for_each = local.apis

  api_management_name   = azapi_resource.apim.name
  name                  = each.key
  resource_group_name   = azurerm_resource_group.this.name
  revision              = each.value.revision
  description           = each.value.description
  display_name          = each.value.display_name
  path                  = each.value.path
  protocols             = each.value.protocols
  revision_description  = try(each.value.revision_description, null)
  service_url           = each.value.service_url
  source_api_id         = try(each.value.source_api_id, null)
  subscription_required = each.value.subscription_required
  terms_of_service_url  = try(each.value.terms_of_service_url, null)
  version               = try(each.value.api_version, null)

  dynamic "import" {
    for_each = each.value.import != null ? [each.value.import] : []

    content {
      content_format = import.value.content_format
      content_value  = import.value.content_value
    }
  }

  depends_on = [azapi_resource.apim]
}

resource "azurerm_api_management_api_policy" "this" {
  for_each = { for k, v in local.apis : k => v if v.policy != null }

  api_management_name = azapi_resource.apim.name
  api_name            = azurerm_api_management_api.this[each.key].name
  resource_group_name = azurerm_resource_group.this.name
  xml_content         = each.value.policy.xml_content
  xml_link            = try(each.value.policy.xml_link, null)

  depends_on = [azurerm_api_management_api.this]
}

resource "azurerm_api_management_product" "this" {
  for_each = local.products

  api_management_name   = azapi_resource.apim.name
  display_name          = each.value.display_name
  product_id            = each.key
  published             = each.value.state == "published"
  resource_group_name   = azurerm_resource_group.this.name
  approval_required     = each.value.approval_required
  description           = each.value.description
  subscription_required = each.value.subscription_required
  subscriptions_limit   = each.value.subscriptions_limit
  terms                 = each.value.terms

  depends_on = [azapi_resource.apim]
}

locals {
  product_api_associations = flatten([
    for product_key, product in local.products : [
      for api_name in product.api_names : {
        product_key = product_key
        api_name    = api_name
        key         = "${product_key}-${api_name}"
      }
    ]
  ])

  product_group_associations = flatten([
    for product_key, product in local.products : [
      for group_name in product.group_names : {
        product_key = product_key
        group_name  = group_name
        key         = "${product_key}-${group_name}"
      }
    ]
  ])
}

resource "azurerm_api_management_product_group" "this" {
  for_each = {
    for assoc in local.product_group_associations : assoc.key => assoc
  }

  api_management_name = azapi_resource.apim.name
  group_name          = each.value.group_name
  product_id          = azurerm_api_management_product.this[each.value.product_key].product_id
  resource_group_name = azurerm_resource_group.this.name

  depends_on = [azurerm_api_management_product.this]
}

resource "azurerm_api_management_product_api" "this" {
  for_each = {
    for assoc in local.product_api_associations : assoc.key => assoc
  }

  api_management_name = azapi_resource.apim.name
  api_name            = azurerm_api_management_api.this[each.value.api_name].name
  product_id          = azurerm_api_management_product.this[each.value.product_key].product_id
  resource_group_name = azurerm_resource_group.this.name

  depends_on = [
    azurerm_api_management_product.this,
    azurerm_api_management_api.this
  ]
}

resource "azurerm_api_management_subscription" "this" {
  for_each = local.subscriptions

  api_management_name = azapi_resource.apim.name
  display_name        = each.value.display_name
  resource_group_name = azurerm_resource_group.this.name
  allow_tracing       = each.value.allow_tracing
  api_id              = each.value.scope_type == "api" ? azurerm_api_management_api.this[each.value.scope_identifier].id : null
  primary_key         = each.value.primary_key
  product_id          = each.value.scope_type == "product" ? azurerm_api_management_product.this[each.value.scope_identifier].id : null
  secondary_key       = each.value.secondary_key
  state               = each.value.state
  subscription_id     = each.key
  user_id             = each.value.user_id

  depends_on = [
    azapi_resource.apim,
    azurerm_api_management_product.this,
    azurerm_api_management_api.this
  ]
}

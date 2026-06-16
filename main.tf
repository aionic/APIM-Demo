data "azurerm_client_config" "current" {}

module "platform" {
  source = "./modules/platform"

  location            = var.location
  resource_group_name = local.resource_group_name
  log_analytics_name  = local.log_analytics_name
  key_vault_name      = local.key_vault_name
  ai_service_name     = local.ai_service_name
  tags                = local.tags
  tenant_id           = data.azurerm_client_config.current.tenant_id
  deployer_object_id  = data.azurerm_client_config.current.object_id
  demo_secret_value   = "demo-secret-value-${random_string.suffix.result}"
}

module "apim" {
  source = "./modules/apim"

  resource_group_name        = module.platform.resource_group_name
  location                   = module.platform.location
  apim_name                  = local.apim_name
  tags                       = local.tags
  apim_sku_name              = var.apim_sku_name
  apim_is_v2_sku             = local.apim_is_v2_sku
  publisher_email            = var.publisher_email
  publisher_name             = var.publisher_name
  tenant_id                  = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
  entra_client_id            = var.entra_client_id
  entra_client_secret        = var.entra_client_secret
  named_values               = local.named_values
  apis                       = local.apis
  products                   = local.products
  subscriptions              = local.subscriptions
  global_policy              = local.global_policy
  log_analytics_workspace_id = module.platform.log_analytics_workspace_id
  key_vault_id               = module.platform.key_vault_id
  cognitive_account_id       = module.platform.cognitive_account_id
  current_user_object_id     = data.azurerm_client_config.current.object_id
}

module "observability" {
  source = "./modules/observability"

  resource_group_name        = module.platform.resource_group_name
  location                   = module.platform.location
  log_analytics_workspace_id = module.platform.log_analytics_workspace_id
  grafana_name               = "${local.name_prefix}-grafana-${random_string.suffix.result}"
  tags                       = local.tags
}

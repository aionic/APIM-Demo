resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = var.log_analytics_name
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_key_vault" "this" {
  location                        = azurerm_resource_group.this.location
  name                            = var.key_vault_name
  resource_group_name             = azurerm_resource_group.this.name
  sku_name                        = "standard"
  tenant_id                       = var.tenant_id
  public_network_access_enabled   = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false
  soft_delete_retention_days      = 7
  tags                            = var.tags
}

resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.this.id
  object_id    = var.deployer_object_id
  tenant_id    = var.tenant_id

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
  value        = var.demo_secret_value
  content_type = "text/plain"

  depends_on = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_cognitive_account" "this" {
  name                          = var.ai_service_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  kind                          = "OpenAI"
  sku_name                      = "S0"
  custom_subdomain_name         = var.ai_service_name
  public_network_access_enabled = true
  local_auth_enabled            = false
  tags                          = var.tags
}

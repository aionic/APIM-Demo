resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

resource "azurerm_key_vault_secret" "grafana_admin_password" {
  key_vault_id = module.platform.key_vault_id
  name         = "grafana-admin-password"
  value        = random_password.grafana_admin.result
}

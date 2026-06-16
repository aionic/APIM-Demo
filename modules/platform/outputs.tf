output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.this.name
}

output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "demo_secret_value" {
  value     = azurerm_key_vault_secret.demo.value
  sensitive = true
}

output "cognitive_account_id" {
  value = azurerm_cognitive_account.this.id
}

output "cognitive_account_endpoint" {
  value = azurerm_cognitive_account.this.endpoint
}

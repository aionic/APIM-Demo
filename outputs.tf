output "apim_gateway_url" {
  description = "APIM gateway URL"
  value       = module.apim.apim_gateway_url
}

output "apim_portal_url" {
  description = "APIM developer portal URL"
  value       = "${module.apim.apim_gateway_url}/developer"
}

output "subscription_keys" {
  description = "APIM subscription keys for demo product"
  sensitive   = true
  value       = module.apim.subscription_keys
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.this.name
}

output "workspace_name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.this.name
}

output "kv_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.this.name
}

output "grafana_dns" {
  description = "Grafana container DNS name"
  value       = try(azurerm_container_group.grafana.fqdn, null)
}

output "grafana_admin_password_secret" {
  description = "Key Vault secret name for Grafana admin password"
  value       = azurerm_key_vault_secret.grafana_admin_password.name
}

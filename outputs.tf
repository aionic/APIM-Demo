output "apim_gateway_url" {
  description = "APIM gateway URL"
  value       = "https://${module.apim.apim_name}.azure-api.net"
}

output "apim_portal_url" {
  description = "APIM developer portal URL"
  value       = "https://${module.apim.apim_name}.azure-api.net/developer"
}

output "subscription_keys" {
  description = "APIM subscription keys for demo product"
  sensitive   = true
  value       = module.apim.subscription_keys
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.platform.resource_group_name
}

output "workspace_name" {
  description = "Log Analytics workspace name"
  value       = module.platform.log_analytics_workspace_name
}

output "kv_name" {
  description = "Key Vault name"
  value       = module.platform.key_vault_name
}

output "grafana_url" {
  description = "Azure Managed Grafana endpoint"
  value       = module.observability.grafana_endpoint
}

output "grafana_name" {
  description = "Azure Managed Grafana resource name"
  value       = module.observability.grafana_name
}

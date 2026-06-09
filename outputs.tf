output "apim_gateway_url" {
  description = "APIM gateway URL"
  value       = module.apim.apim_gateway_url
}

output "apim_portal_url" {
  description = "APIM developer portal URL (if enabled)"
  value       = module.apim.portal_url
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

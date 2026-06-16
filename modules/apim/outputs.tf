output "apim_id" {
  value = azapi_resource.apim.id
}

output "apim_name" {
  value = azapi_resource.apim.name
}

output "subscription_keys" {
  sensitive = true
  value = {
    for key, sub in azurerm_api_management_subscription.this : key => {
      primary_key   = sub.primary_key
      secondary_key = sub.secondary_key
    }
  }
}

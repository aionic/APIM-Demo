moved {
  from = azurerm_resource_group.this
  to   = module.platform.azurerm_resource_group.this
}

moved {
  from = azurerm_log_analytics_workspace.this
  to   = module.platform.azurerm_log_analytics_workspace.this
}

moved {
  from = azurerm_key_vault.this
  to   = module.platform.azurerm_key_vault.this
}

moved {
  from = azurerm_key_vault_access_policy.deployer
  to   = module.platform.azurerm_key_vault_access_policy.deployer
}

moved {
  from = azurerm_key_vault_secret.demo
  to   = module.platform.azurerm_key_vault_secret.demo
}

moved {
  from = azurerm_cognitive_account.this
  to   = module.platform.azurerm_cognitive_account.this
}

moved {
  from = azapi_resource.apim
  to   = module.apim.azapi_resource.apim
}

moved {
  from = azurerm_role_assignment.apim_keyvault_access
  to   = module.apim.azurerm_role_assignment.apim_keyvault_access
}

moved {
  from = azurerm_role_assignment.apim_ai_user
  to   = module.apim.azurerm_role_assignment.apim_ai_user
}

moved {
  from = azurerm_role_assignment.current_user_apim_service_contributor
  to   = module.apim.azurerm_role_assignment.current_user_apim_service_contributor
}

moved {
  from = azurerm_api_management_authorization_server.entra
  to   = module.apim.azurerm_api_management_authorization_server.entra
}

moved {
  from = azurerm_api_management_identity_provider_aad.entra
  to   = module.apim.azurerm_api_management_identity_provider_aad.entra
}

moved {
  from = azurerm_api_management_policy.global
  to   = module.apim.azurerm_api_management_policy.global
}

moved {
  from = azurerm_api_management_named_value.this["DemoSecret"]
  to   = module.apim.azurerm_api_management_named_value.this["DemoSecret"]
}

moved {
  from = azurerm_api_management_named_value.this["EchoBaseUrl"]
  to   = module.apim.azurerm_api_management_named_value.this["EchoBaseUrl"]
}

moved {
  from = azurerm_api_management_named_value.this["TimeBaseUrl"]
  to   = module.apim.azurerm_api_management_named_value.this["TimeBaseUrl"]
}

moved {
  from = azurerm_api_management_named_value.this["WeatherBaseUrl"]
  to   = module.apim.azurerm_api_management_named_value.this["WeatherBaseUrl"]
}

moved {
  from = azurerm_api_management_api.this["echo"]
  to   = module.apim.azurerm_api_management_api.this["echo"]
}

moved {
  from = azurerm_api_management_api.this["llm"]
  to   = module.apim.azurerm_api_management_api.this["llm"]
}

moved {
  from = azurerm_api_management_api.this["time"]
  to   = module.apim.azurerm_api_management_api.this["time"]
}

moved {
  from = azurerm_api_management_api.this["weather"]
  to   = module.apim.azurerm_api_management_api.this["weather"]
}

moved {
  from = azurerm_api_management_api_policy.this["echo"]
  to   = module.apim.azurerm_api_management_api_policy.this["echo"]
}

moved {
  from = azurerm_api_management_api_policy.this["llm"]
  to   = module.apim.azurerm_api_management_api_policy.this["llm"]
}

moved {
  from = azurerm_api_management_api_policy.this["time"]
  to   = module.apim.azurerm_api_management_api_policy.this["time"]
}

moved {
  from = azurerm_api_management_api_policy.this["weather"]
  to   = module.apim.azurerm_api_management_api_policy.this["weather"]
}

moved {
  from = azurerm_api_management_product.this["demo"]
  to   = module.apim.azurerm_api_management_product.this["demo"]
}

moved {
  from = azurerm_api_management_product_api.this["demo-echo"]
  to   = module.apim.azurerm_api_management_product_api.this["demo-echo"]
}

moved {
  from = azurerm_api_management_product_api.this["demo-llm"]
  to   = module.apim.azurerm_api_management_product_api.this["demo-llm"]
}

moved {
  from = azurerm_api_management_product_api.this["demo-time"]
  to   = module.apim.azurerm_api_management_product_api.this["demo-time"]
}

moved {
  from = azurerm_api_management_product_api.this["demo-weather"]
  to   = module.apim.azurerm_api_management_product_api.this["demo-weather"]
}

moved {
  from = azurerm_api_management_product_group.this["demo-developers"]
  to   = module.apim.azurerm_api_management_product_group.this["demo-developers"]
}

moved {
  from = azurerm_api_management_subscription.this["demo-subscription"]
  to   = module.apim.azurerm_api_management_subscription.this["demo-subscription"]
}

moved {
  from = azurerm_resource_group_template_deployment.apim_monitor_workbook
  to   = module.observability.azurerm_resource_group_template_deployment.apim_monitor_workbook
}

output "grafana_endpoint" {
  value = azurerm_dashboard_grafana.this.endpoint
}

output "grafana_name" {
  value = azurerm_dashboard_grafana.this.name
}

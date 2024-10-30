output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log-workspace.id
}
output "log_analytics_primary_key" {
  value = azurerm_log_analytics_workspace.log-workspace.primary_shared_key
}
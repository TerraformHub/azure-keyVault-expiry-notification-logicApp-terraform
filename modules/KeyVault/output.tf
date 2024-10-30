output "keyvault_id" {
  value = azurerm_key_vault.backend-keyvault.id
}
output "keyvault_name" {
  value = azurerm_key_vault.backend-keyvault.name
}
output "frontend_keyvault_id" {
  value = azurerm_key_vault.frontend-keyvault.id
}
output "frontend_keyvault_name" {
  value = azurerm_key_vault.frontend-keyvault.name
}
output "keyvault_uri" {
  value = azurerm_key_vault.backend-keyvault.vault_uri
}
output "frontend_keyvault_uri" {
  value = azurerm_key_vault.frontend-keyvault.vault_uri
}
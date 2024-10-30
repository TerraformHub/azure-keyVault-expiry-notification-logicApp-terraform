output "acs_id" {
  value = azurerm_communication_service.acs.id
}
output "acs_connection_string" {
  value = azurerm_communication_service.acs.primary_connection_string
}
output "acs_email" {
  value = "DoNotReply@${azurerm_email_communication_service_domain.acs-domain.from_sender_domain}"
}
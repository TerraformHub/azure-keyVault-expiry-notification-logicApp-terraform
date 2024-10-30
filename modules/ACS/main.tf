data "azurerm_client_config" "current" {}

## ACS (Azure Communication Service)
resource "azurerm_communication_service" "acs" {
  name                = "${var.prefix}-acs"
  resource_group_name = var.resource_group_name
  data_location       = "United States"
  tags                = var.tags
}

## Azure Email Communication Service
resource "azurerm_email_communication_service" "email" {
  name                = "${var.prefix}-acs-email-service"
  resource_group_name = var.resource_group_name
  data_location       = "United States"
}

## ACS Azure Managed Domain
resource "azurerm_email_communication_service_domain" "acs-domain" {
  name              = "AzureManagedDomain"
  email_service_id  = azurerm_email_communication_service.email.id
  domain_management = "AzureManaged"
}

resource "azapi_update_resource" "acs-to-email" {
  type        = "Microsoft.Communication/communicationServices@2022-07-01-preview"
  resource_id = azurerm_communication_service.acs.id

  body = jsonencode({
    properties = {
      linkedDomains = [
        "${azurerm_email_communication_service_domain.acs-domain.id}"
      ]
    }
  })
}

data "azurerm_client_config" "current" {}

## KeyVault
resource "azurerm_key_vault" "keyvault" {
  name                        = "${var.prefix}-vault"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = true
  soft_delete_retention_days  = 15
  sku_name                    = "standard"
  tags                        = var.tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions         = ["Get", ]
    secret_permissions      = ["Get", "Set", "List", "Delete", "Purge"]
    certificate_permissions = ["Get", "Create", "List", "Delete", "Purge"]
  }

  lifecycle {
    ignore_changes = [access_policy]
  }
}

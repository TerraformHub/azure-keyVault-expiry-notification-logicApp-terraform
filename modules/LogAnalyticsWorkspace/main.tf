## Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log-workspace" {
  name                = "${var.prefix}-log-analytics-workspace"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

## Action Group
resource "azurerm_monitor_action_group" "action-grp" {
  name                = "${var.prefix}-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "alertgrp"
  dynamic "email_receiver" {
    for_each = var.action_grp_member
    content {
      name                    = "${element(split("@", email_receiver.value), 0)}-email"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
  tags = var.tags
}

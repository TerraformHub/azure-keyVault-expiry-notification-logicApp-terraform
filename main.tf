locals {
  tags = {
    "Resource Owner" = "DrStrange",
    "Business Unit"  = "Testing"
  }
}

module "logicapp" {
  source                     = "./modules/LogicApp"
  prefix                     = var.prefix
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tags                       = local.tags
  keyvault_id                = module.keyvault.keyvault_id
  keyvault_name              = module.keyvault.keyvault_name
  keyvault_uri               = module.keyvault.keyvault_uri
  acs_email                  = module.acs.acs_email
  acs_connection_string      = module.acs.acs_connection_string
  action_grp_member          = var.action_grp_member
  log_analytics_workspace_id = module.workspace.log_analytics_workspace_id
  log_connection_string      = module.workspace.log_analytics_primary_key
}

module "keyvault" {
  source              = "./modules/KeyVault"
  prefix              = var.prefix
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.tags
}

module "workspace" {
  source              = "./modules/LogAnalyticsWorkspace"
  prefix              = var.prefix
  location            = var.location
  tags                = local.tags
  resource_group_name = var.resource_group_name
  action_grp_member   = var.action_grp_member
}

module "acs" {
  source              = "./modules/ACS"
  prefix              = var.prefix
  location            = var.location
  tags                = local.tags
  resource_group_name = var.resource_group_name
}

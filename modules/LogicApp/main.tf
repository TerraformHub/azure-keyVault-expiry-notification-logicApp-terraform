locals {
  vault_names = concat([var.keyvault_name], [var.frontend_keyvault_name])
  recipients  = [for email in var.action_grp_member : { address = email }]
}

data "azurerm_client_config" "current" {}

## Managed APIs
data "azurerm_managed_api" "keyvault_managed_api" {
  name     = "keyvault"
  location = var.location
}
data "azurerm_managed_api" "acs_managed_api" {
  name     = "acsemail"
  location = var.location
}
data "azurerm_managed_api" "log_managed_api" {
  name     = "azureloganalyticsdatacollector"
  location = var.location
}

## Logic App
resource "azurerm_logic_app_workflow" "logic-app" {
  name                = "${var.prefix}-secretExpiration-logicApp"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  workflow_parameters = {
    "$connections" = jsonencode(
      {
        defaultValue = {}
        type         = "Object"
      }
    )
  }

  parameters = {
    "$connections" = jsonencode({
      "keyvault" : {
        "connectionId"   = azurerm_api_connection.vault_api.id
        "connectionName" = azurerm_api_connection.vault_api.name
        "id"             = azurerm_api_connection.vault_api.managed_api_id
      }
      "frontend-keyvault" : {
        "connectionId"   = azurerm_api_connection.frontend_vault_api.id
        "connectionName" = azurerm_api_connection.frontend_vault_api.name
        "id"             = azurerm_api_connection.frontend_vault_api.managed_api_id
      }
      "acsemail" : {
        "connectionId"   = azurerm_api_connection.acs_api.id
        "connectionName" = azurerm_api_connection.acs_api.name
        "id"             = azurerm_api_connection.acs_api.managed_api_id
      }
      "azureloganalyticsdatacollector" : {
        "connectionId"   = azurerm_api_connection.loganalytics_api.id
        "connectionName" = azurerm_api_connection.loganalytics_api.name
        "id"             = azurerm_api_connection.loganalytics_api.managed_api_id
      }
    })
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azuread_application_registration" "example" {
  display_name = "keyvault-client-secret"
}

resource "azuread_application_password" "app-password" {
  application_id = azuread_application_registration.example.id
}

## API Connection: KeyVault
resource "azurerm_api_connection" "vault_api" {
  name                = "${var.keyvault_name}-api-connection"
  resource_group_name = var.resource_group_name
  managed_api_id      = data.azurerm_managed_api.keyvault_managed_api.id
  display_name        = var.keyvault_name
  tags                = var.tags

  parameter_values = {
    vaultName            = var.keyvault_name
    "token:clientId"     = azuread_application_password.app-password.application_id
    "token:TenantId"     = data.azurerm_client_config.current.tenant_id
    "token:grantType"    = "client_credentials"
    "token:clientSecret" = azuread_application_password.app-password.value
    "token:ResourceUri"  = var.keyvault_uri
  }
  lifecycle {
    ignore_changes = [parameter_values]
  }
}

## API Connection: Frontend KeyVault
resource "azurerm_api_connection" "frontend_vault_api" {
  name                = "${var.frontend_keyvault_name}-api-connection"
  resource_group_name = var.resource_group_name
  managed_api_id      = data.azurerm_managed_api.keyvault_managed_api.id
  display_name        = var.frontend_keyvault_name
  tags                = var.tags

  parameter_values = {
    vaultName            = var.frontend_keyvault_name
    "token:clientId"     = azuread_application_password.app-password.application_id
    "token:TenantId"     = data.azurerm_client_config.current.tenant_id
    "token:grantType"    = "client_credentials"
    "token:clientSecret" = azuread_application_password.app-password.value
    "token:ResourceUri"  = var.frontend_keyvault_uri
  }
  lifecycle {
    ignore_changes = [parameter_values]
  }
}

## API Connection: ACS
resource "azurerm_api_connection" "acs_api" {
  name                = "acs-api-connection"
  resource_group_name = var.resource_group_name
  managed_api_id      = data.azurerm_managed_api.acs_managed_api.id
  display_name        = "acs-api-connection"
  tags                = var.tags

  parameter_values = {
    api_key = var.acs_connection_string
  }
  lifecycle {
    ignore_changes = [parameter_values]
  }
}

## API Connection: Log Analytics
resource "azurerm_api_connection" "loganalytics_api" {
  name                = "logAnalytics-api-connection"
  resource_group_name = var.resource_group_name
  managed_api_id      = data.azurerm_managed_api.log_managed_api.id
  display_name        = "logAnalytics-api-connection"
  tags                = var.tags

  parameter_values = {
    username = var.log_analytics_workspace_id
    password = var.log_connection_string
  }
  lifecycle {
    ignore_changes = [parameter_values]
  }
}

## Logic App trigger
resource "azurerm_logic_app_trigger_recurrence" "trigger" {
  name         = "Recurrence"
  logic_app_id = azurerm_logic_app_workflow.logic-app.id
  frequency    = "Hour"
  interval     = 24
}

## KeyVault API Connection Stage
resource "azurerm_logic_app_action_custom" "vault_action" {
  name         = var.keyvault_name
  logic_app_id = azurerm_logic_app_workflow.logic-app.id
  body         = <<BODY
    {
    "type": "ApiConnection",
    "inputs": {
      "host": {
        "connection": {
          "name": "@parameters('$connections')['keyvault']['connectionId']"
        }
      },
      "method": "get",
      "path": "/secrets"
    },
    "runAfter": {}
  }
  BODY
}

## Frontend API Connection Stage
resource "azurerm_logic_app_action_custom" "frontend_action" {
  name         = var.frontend_keyvault_name
  logic_app_id = azurerm_logic_app_workflow.logic-app.id
  body         = <<BODY
    {
  "type": "ApiConnection",
  "inputs": {
    "host": {
      "connection": {
        "name": "@parameters('$connections')['frontend-keyvault']['connectionId']"
      }
    },
    "method": "get",
    "path": "/secrets"
  },
  "runAfter": {}
}
  BODY
}

resource "azurerm_logic_app_action_custom" "loop_action" {
  for_each     = toset(local.vault_names)
  name         = "${each.value}-loop"
  logic_app_id = azurerm_logic_app_workflow.logic-app.id
  body         = <<BODY
  {
  "type": "Foreach",
  "foreach": "@body('${each.value}')?['value']",
  "actions": {
    "Condition-${each.value}": {
      "type": "If",
      "expression": {
        "and": [
          {
            "greaterOrEquals": [
              "@outputs('Current-Date-${each.value}')",
              "@outputs('SecretNearExpiry-${each.value}')"
            ]
          }
        ]
      },
      "actions": {
        "Send-Data-${each.value}": {
          "type": "ApiConnection",
          "inputs": {
            "host": {
              "connection": {
                "name": "@parameters('$connections')['azureloganalyticsdatacollector']['connectionId']"
              }
            },
            "method": "post",
            "body": "{\n\"Secret Name\":\"@{outputs('Secret-List-${each.value}')?['name']}\",\n\"Expiry date\":\"@{outputs('Expiry-Date-${each.value}')}\",\n\"KeyVault Name\":\"${each.value}\"\n}",
            "headers": {
              "Log-Type": "KeyVaultSecretExpiry"
            },
            "path": "/api/logs"
          }
        },
        "Send-email-${each.value}": {
          "type": "ApiConnection",
          "inputs": {
            "host": {
              "connection": {
                "name": "@parameters('$connections')['acsemail']['connectionId']"
              }
            },
            "method": "post",
            "body": {
              "senderAddress": "${var.acs_email}",
              "recipients": {
                "to": ${jsonencode(local.recipients)}
              },
              "content": {
                "subject": "Secret Expiration",
                "html": "<h1 class=\"editor-heading-h1\">Key Vault Secret Expiration Notice<br><br></h1><p class=\"editor-paragraph\">This is a notification that the following secret in the Azure Key Vault is nearing its expiration date. Please take the necessary actions to renew or replace it.</p><p class=\"editor-paragraph\">Details of the Expiring Secret:</p><h4 class=\"editor-heading-h4\"><ul class=\"editor-list-ul\"><li class=\"editor-listitem\">Key Vault Name:<b><strong class=\"editor-text-bold\"> ${each.value} </strong></b></li><li class=\"editor-listitem\">Secret Name:<b><strong class=\"editor-text-bold\"> </strong></b>@{outputs('Secret-List-${each.value}')?['name']}</li><li class=\"editor-listitem\">Expiration Date:<b><strong class=\"editor-text-bold\"> </strong></b>@{outputs('Expiry-Date-${each.value}')}<br></li></ul></h4><p class=\"editor-paragraph\">Thank you for your attention to this matter.</p>"
              },
              "importance": "Normal"
            },
            "path": "/emails:sendGAVersion",
            "queries": {
              "api-version": "2023-03-31"
            }
          }
        }
      },
      "else": {
        "actions": {}
      },
      "runAfter": {
        "SecretNearExpiry-${each.value}": [
          "Succeeded"
        ]
      }
    },
    "Current-Date-${each.value}": {
      "type": "Compose",
      "inputs": "@convertFromUtc(formatDateTime(utcNow()),'India Standard Time','yyyy-MM-dd')",
      "runAfter": {
        "Expiry-Date-${each.value}": [
          "Succeeded"
        ]
      }
    },
    "Expiry-Date-${each.value}": {
      "type": "Compose",
      "inputs": "@convertTimeZone(outputs('Secret-List-${each.value}')?['validityEndTime'],'UTC','India Standard Time','yyyy-MM-dd')",
      "runAfter": {
        "Secret-list-${each.value}": [
          "Succeeded"
        ]
      }
    },
    "SecretNearExpiry-${each.value}": {
      "type": "Compose",
      "inputs": "@formatDateTime(subtractFromTime(outputs('Expiry-Date-${each.value}'),30,'Day'),'yyyy-MM-dd')",
      "runAfter": {
        "Current-Date-${each.value}": [
          "Succeeded"
        ]
      }
    },
    "Secret-list-${each.value}": {
      "type": "Compose",
      "inputs": "@items('${each.value}-loop')"
    }
  },
  "runAfter": {
    "${each.value}": [
      "Succeeded"
    ]
  }
}
  BODY
}

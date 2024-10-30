terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "1.13.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.1.0"
    }
  }
}
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "your-subscription-id"
}
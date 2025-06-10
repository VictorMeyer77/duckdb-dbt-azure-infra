terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.30.0"
    }
  }
}

data "azurerm_client_config" "current" {}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.deploy_client_id
  client_secret   = var.deploy_client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.project}-rg"
  location = var.resource_group_location
  tags     = var.tags
}


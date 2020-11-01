terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    resource_group_name = "tf-remote-state-rg"
    storage_account_name = "bptfremotestate"
    container_name = "la-manage-az-infra-tf"
    key = "terrafor.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "tf-la-learn-rg"
  location = "westeurope"

  tags = {
    "provider"    = "Linux Academy"
    "environment" = "development"
  }
}

resource "azurerm_storage_account" "sa" {
  name                     = "bptflalearnsa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    "provider"    = "Linux Academy"
    "environment" = "development"
  }
}

resource "azurerm_storage_container" "container" {
  name                  = "myblobs"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_share" "share" {
  name                 = "myfileshare"
  storage_account_name = azurerm_storage_account.sa.name
  quota = 1
}

resource "azurerm_storage_share_directory" "directory" {
  name                 = "mydirectory"
  share_name           = azurerm_storage_share.share.name
  storage_account_name = azurerm_storage_account.sa.name
}
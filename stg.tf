provider "azurerm" {
  version = "= 2.0.0"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name = "tf-rg"
  location = "centralus"
}

resource "azurerm_storage_account" "this" {
  name                     = "mystorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  account_kind             = "StorageV2"

  tags = {
  environment = "dev"
  }
}






resource "azurerm_storage_account" "storage" {
  name                       = "${var.environment}${var.project}sto"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  account_tier               = "Standard"
  account_replication_type   = "ZRS"
  is_hns_enabled             = "true"
  access_tier                = "Hot"
  https_traffic_only_enabled = true
  tags                       = var.tags
}

resource "azurerm_storage_container" "container" {
  for_each              = toset(var.containers)
  name                  = each.key
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}
resource "azurerm_data_factory" "adf" {
  name                            = "${var.environment}${var.project}adf"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  managed_virtual_network_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}


resource "azurerm_data_factory_pipeline" "pipeline_books" {
  name            = "StartContainerBooks"
  data_factory_id = azurerm_data_factory.adf.id
  description     = "Call webhook to start ACI books automation."
  folder          = "Books"
  activities_json = <<JSON
[
  {
      "name": "WebHookCall",
      "type": "WebHook",
      "dependsOn": [],
      "policy": {
          "secureOutput": false,
          "secureInput": false
      },
      "userProperties": [],
      "typeProperties": {
          "url": "${azurerm_automation_webhook.run_container.uri}",
          "method": "POST",
          "timeout": "00:10:00",
          "reportStatusOnCallBack": true,
          "body": {}
      }
  }
]
  JSON
}
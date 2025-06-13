resource "azurerm_log_analytics_workspace" "log" {
  name                = "${var.environment}${var.project}log"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Automation

resource "azurerm_monitor_diagnostic_setting" "aut_log" {
  name                       = "${var.environment}${var.project}logaut"
  target_resource_id         = azurerm_automation_account.aut.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id

  enabled_log {
    category = "JobLogs"
  }

  enabled_log {
    category = "JobStreams"
  }

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
  }

}

# Data Factory

resource "azurerm_monitor_diagnostic_setting" "adf_log" {
  name                       = "${var.environment}${var.project}logadf"
  target_resource_id         = azurerm_data_factory.adf.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id

  enabled_log {
    category = "ActivityRuns"
  }

  enabled_log {
    category = "PipelineRuns"
  }

  enabled_log {
    category = "TriggerRuns"
  }

  metric {
    category = "AllMetrics"
  }

}

# Container Registry

resource "azurerm_monitor_diagnostic_setting" "acr_log" {
  name                       = "${var.environment}${var.project}logacr"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  metric {
    category = "AllMetrics"
  }

}
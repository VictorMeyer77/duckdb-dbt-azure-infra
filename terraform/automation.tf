resource "azurerm_automation_account" "aut" {
  name                = "${var.environment}${var.project}aut"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}


resource "azurerm_automation_runbook" "container" {
  name                    = "container"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aut.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Start and stop an azure container instances."
  runbook_type            = "PowerShell"
  content                 = <<-EOT
Param(
    [Parameter(Mandatory=$true)]
    [string] $subscriptionId,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroup,

    [Parameter(Mandatory=$true)]
    [string] $containerInstances,

    [Parameter(Mandatory=$true)]
    [string] $action = "start"
)

Connect-AzAccount -Identity

try {
    if ($action -eq "start") {
        Start-AzContainerGroup -Name $containerInstances -ResourceGroupName $resourceGroup -SubscriptionId $subscriptionId
        Write-Output "✅ Container instance '$containerInstances' started successfully."
    }
    elseif ($action -eq "stop") {
        Stop-AzContainerGroup -Name $containerInstances -ResourceGroupName $resourceGroup -SubscriptionId $subscriptionId
        Write-Output "✅ Container instance '$containerInstances' stopped successfully."
    }
    else {
        throw "❌ Invalid action '$action'. Use 'start' or 'stop'."
    }
}
catch {
    Write-Error "❌ Error: $($_.Exception.Message)"
}
  EOT
}
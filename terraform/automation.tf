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
    [string] $action = "start",

    [Parameter(Mandatory=$false)]
    [object] $webhookData
)

Connect-AzAccount -Identity

# Extract callbackUri from webhookData if provided
if ($webhookData) {
    try {
        $bodyJson = $webhookData.RequestBody
        $parsedBody = $bodyJson | ConvertFrom-Json
        $callbackUri = $parsedBody.callBackUri
        Write-Output "🔗 Extracted callbackUri: $callbackUri"
    }
    catch {
        Write-Warning "⚠️ Failed to parse callBackUri from webhookData: $($_.Exception.Message)"
    }
}

# Launch container instances command
try {
    if ($action -eq "start") {
        Start-AzContainerGroup -Name $containerInstances -ResourceGroupName $resourceGroup -SubscriptionId $subscriptionId -ErrorAction Stop
    }
    elseif ($action -eq "stop") {
        Stop-AzContainerGroup -Name $containerInstances -ResourceGroupName $resourceGroup -SubscriptionId $subscriptionId -ErrorAction Stop
    }
    else {
        throw "❌ Invalid action '$action'. Use 'start' or 'stop'."
    }
}
catch {
    $errorMessage = $_.Exception.Message
}

# Handle return code
if ($errorMessage) {

    $callbackBody = @{
        Output = @{}
        Error = @{
            ErrorCode = "ContainerInstanceError"
            Message   = $errorMessage
        }
        StatusCode = "403"
    } | ConvertTo-Json

    Write-Error "❌ Error: $errorMessage"

}
else {

    $callbackBody = @{
        Output = @{}
        Error = @{}
        StatusCode = "202"
    } | ConvertTo-Json

    Write-Output "✅ Container instance '$containerInstances' executed '$action' successfully."

}

# Send callback if URI is available
if ($callbackUri) {

    try {
        $response = Invoke-RestMethod -Uri $callbackUri -Method Post -Body $callbackBody -ContentType "application/json"
        Write-Output "📬 Callback sent successfully"
    }
    catch {
        Write-Warning "⚠️ Failed to send callback: $($_.Exception.Message)"
    }
}
  EOT
}


resource "azurerm_automation_webhook" "run_container" {
  name                    = "run_container"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aut.name
  expiry_time             = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timeadd(timestamp(), "8760h")) # 1 year
  enabled                 = true
  runbook_name            = azurerm_automation_runbook.container.name
  parameters = {
    subscriptionId     = var.subscription_id
    resourceGroup      = azurerm_resource_group.rg.name
    containerInstances = "${var.environment}${var.project}aci-books" # should be released with github actions
    action             = "start"
  }
}
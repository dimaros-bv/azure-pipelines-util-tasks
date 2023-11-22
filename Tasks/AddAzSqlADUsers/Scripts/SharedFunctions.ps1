function Log($message) {
  Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message"
}

function Get-AzSqlToken {
  Log "Retrieving access token for Azure databases."
  $token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
  return $token
}

function Set-AzDefaultResourceGroup($resourceGroup) {
  Log "Setting default resource group to $resourceGroup."
  Set-AzDefault -ResourceGroupName $resourceGroup
}

function Install-SqlDependencies {
  # Dependencies
  Log "Installing SqlServer module."
  Install-Module -Name SqlServer -Force -AllowClobber
  Import-Module SqlServer

  Log "Installing Az.Sql module."
  Install-Module -Name Az.Sql -Force -AllowClobber
  Import-Module Az.Sql
}
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/Scripts/SharedFunctions.ps1"
. "$PSScriptRoot/Scripts/AddAzSqlADUsers.ps1"

# Get inputs.
$resourceGroup = Get-VstsInput -Name ResourceGroup -Require
$sqlServerName = Get-VstsInput -Name SqlServerName -Require
$users = Get-VstsInput -Name Users -Require

$serviceName = Get-VstsInput -Name ConnectedServiceNameARM -Require
$endpointObject = Get-VstsEndpoint -Name $serviceName -Require
$endpoint = ConvertTo-Json $endpointObject
Log "$endpoint"

Install-SqlDependencies

# Connect to Azure
$tenantId = $endpoint.Auth.Parameters.TenantId
$clientName = $endpoint.Auth.Parameters.ServicePrincipalName
$clientId = $endpoint.Auth.Parameters.ServicePrincipalId
$clientSecret = $endpoint.Auth.Parameters.ServicePrincipalKey

$psCredential = New-Object System.Management.Automation.PSCredential(
  $clientId,
  (ConvertTo-SecureString $clientSecret -AsPlainText -Force)
)

Connect-AzAccount `
  -Tenant $tenantId `
  -Credential $psCredential `
  -ServicePrincipal $true `
  -Scope 'Process' `
  -WarningAction 'SilentlyContinue'

$token = Get-AzSqlToken

Add-AzSqlADUsers `
  -ResourceGroup $resourceGroup `
  -SqlServerName $sqlServerName `
  -ServiceConnectionName $clientName `
  -ServiceConnectionClientId $clientId `
  -Token $token `
  -DbUserRolesToAdd $users

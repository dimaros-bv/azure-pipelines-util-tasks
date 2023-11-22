function Invoke-AzSqlQueryWrapper {
  param (
    [string]$ResourceGroup,
    [string]$SqlServerName,
    [string]$ServiceConnectionName,
    [string]$ServiceConnectionClientId,
    [scriptBlock]$CodeToExecute
  )

  Log "Executing script against $SqlServerName"

  Set-AzDefaultResourceGroup $ResourceGroup

  # Grant permissions
  # Grant firewall access to SQL Server for agent
  Log "Creating firewall rule for agent to be able to access SQL Server."
  $IP = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip
  Log "Agent IP: $IP"
  $firewallRuleName = "Azure_DevOps_Agent_IP"
  New-AzSqlServerFirewallRule `
    -ServerName "$SqlServerName" `
    -FirewallRuleName "$firewallRuleName" `
    -StartIpAddress "$IP" `
    -EndIpAddress "$IP"
  Log "Firewall rule created."

  # Make service connection sql server admin
  $currentAdmin = Get-AzSqlServerActiveDirectoryAdministrator `
    -ServerName "$SqlServerName"
  Log "Current sql server admin:"
  $currentAdmin
  Log "Setting sql server admin to service account:"
  Set-AzSqlServerActiveDirectoryAdministrator `
    -ServerName "$SqlServerName" `
    -DisplayName "$ServiceConnectionName" `
    -ObjectId "$ServiceConnectionClientId"

  try {
    # Custom code
    & $CodeToExecute
  }
  catch {
    $exception = $_
    $exception | Format-List * -Force | Out-String
    if ($exception.InnerException) {
      $exception.InnerException | Format-List * -Force | Out-String
    }
    throw
  }
  finally {
    # Remove access
    Log "Removing firewall rule."
    Remove-AzSqlServerFirewallRule `
      -ServerName "$SqlServerName" `
      -FirewallRuleName "$firewallRuleName" 
    Log "Removed."
    Log "Resetting sql admin to $($currentAdmin.DisplayName)."
    Set-AzSqlServerActiveDirectoryAdministrator `
      -ServerName "$SqlServerName" `
      -DisplayName "$($currentAdmin.DisplayName)" `
      -ObjectId "$($currentAdmin.ObjectId)"
    Log "Reset."
  }

  Log "Successfully executed script."
}

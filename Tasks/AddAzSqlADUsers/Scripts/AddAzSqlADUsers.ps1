. "$PSScriptRoot/InvokeAzSqlQueryWrapper.ps1"

function Add-User {
  param(
    [object] $Context,
    [string] $User,
    [string[]] $DbRoles
  )
  Log "Adding $User to $($Context.Database) with roles $DbRoles"
  $result = Invoke-Sqlcmd @Context -Query "SELECT name FROM sys.sysusers WHERE name = '$User'"
  if ($result.ItemArray) {
    Log "User already exists."
  }
  else {
    Log "Creating user."
    Invoke-Sqlcmd @Context -Query "CREATE USER [$User] FROM EXTERNAL PROVIDER"
    Log "Created User."
  }

  foreach ($role in $DbRoles) {
    Log "Adding User to a role $role."
    Invoke-Sqlcmd @Context -Query "ALTER ROLE $role ADD MEMBER [$User]"
  }
}

function Add-AzSqlADUsers() {
  param(
    [string] $ResourceGroup,
    [string]$SqlServerName,
    [string]$ServiceConnectionName,
    [string]$ServiceConnectionClientId,
    [string]$Token,
    [string[]]$DbUserRolesToAdd
  )

  $Main = {
  
    foreach ($item in $DbUserRolesToAdd) {
      $params = $item -split '\|'
      $database = $params[0]
      $user = $params[1]
      $roles = $params[2] -split ','

      $context = @{
        AccessToken    = $Token
        ServerInstance = "$SqlServerName.database.windows.net"
        Database       = $database
      }

      Add-User -Context $context -User $user -DbRoles $roles 
    }
  
  }

  Invoke-AzSqlQueryWrapper `
    -ResourceGroup $ResourceGroup `
    -SqlServerName $SqlServerName `
    -ServiceConnectionName $ServiceConnectionName `
    -ServiceConnectionClientId $ServiceConnectionClientId `
    -CodeToExecute $Main  
}

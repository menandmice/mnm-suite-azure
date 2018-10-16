#
# mmDomainJoin.ps1
# A that join current computer to a domain and sets DNS and DHCP remote services
# to run as a specific user
#
# dependencies: AddAccountToLogonAsService.ps1
#
[CmdletBinding()]   
param(
    # user name for the domain to join to 
    [Parameter(Mandatory=$false)]
    [string]
    $domainUsername,
    # The password for the domain user
    [Parameter(Mandatory=$false)]
    [string]
    $domainUserPassword,
    # a user name to let the DNS and DHCP remote services log on/run as 
    [Parameter(Mandatory=$false)]
    [string]
    $svcDomainUsername,
    # password for the logon service
    [Parameter(Mandatory=$false)]
    [string]
    $svcDomainUserPassword
)


#
# simple log function
mkdir -Force "\mm\logs"
$logFile = "\mm\logs\main.log"
function Log-Message([string] $msg)
{
    try {
        "$(Get-Date) $msg" | Out-File $logFile -Append
    } catch {}
}


$needsRestart = $false
if ($domainUsername) {
    # Joining a domain
    Log-Message("*** Joining a domain")
    Log-Message("* Domain username: $domainUsername")
    Log-Message("* Domain password: $domainUserPassword")
    $User = $domainUsername
    $PWord = ConvertTo-SecureString -String $domainUserPassword -AsPlainText -Force
    $Domain = $domainUsername.Split("\")

    $joinCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
    Add-Computer -DomainName $Domain[0] -Credential $joinCred
    $needsRestart = $true
}

if ($svcDomainUsername) {
    # Need to change the default logon credentials for the DNS and DHCP service
    Log-Message("* Changing logon credentials for services to user: $svcDomainUsername")
    # Stop-Service -DisplayName "Men and Mice DNS Server Controller"
    # Stop-Service -DisplayName "Men and Mice DHCP Server Controller"
    SC.exe stop "Men and Mice DNS Server Controller"
    SC.exe stop "Men and Mice DHCP Server Controller"
    SC.exe config "Men and Mice DNS Server Controller" type= own obj= "$svcDomainUsername" password= "$svcDomainUserPassword"
    SC.exe config "Men and Mice DHCP Server Controller" type= own obj= "$svcDomainUsername" password= "$svcDomainUserPassword"

    # make sure the credentials are allowed to logon
    .\AddAccountToLogonAsService.ps1 -accountToAdd "$svcDomainUsername" *> "\mm\logs\log_addserviceaccount.txt"
    $needsRestart = $true
}

Log-Message("* All done")
if ($needsRestart) {
    Log-Message("*** Restarting...")
    Restart-Computer -Force
}

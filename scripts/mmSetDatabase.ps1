#
# mmSetDatabase.ps1
# A script that sets the database  connection for Men & Mice Suite
#
[CmdletBinding()]   
param(
    # database server name or address
    [Parameter(Mandatory=$false)]
    [string]
    $databaseServer,
    # database port number
    [Parameter(Mandatory=$false)]
    [string]
    $databasePort = "1433",
    # database name
    [Parameter(Mandatory=$false)]
    [string]
    $databaseInstance,
    # database user  
    [Parameter(Mandatory=$false)]
    [string]
    $databaseUsername,
    # password for the database user
    [Parameter(Mandatory=$false)]
    [string]
    $databasePassword = ""
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

Log-Message("*** Database configuration")

if($databaseServer){
    $isAzureValue = If ($azure) {"1"} Else {"0"}
    $fingerprint = -join ((48..57) + (97..122) | Get-Random -Count 48 | % {[char]$_})
    Log-Message("* Configuring database connection. Database: $($databaseServer)")
    mkdir -Force "C:\ProgramData\Men and Mice\Central"
    $pref = "C:\ProgramData\Men and Mice\Central\preferences.cfg"

   Add-Content $pref "
<password value=`"$($fingerprint)`" />
<Database value=`"MSSQL`" />
<DatabaseSchema value=`"dbo`" />
<DatabaseServer value=`"tcp:$($databaseServer).database.windows.net,$($databasePort)@$($databaseInstance)`" />
<DatabaseUsername value=`"$databaseUsername@$databaseServer`" />
<DatabasePassword value=`"plaintext:$databasePassword`" />`n"

}

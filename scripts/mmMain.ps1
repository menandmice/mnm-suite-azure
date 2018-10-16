#
# mmMain.ps1
# A script call all other required script for deployment of Men & Mice
#
param(
    # a version to install
    [Parameter(Mandatory=$false)]
    [string]
    $mmVersion="9.1.3",
	[Parameter(Mandatory=$false)]
	[string]
	$httpPort,
	[Parameter(Mandatory=$false)]
	[string]
	$mmmcPort,
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
    $databaseInstance = "mmsuite",
    # database user  
    [Parameter(Mandatory=$false)]
    [string]
    $databaseUsername = "mmSuiteUser",
    # password for the database user
    [Parameter(Mandatory=$false)]
    [string]
    $databasePassword,
    # whether this is a azure db or MS-SQL
    [Parameter(Mandatory=$false)]
    [switch]
    $azure = $true,
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

# Note: Not sending password while cleartext passwords don't work
.\mmSetDatabase.ps1 -databaseServer $databaseServer -databasePort $databasePort -databaseInstance $databaseInstance -databaseUsername $databaseUsername -databasePassword $databasePassword | Out-Null 
.\mmInstall.ps1 -mmmcPort $mmmcPort -httpPort $httpPort | Out-Null
.\mmInstallKeys.ps1 | Out-Null
.\mmDomainJoin.ps1 -domainUsername $domainUsername -domainUserPassword $domainUserPassword -svcDomainUsername $svcDomainUsername -svcDomainUserPassword $svcDomainUserPassword | Out-Null

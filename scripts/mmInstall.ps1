#
# mmInstall.ps1
# A script to install all the components of Men & Mice Suite 
#
# will create a directory \mm\ to work in 
# \mm\logs - contains all logs
#
param(
    # a version to install
    [Parameter(Mandatory=$false)]
    [string]
    $mmVersion="9.1.6",
    [Parameter(Mandatory=$false)]
    [string]
    $mmmcPort,
	[Parameter(Mandatory=$false)]
	[string]
	$httpPort
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

Log-Message("*** Starting install")

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}


#
# download all installation files
#
Log-Message("* Downloading installation files")
$centralUpdateDir = "C:\ProgramData\Men and Mice\Central\update"
mkdir -Force "$($centralUpdateDir)"

# set progress to silent to speed up download
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest "http://update.menandmice.com/updates/$($mmVersion).zip" -Outfile "$($centralUpdateDir)/$($mmVersion).zip" *>> $logFile
Log-Message("* Extracting update file")
Unzip "$($centralUpdateDir)/$($mmVersion).zip" "$($centralUpdateDir)/"

$centralUpdateDir = "$($centralUpdateDir)\$($mmVersion)"

# copy release as currentVersion so upgrade will work for us
cp "$($centralUpdateDir)\release.xml" "$($centralUpdateDir)\..\currentVersion.xml"

# create all the directories
mkdir -Force "C:\Program Files\Men and Mice\Central"
mkdir -Force "C:\Program Files\Men and Mice\Remotes"

# copy all the files needed
Log-Message("* Copying files needed")
copy "$($centralUpdateDir)\windows\win64\mmcentral.exe" "C:\Program Files\Men and Mice\Central\"
###JWD copy "$($centralUpdateDir)\windows\win64\mmSSPI.dll" "C:\Program Files\Men and Mice\Central\"
copy "$($centralUpdateDir)\windows\win64\mmupdater.exe" "C:\Program Files\Men and Mice\Central\"
###JWD copy "$($centralUpdateDir)\windows\win64\doUpdate.bat" "C:\Program Files\Men and Mice\Central\"
copy "$($centralUpdateDir)\windows\win64\mmremote.exe" "C:\Program Files\Men and Mice\Remotes\"
copy "$($centralUpdateDir)\windows\win64\mmdhcpremote.exe" "C:\Program Files\Men and Mice\Remotes\"

Log-Message("* Installing and starting services")
Push-Location -Path "C:\Program Files\Men and Mice\"
.\Central\mmcentral.exe -i -start
.\Central\mmupdater.exe -i -start
.\Remotes\mmremote.exe -i -start
.\Remotes\mmdhcpremote.exe -i -start
Pop-Location

Log-Message("* Installing management console")
$centralInstallersDir = "$($centralUpdateDir)\installers"
Push-Location -Path "$($centralInstallersDir)"
.\Men_and_Mice_Management_Console_*.exe /x /b"./" /v"/qn" | Out-Null
msiexec /i "$($centralInstallersDir)\Men and Mice Management Console.msi" /quiet /qn /norestart /log \mm\logs\log_console.txt | Out-Null
Pop-Location

if($mmmcPort -eq "Allow") {
    New-NetFirewallRule -DisplayName "Men & Mice Management Console" -Direction Inbound -LocalPort 1231 -Protocol TCP -Action Allow -Profile Domain,Private
}

#
# Create shortcut for Men & Mice management console on the desktop
#
$sh = New-Object -COM WScript.shell

$scut=$sh.CreateShortcut( $sh.SpecialFolders("AllUsersDesktop") + '\\MMMC.lnk')
$scut.TargetPath= 'C:\Program Files (x86)\Men and Mice\Console\MMMC.exe'
$scut.Save()


#
# install IIS
#
Log-Message("* Installing IIS")
Install-WindowsFeature -name Web-Server -IncludeManagementTools

Log-Message("* Installing Men and Mice Web")
Push-Location -Path "$($centralInstallersDir)"
.\Men_and_Mice_Web_Application_x64_*.exe /install /quiet /log \mm\logs\log_web.txt | Out-Null
Pop-Location

if($httpPort -eq "Allow") {
	New-NetFirewallRule -DisplayName "Men & Mice Web Application" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow -Profile Domain,Private
}

Log-Message("* Install components done")


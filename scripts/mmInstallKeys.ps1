#
# mmInstallKeys.ps1
# A script that downloads and installs temporary keys to database
#


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

#
# install temporary license keys
#
Log-Message("*** Installing temporary license keys")
$count = 0
$success = $false
do {
    $req = Invoke-WebRequest  -UseBasicParsing -Uri "http://tempkeys.menandmice.com/temp_keys.txt"
    $success = $req.StatusCode -eq "200"
    $count++
    if (-not($success)) {
        Log-Message("error: retrieving temporary license keys: $req")
        Log-Message("error status: $error")
        Start-sleep -Seconds 5
    }
} until($count -gt 2 -or $success)
if(-not($success)) {
    Log-Message("error: giving up retrieving license keys")
    Exit
}

$arr = $req.content.split("`r`n")

$mmws_location = 'http://127.0.0.1:8111/'
$mmws_command = $mmws_location + 'api/command/AddLicenseKey?licenseKey='
$user = 'administrator'
$pass = 'administrator'
$pair = "$($user):$($pass)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

$centralLog = "C:\ProgramData\Men and Mice\Central\logs\central-startup*"
$databaseReady = $false
while($databaseReady -eq $false){
    if ((Get-Content $centralLog | %{$_ -match "Switching states - current is now : Active"}) -contains $true) {
        $databaseReady = $true
        Log-Message("* Database ready")
    } else {
        Start-Sleep -s 1
    }
}

$mmwsService
while($mmwsService.Status -ne "Running") {
    $mmwsService = Get-Service "Men and Mice Web Services"
}
Log-Message("* Web Service running")

foreach($key in $arr) {
    if ($key) {
        $url = "$($mmws_command)$($key)"
        try { 
            $res = Invoke-WebRequest -UseBasicParsing -Uri $url -Headers $Headers
            if($res.StatusCode -ne "204") {
                $status = $res.StatusCode
                Log-Message("error: setting license keys <$($status)><$($url)>")
            }
        } catch {
            $status = $_.Exception.Response.StatusCode.Value__
            # Log-Message("exception: setting license keys <$($status)><$($url)>")
            Log-Message("exception: $($_)")
        }
    }
}

Log-Message("* Installing temporary license keys done")
